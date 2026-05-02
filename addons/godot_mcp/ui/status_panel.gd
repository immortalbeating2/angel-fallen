@tool
extends VBoxContainer

var websocket_server: Node = null
var command_router: Node = null

const MAX_LOG_ENTRIES := 200
const COLOR_CONNECTED := Color(0.2, 0.9, 0.2)
const COLOR_DISCONNECTED := Color(0.9, 0.2, 0.2)
const COLOR_SUCCESS := Color(0.6, 1, 0.6)
const COLOR_ERROR := Color(1, 0.6, 0.6)
const COLOR_DIM := Color(0.6, 0.6, 0.6)

const STDIO_PRIMARY_START := 17605
const STDIO_PRIMARY_END := 17619
const CLI_PRIMARY_START := 17620
const CLI_PRIMARY_END := 17624
const LEGACY_STDIO_START := 6505
const LEGACY_STDIO_END := 6509
const LEGACY_CLI_START := 6510
const LEGACY_CLI_END := 6514

# 状态面板只用于人工复核：它显示插件扫描范围和端口角色，方便确认 Godot editor
# 是否看到了 bridge / CLI 端口。真正 stale 清理必须由 PowerShell 脚本结合
# lock/heartbeat、PID、TCP 连接和 workspace 归属判断，不能只看面板上的连接年龄。

# Header
var _status_icon: Label
var _status_label: Label
var _client_count_label: Label

# Tabs
var _tab_container: TabContainer

# Activity tab
var _show_details_check: CheckBox
var _log_container: VBoxContainer
var _log_scroll: ScrollContainer

# Clients tab
var _port_labels: Dictionary = {}  # port -> {icon: Label, label: Label}

# Tools tab
var _filter_edit: LineEdit
var _tools_container: VBoxContainer
var _tool_checkboxes: Dictionary = {}  # method_name -> CheckBox


func _ready() -> void:
	_build_ui()


func setup(ws_server: Node, cmd_router: Node = null) -> void:
	websocket_server = ws_server
	command_router = cmd_router

	if websocket_server:
		websocket_server.client_connected.connect(_on_client_connected)
		websocket_server.client_disconnected.connect(_on_client_disconnected)
		if websocket_server.has_signal("workspace_handshake_sent"):
			websocket_server.workspace_handshake_sent.connect(_on_workspace_handshake_sent)
		if websocket_server.has_signal("workspace_handshake_accepted"):
			websocket_server.workspace_handshake_accepted.connect(_on_workspace_handshake_accepted)
		if websocket_server.has_signal("workspace_handshake_rejected"):
			websocket_server.workspace_handshake_rejected.connect(_on_workspace_handshake_rejected)
		if websocket_server.has_signal("command_completed"):
			websocket_server.command_completed.connect(_on_command_completed)
		else:
			websocket_server.command_executed.connect(_on_command_executed)

	if command_router:
		_populate_tools_list()


func _build_ui() -> void:
	# Header bar
	var header := HBoxContainer.new()
	add_child(header)

	_status_icon = Label.new()
	_status_icon.text = "●"
	_status_icon.add_theme_color_override("font_color", COLOR_DISCONNECTED)
	header.add_child(_status_icon)

	_status_label = Label.new()
	_status_label.text = " MCP Pro: Waiting for connection..."
	header.add_child(_status_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_client_count_label = Label.new()
	_client_count_label.text = "Clients: 0"
	header.add_child(_client_count_label)

	# Separator
	var sep := HSeparator.new()
	add_child(sep)

	# TabContainer
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tab_container)

	_build_activity_tab()
	_build_clients_tab()
	_build_tools_tab()


func _build_activity_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "Activity"
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_child(vbox)

	# Controls row
	var controls := HBoxContainer.new()
	vbox.add_child(controls)

	_show_details_check = CheckBox.new()
	_show_details_check.text = "Show Response Details"
	_show_details_check.button_pressed = false
	_show_details_check.toggled.connect(_on_show_details_toggled)
	controls.add_child(_show_details_check)

	var ctrl_spacer := Control.new()
	ctrl_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(ctrl_spacer)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear_log)
	controls.add_child(clear_btn)

	# Log scroll
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.custom_minimum_size.y = 80
	vbox.add_child(_log_scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_container)


func _build_clients_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "Clients"
	_tab_container.add_child(vbox)

	for p in _status_ports():
		var row := HBoxContainer.new()
		vbox.add_child(row)

		var icon := Label.new()
		icon.text = "○"
		icon.add_theme_color_override("font_color", COLOR_DISCONNECTED)
		row.add_child(icon)

		var lbl := Label.new()
		lbl.text = "  Port %d  —  Disconnected" % p
		row.add_child(lbl)
		lbl.text = "  Port %d%s  - Disconnected" % [p, _port_role_suffix(p)]

		_port_labels[p] = {"icon": icon, "label": lbl}


func _build_tools_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "Tools"
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_child(vbox)

	# Controls
	var controls := HBoxContainer.new()
	vbox.add_child(controls)

	_filter_edit = LineEdit.new()
	_filter_edit.placeholder_text = "Filter tools..."
	_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_edit.text_changed.connect(_on_filter_changed)
	controls.add_child(_filter_edit)

	var enable_all_btn := Button.new()
	enable_all_btn.text = "Enable All"
	enable_all_btn.pressed.connect(_on_enable_all)
	controls.add_child(enable_all_btn)

	var disable_all_btn := Button.new()
	disable_all_btn.text = "Disable All"
	disable_all_btn.pressed.connect(_on_disable_all)
	controls.add_child(disable_all_btn)

	# Scroll
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 80
	vbox.add_child(scroll)

	_tools_container = VBoxContainer.new()
	_tools_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_tools_container)


func _populate_tools_list() -> void:
	if not command_router:
		return

	# Clear existing
	for child in _tools_container.get_children():
		child.queue_free()
	_tool_checkboxes.clear()

	var methods: Array = command_router.get_available_methods()
	methods.sort()

	for method_name: String in methods:
		var cb := CheckBox.new()
		cb.text = method_name
		cb.button_pressed = not command_router.is_tool_disabled(method_name)
		cb.toggled.connect(_on_tool_toggled.bind(method_name))
		_tools_container.add_child(cb)
		_tool_checkboxes[method_name] = cb


func _process(_delta: float) -> void:
	if not websocket_server:
		return

	var count: int = websocket_server.get_client_count()
	_client_count_label.text = "Clients: %d" % count

	if count > 0:
		_status_icon.add_theme_color_override("font_color", COLOR_CONNECTED)
		_status_label.text = " MCP Pro: Connected"
	else:
		_status_icon.add_theme_color_override("font_color", COLOR_DISCONNECTED)
		_status_label.text = " MCP Pro: Waiting for connection..."

	# Update clients tab
	_update_clients_tab()
	_apply_port_role_labels()


func _update_clients_tab() -> void:
	var connected_ports: Array[int] = []
	if websocket_server.has_method("get_connected_ports"):
		connected_ports = websocket_server.get_connected_ports()

	for p: int in _port_labels:
		var info: Dictionary = _port_labels[p]
		var icon: Label = info["icon"]
		var lbl: Label = info["label"]

		if p in connected_ports:
			icon.text = "●"
			icon.add_theme_color_override("font_color", COLOR_CONNECTED)
			var time_str := ""
			if websocket_server.has_method("get_port_connect_time"):
				var elapsed: float = websocket_server.get_port_connect_time(p)
				if elapsed >= 0:
					var mins := int(elapsed) / 60
					var secs := int(elapsed) % 60
					time_str = "  (%dm %02ds)" % [mins, secs]
			lbl.text = "  Port %d  —  Connected%s" % [p, time_str]
		else:
			icon.text = "○"
			icon.add_theme_color_override("font_color", COLOR_DISCONNECTED)
			lbl.text = "  Port %d  —  Disconnected" % p


# --- Activity callbacks ---

func _port_role_suffix(port: int) -> String:
	# 端口角色与 Node server / 诊断脚本 / 补丁脚本保持一致：
	# 17605-17619 是 stdio primary，17620-17624 是 CLI primary；
	# 6505-6509 / 6510-6514 只保留 legacy 兼容观察。
	if port >= STDIO_PRIMARY_START and port <= STDIO_PRIMARY_END:
		return " (stdio primary)"
	if port >= CLI_PRIMARY_START and port <= CLI_PRIMARY_END:
		return " (CLI primary)"
	if port >= LEGACY_STDIO_START and port <= LEGACY_STDIO_END:
		return " (legacy stdio)"
	if port >= LEGACY_CLI_START and port <= LEGACY_CLI_END:
		return " (legacy CLI)"
	return " (rendezvous)"


func _status_ports() -> Array[int]:
	var ports: Array[int] = []
	if websocket_server and websocket_server.has_method("get_tracked_ports"):
		ports = websocket_server.get_tracked_ports()
	else:
		for p in range(STDIO_PRIMARY_START, CLI_PRIMARY_END + 1):
			ports.append(p)
		for p in range(LEGACY_STDIO_START, LEGACY_CLI_END + 1):
			ports.append(p)
	ports.sort()
	return ports


func _apply_port_role_labels() -> void:
	var connected_ports: Array[int] = []
	if websocket_server and websocket_server.has_method("get_connected_ports"):
		connected_ports = websocket_server.get_connected_ports()
	for p: int in _port_labels:
		var info: Dictionary = _port_labels[p]
		var lbl: Label = info["label"]
		if p in connected_ports:
			lbl.text = "  Port %d%s  - Connected" % [p, _port_role_suffix(p)]
		else:
			lbl.text = "  Port %d%s  - Disconnected" % [p, _port_role_suffix(p)]


func _on_client_connected() -> void:
	_add_log("Client connected", COLOR_CONNECTED)


func _on_client_disconnected() -> void:
	_add_log("Client disconnected", COLOR_DISCONNECTED)


func _on_workspace_handshake_sent(port: int, workspace: String) -> void:
	_add_log("Handshake sent on port %d for %s" % [port, workspace], COLOR_DIM)


func _on_workspace_handshake_accepted(port: int, session_id: String) -> void:
	_add_log("Handshake accepted on port %d (%s)" % [port, session_id], COLOR_CONNECTED)


func _on_workspace_handshake_rejected(port: int, reason: String) -> void:
	_add_log("Handshake rejected on port %d: %s" % [port, reason], COLOR_ERROR)


func _on_command_executed(method: String, ok: bool) -> void:
	var color := COLOR_SUCCESS if ok else COLOR_ERROR
	var status_icon := "OK" if ok else "ERR"
	_add_log("[%s] %s" % [status_icon, method], color)


func _on_command_completed(method: String, ok: bool, response: String, source_port: int) -> void:
	var color := COLOR_SUCCESS if ok else COLOR_ERROR
	var status_icon := "OK" if ok else "ERR"
	_add_log("[%s] %s (port %d)" % [status_icon, method, source_port], color, response)


func _on_clear_log() -> void:
	for child in _log_container.get_children():
		child.queue_free()


func _on_show_details_toggled(on: bool) -> void:
	for entry in _log_container.get_children():
		if entry is VBoxContainer and entry.get_child_count() > 1:
			entry.get_child(1).visible = on


func _add_log(text: String, color: Color = Color.WHITE, response: String = "") -> void:
	if _log_container == null:
		return

	var entry := VBoxContainer.new()
	_log_container.add_child(entry)

	var label := Label.new()
	var time_str := Time.get_time_string_from_system()
	label.text = "[%s] %s" % [time_str, text]
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 12)
	entry.add_child(label)

	if not response.is_empty():
		var detail := RichTextLabel.new()
		var preview := response.substr(0, 500)
		if response.length() > 500:
			preview += "..."
		detail.text = preview
		detail.fit_content = true
		detail.scroll_active = false
		detail.add_theme_color_override("default_color", COLOR_DIM)
		detail.add_theme_font_size_override("normal_font_size", 11)
		detail.custom_minimum_size.y = 0
		detail.visible = _show_details_check.button_pressed if _show_details_check else false
		entry.add_child(detail)

	# Limit entries
	while _log_container.get_child_count() > MAX_LOG_ENTRIES:
		var old: Node = _log_container.get_child(0)
		_log_container.remove_child(old)
		old.queue_free()

	# Auto scroll to bottom
	_auto_scroll.call_deferred()


func _auto_scroll() -> void:
	if _log_scroll:
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


# --- Tools callbacks ---

func _on_filter_changed(filter: String) -> void:
	for method_name: String in _tool_checkboxes:
		var cb: CheckBox = _tool_checkboxes[method_name]
		cb.visible = filter.is_empty() or method_name.containsn(filter)


func _on_tool_toggled(enabled: bool, method_name: String) -> void:
	if command_router and command_router.has_method("set_tool_disabled"):
		command_router.set_tool_disabled(method_name, not enabled)


func _on_enable_all() -> void:
	if command_router and command_router.has_method("set_all_tools_disabled"):
		command_router.set_all_tools_disabled(false)
	for method_name: String in _tool_checkboxes:
		_tool_checkboxes[method_name].set_pressed_no_signal(true)


func _on_disable_all() -> void:
	if command_router and command_router.has_method("set_all_tools_disabled"):
		command_router.set_all_tools_disabled(true)
	for method_name: String in _tool_checkboxes:
		_tool_checkboxes[method_name].set_pressed_no_signal(false)
