shader_type canvas_item;

// Archive Seal Wave Shader
// 用途：封印门、挑战档记录的轻微空间波动，克制但有庄严压迫感。

uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.015;
uniform float wave_frequency : hint_range(0.0, 20.0) = 12.0;
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform vec4 solemn_tint : source_color = vec4(0.85, 0.8, 0.75, 1.0); // 褪色的档案黄昏感

void fragment() {
    vec2 uv = UV;
    // Y轴的轻微形变挤压，符合旧封印的年代流动感
    uv.x += sin(uv.y * wave_frequency + TIME * speed) * wave_amplitude;
    
    vec4 tex = texture(TEXTURE, uv);
    // 挂上一层残败泛黄的滤镜
    COLOR = tex * solemn_tint;
}
