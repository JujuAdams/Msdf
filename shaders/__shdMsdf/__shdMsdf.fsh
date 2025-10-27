#define SMOOTHNESS  0.75

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

float median(vec3 v)
{
    return max(min(v.x, v.y), min(max(v.x, v.y), v.z));
}

void main()
{
    vec4 sample = texture2D(gm_BaseTexture, v_vTexcoord);
    
    float baseDist;
    if (all(equal(sample.rgb, vec3(1.0))))
    {
        baseDist = sample.a;
    }
    else
    {
        baseDist = median(sample.rgb);
    }
    
    float spread = max(fwidth(baseDist), 0.001);
    float alpha = smoothstep(0.5 - SMOOTHNESS*spread, 0.5 + SMOOTHNESS*spread, baseDist);
    
    gl_FragColor = vec4(v_vColour.rgb, alpha*v_vColour.a);
}