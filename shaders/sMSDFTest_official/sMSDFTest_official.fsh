varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_fMsdfRange;

float median(vec3 v)
{
    return max(min(v.x, v.y), min(max(v.x, v.y), v.z));
}

float pxRange()
{
    vec2 unitRange = vec2(u_fMsdfRange) / vec2(220.0);
    vec2 screenTexSize = vec2(1.0) / fwidth(v_vTexcoord);
    return max(0.5*dot(unitRange, screenTexSize), 1.0);
}

void main()
{
    vec4 sample = texture2D(gm_BaseTexture, v_vTexcoord);
    float baseDist = median(sample.rgb);
    float screenPxDistance = pxRange()*(baseDist - 0.5);
    float opacity = clamp(screenPxDistance + 0.5, 0.0, 1.0);
    gl_FragColor = vec4(v_vColour.rgb, v_vColour.a*opacity);
}