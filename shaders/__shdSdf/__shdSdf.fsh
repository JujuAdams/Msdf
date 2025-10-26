#define SMOOTHNESS  0.75

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_fMsdfRange;

float median(vec3 v)
{
    return max(min(v.x, v.y), min(max(v.x, v.y), v.z));
}

float SdfValue(vec2 texcoord)
{
    return texture2D(gm_BaseTexture, texcoord).a;
}

float MsdfValue(vec2 texcoord)
{
    return median(texture2D(gm_BaseTexture, texcoord).rgb);
}

void main()
{
    float baseDist = SdfValue(v_vTexcoord);
    float spread = max(fwidth(baseDist), 0.001);
    float alpha = smoothstep(0.5 - SMOOTHNESS*spread, 0.5 + SMOOTHNESS*spread, baseDist);   
    gl_FragColor = vec4(v_vColour.rgb, alpha*v_vColour.a);
}