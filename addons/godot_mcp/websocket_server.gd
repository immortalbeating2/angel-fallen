@tool
extends Node

## Multi-connection WebSocket client.
## 端口规划必须与 Node server、PowerShell 诊断脚本和补丁脚本保持同步：
## - 17605-17619: stdio MCP primary，默认给 Codex / Claude Code / opencode 会话 bridge 使用。
## - 17620-17624: godot-cli primary，只给短生命周期 CLI 命令使用。
## - 6505-6509: legacy stdio fallback，仅用于兼容旧插件或旧配置。
## - 6510-6514: legacy CLI fallback，仅用于兼容旧 CLI。
## 插件启动时优先读取项目本地 rendezvous 文件，直接连接当前会话写入的端口；
## 只有 rendezvous 不存在或连接失败时，才回退到固定端口扫描。

signal client_connected()
signal client_disconnected()
signal message_received(text: String)
signal command_executed(method: String, success: bool)
signal command_completed(method: String, success: bool, response: String, source_port: int)
signal workspace_handshake_sent(port: int, workspace: String)
signal workspace_handshake_accepted(port: int, session_id: String)
signal workspace_handshake_rejected(port: int, reason: String)

var command_router: Node

const STDIO_PRIMARY_START := 17605
const STDIO_PRIMARY_END := 17619
const CLI_PRIMARY_START := 17620
const CLI_PRIMARY_END := 17624
const LEGACY_STDIO_START := 6505
const LEGACY_STDIO_END := 6509
const LEGACY_CLI_START := 6510
const LEGACY_CLI_END := 6514
const RECONNECT_INTERVAL := 3.0
const BUFFER_SIZE := 16 * 1024 * 1024  # 16MB
const RENDEZVOUS_PATH := "res://.godot/godot-mcp-pro/current-bridge.json"

var _ports: Array[int] = []
var _port_sources: Dictionary = {}  # port -> source label
var _rendezvous_sessions: Dictionary = {}  # port -> sessionId from current-bridge.json
var _peers: Dictionary = {}  # port -> WebSocketPeer
var _connected: Dictionary = {}  # port -> bool
var _accepted: Dictionary = {}  # port -> bool，stdio 必须等 godot_hello_ack 后才算被当前 bridge 接受。
var _hello_sent: Dictionary = {}  # port -> bool
var _timers: Dictionary = {}  # port -> float (reconnect countdown)
var _connect_times: Dictionary = {}  # port -> float (elapsed seconds since connect)
var _running: bool = false


func start_server() -> void:
	_running = true
	_build_candidate_ports()
	for p in _ports:
		_connected[p] = false
		_accepted[p] = false
		_hello_sent[p] = false
		_timers[p] = 0.0
		_try_connect(p)
	print("[MCP] Connecting via rendezvous, stdio 17605-17619, cli 17620-17624, legacy 6505-6509/6510-6514")


func stop_server() -> void:
	_running = false
	for p in _peers:
		var ws: WebSocketPeer = _peers[p]
		if ws:
			ws.close(1000, "Plugin shutting down")
	_peers.clear()
	_connected.clear()
	_accepted.clear()
	_hello_sent.clear()
	_timers.clear()
	print("[MCP] WebSocket client stopped")


func get_client_count() -> int:
	var count: int = 0
	for p in _connected:
		if _connected[p]:
			count += 1
	return count


func get_connected_ports() -> Array[int]:
	var ports: Array[int] = []
	for p: int in _connected:
		if _connected[p]:
			ports.append(p)
	return ports


func get_tracked_ports() -> Array[int]:
	return _ports.duplicate()


func get_port_source(port: int) -> String:
	return str(_port_sources.get(port, "unknown"))


func get_port_connect_time(port: int) -> float:
	return _connect_times.get(port, -1.0)


func _build_candidate_ports() -> void:
	_ports.clear()
	_port_sources.clear()
	_rendezvous_sessions.clear()

	_add_rendezvous_port()
	_add_port_range(STDIO_PRIMARY_START, STDIO_PRIMARY_END, "stdio primary")
	_add_port_range(CLI_PRIMARY_START, CLI_PRIMARY_END, "cli primary")
	_add_port_range(LEGACY_STDIO_START, LEGACY_STDIO_END, "legacy stdio")
	_add_port_range(LEGACY_CLI_START, LEGACY_CLI_END, "legacy cli")


func _add_port_range(start_port: int, end_port: int, source: String) -> void:
	for p in range(start_port, end_port + 1):
		_add_port(p, source)


func _add_port(port: int, source: String) -> void:
	if _port_sources.has(port):
		return
	_ports.append(port)
	_port_sources[port] = source


func _add_rendezvous_port() -> void:
	var path := ProjectSettings.globalize_path(RENDEZVOUS_PATH)
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	var port := int(data.get("port", 0))
	if port <= 0:
		return
	_add_port(port, "rendezvous")
	_rendezvous_sessions[port] = str(data.get("sessionId", ""))


func _try_connect(p: int) -> void:
	var ws := WebSocketPeer.new()
	ws.outbound_buffer_size = BUFFER_SIZE
	ws.inbound_buffer_size = BUFFER_SIZE
	var err := ws.connect_to_url("ws://127.0.0.1:%d" % p)
	if err == OK:
		_peers[p] = ws
	else:
		_peers[p] = null


func _process(delta: float) -> void:
	if not _running:
		return

	for p in _ports:
		var ws: WebSocketPeer = _peers.get(p)

		if ws == null:
			_timers[p] = _timers.get(p, 0.0) + delta
			if _timers[p] >= RECONNECT_INTERVAL:
				_timers[p] = 0.0
				_try_connect(p)
			continue

		ws.poll()
		var state := ws.get_ready_state()

		match state:
			WebSocketPeer.STATE_OPEN:
				if not _connected.get(p, false):
					_connected[p] = true
					_connect_times[p] = 0.0
					_timers[p] = 0.0
					print_verbose("[MCP] Connected on port %d (%s)" % [p, get_port_source(p)])
					_send_workspace_hello(p)
					client_connected.emit()
				else:
					_connect_times[p] = _connect_times.get(p, 0.0) + delta

				while ws.get_available_packet_count() > 0:
					var packet := ws.get_packet()
					var text := packet.get_string_from_utf8()
					_dispatch_message(text, p)

			WebSocketPeer.STATE_CLOSING:
				pass

			WebSocketPeer.STATE_CLOSED:
				if _connected.get(p, false):
					_connected[p] = false
					_accepted[p] = false
					_hello_sent[p] = false
					print_verbose("[MCP] Disconnected from port %d (%s)" % [p, get_port_source(p)])
					client_disconnected.emit()
				_peers[p] = null
				_timers[p] = 0.0

			WebSocketPeer.STATE_CONNECTING:
				pass


func _send_to_port(p: int, text: String) -> void:
	var ws: WebSocketPeer = _peers.get(p)
	if ws and _connected.get(p, false):
		ws.send_text(text)


func _send_workspace_hello(p: int) -> void:
	if _hello_sent.get(p, false):
		return
	_hello_sent[p] = true
	var workspace := ProjectSettings.globalize_path("res://")
	var payload := {
		"jsonrpc": "2.0",
		"method": "godot_hello",
		"params": {
			"workspace": workspace,
			"projectPath": workspace,
			"sessionId": str(_rendezvous_sessions.get(p, "")),
			"pluginVersion": "1.12.0",
			"connectionSource": get_port_source(p),
		},
	}
	_send_to_port(p, JSON.stringify(payload))
	workspace_handshake_sent.emit(p, workspace)


func send_message(text: String) -> void:
	for p in _peers:
		_send_to_port(p, text)


## Synchronous dispatch - parse JSON, handle ping/pong/hello ack, queue command execution
func _dispatch_message(text: String, source_port: int) -> void:
	message_received.emit(text)

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		_send_response(source_port, null, null, {"code": -32700, "message": "Parse error"})
		return

	var msg: Variant = json.data
	if not msg is Dictionary:
		_send_response(source_port, null, null, {"code": -32600, "message": "Invalid request"})
		return

	var msg_dict: Dictionary = msg

	if msg_dict.get("method") == "godot_hello_ack":
		_handle_hello_ack(source_port, msg_dict.get("params", {}))
		return

	if msg_dict.get("method") == "ping":
		_send_to_port(source_port, JSON.stringify({"jsonrpc": "2.0", "method": "pong", "params": {}}))
		return

	if msg_dict.get("method") == "pong":
		return

	var id: Variant = msg_dict.get("id")
	var method: String = msg_dict.get("method", "")
	var params: Dictionary = msg_dict.get("params", {})

	if method.is_empty():
		_send_response(source_port, id, null, {"code": -32600, "message": "Missing method"})
		return

	if not command_router:
		_send_response(source_port, id, null, {"code": -32603, "message": "No command router"})
		return

	_execute_command.call_deferred(source_port, id, method, params)


func _handle_hello_ack(source_port: int, params: Variant) -> void:
	var data: Dictionary = params if params is Dictionary else {}
	var accepted := bool(data.get("accepted", false))
	if accepted:
		_accepted[source_port] = true
		workspace_handshake_accepted.emit(source_port, str(data.get("sessionId", "")))
	else:
		var reason := str(data.get("reason", "rejected"))
		workspace_handshake_rejected.emit(source_port, reason)
		var ws: WebSocketPeer = _peers.get(source_port)
		if ws:
			ws.close(1008, reason)


func _execute_command(source_port: int, id: Variant, method: String, params: Dictionary) -> void:
	var cmd_result: Dictionary = await command_router.execute(method, params)
	if cmd_result.has("error"):
		var err_data: Variant = cmd_result["error"]
		_send_response(source_port, id, null, err_data)
		var response_text := JSON.stringify(err_data)
		command_executed.emit(method, false)
		command_completed.emit(method, false, response_text, source_port)
	else:
		var result_data: Variant = cmd_result.get("result", {})
		_send_response(source_port, id, result_data, null)
		var response_text := JSON.stringify(result_data)
		command_executed.emit(method, true)
		command_completed.emit(method, true, response_text, source_port)


func _send_response(source_port: int, id: Variant, result: Variant, err: Variant) -> void:
	var response: Dictionary = {"jsonrpc": "2.0", "id": id}
	if err != null:
		response["error"] = err
	else:
		response["result"] = result if result != null else {}
	_send_to_port(source_port, JSON.stringify(response))
