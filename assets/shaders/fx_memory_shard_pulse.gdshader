shader_type canvas_item;

// Memory Shard Pulse Shader
// 用途：记忆祭坛碎片、记忆图标缓慢脉冲，蓝金交织的怀旧沉重感。

uniform vec4 core_color : source_color = vec4(0.6, 0.8, 1.0, 1.0); // 残破偏冷的蓝
uniform vec4 aura_color : source_color = vec4(1.0, 0.9, 0.5, 1.0); // 淡金色残辉
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.0;

void fragment() {
    vec4 base_tex = texture(TEXTURE, UV);
    // 脉冲周期计算
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5);
    
    // 色彩在蓝金两极之间进行呼吸游走
    vec4 active_glow = mix(core_color, aura_color, pulse);
    
    // 直接以混合色提亮原图
    COLOR = base_tex * active_glow;
    // 透明度微弱变化模拟"心跳感"
    COLOR.a = base_tex.a * (0.8 + 0.2 * pulse);
}
