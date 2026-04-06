shader_type canvas_item;

// Void Rift Distort Shader
// 用途：深渊污染点、隐藏裂隙扭曲，克制的黑色污染，依赖噪声贴图

uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;
uniform float time_scale : hint_range(0.0, 5.0) = 1.5;
uniform vec4 void_color : source_color = vec4(0.2, 0.0, 0.3, 1.0); // 极深邃的紫黑色深渊
uniform sampler2D noise_tex : repeat_enable; // 必须赋一张外部噪点/云朵贴图

void fragment() {
    // 根据时间流动扭曲 UV，取随机噪波
    vec2 scroll_uv = UV + vec2(TIME * 0.1, TIME * -0.15) * time_scale;
    float noise_val = texture(noise_tex, scroll_uv).r;
    
    // 把当前坐标推走，实现类似水面/裂空的折射效果
    vec2 distorted_uv = UV + (noise_val - 0.5) * distortion_strength;
    vec4 base_color = texture(TEXTURE, distorted_uv);
    
    // 噪声值越大，越会被深渊颜色侵蚀腐化
    float corruption = smoothstep(0.4, 0.8, noise_val);
    
    // 向暗影深渊色混合
    COLOR = mix(base_color, base_color * void_color, corruption);
    COLOR.a = base_color.a;
}
