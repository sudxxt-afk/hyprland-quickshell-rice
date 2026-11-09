#version 300 es
// Лёгкое плёночное зерно + виньетка поверх всего экрана.
// Без uniform time: зерно статичное, поэтому Hyprland перерисовывает только
// повреждённые области, а не весь экран каждый кадр (важно для iGPU и батареи).
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float GRAIN    = 0.035; // сила зерна
const float VIGNETTE = 0.22;  // насколько темнеют углы

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

void main() {
    vec4 c = texture(tex, v_texcoord);

    float n = hash(gl_FragCoord.xy) - 0.5;
    c.rgb += n * GRAIN;

    vec2 d = v_texcoord - 0.5;
    c.rgb *= 1.0 - VIGNETTE * smoothstep(0.35, 0.85, length(d) * 1.4);

    fragColor = c;
}
