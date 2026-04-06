shader_type canvas_item;

// UI Holy Glow Shader
// 用途：为UI面单、奖励卡片、选框边缘提供克制的神圣感微光，具有呼吸感。

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.6, 1.0); // 淡金色微光
uniform float intensity : hint_range(0.0, 5.0) = 1.2;
uniform float speed : hint_range(0.0, 5.0) = 2.0;
uniform float fade_edge : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    // 生成基于时间的微光呼吸频率
    float pulse = (sin(TIME * speed) * 0.5 + 0.5) * intensity;
    
    // 计算中心距离，让微光局限于图像不透明区域并且边缘柔和
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    float edge_falloff = smoothstep(0.5, 0.5 - fade_edge, dist);
    
    // 将原图色彩与泛光色彩根据透明度与强度进行混合
    vec4 final_color = mix(base_color, glow_color, pulse * edge_falloff * base_color.a);
    COLOR = vec4(final_color.rgb, base_color.a);
}
