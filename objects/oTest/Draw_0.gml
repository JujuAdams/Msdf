// Feather disable all

draw_line(20, 0, 20, room_height);

var _string = "Hello\nWorld";

//draw_set_font(fArial);
//MsdfDrawText(20, 20, _string);

shader_set(__shdMsdf);
draw_set_font(fArial);
draw_text_transformed(20, 20, _string, scale/MSDF_DOWNSCALE, scale/MSDF_DOWNSCALE, 0);
shader_reset();

draw_set_font(fSDFButNotTagged);
draw_text_transformed(220, 20, _string, scale, scale, 0);
draw_text_transformed(20, 200, _string, scale, scale, 0);

//shader_set(sMsdfTest);
//shader_set_uniform_f(shader_get_uniform(sMsdfTest, "u_fMsdfRange"), 20);
//draw_sprite_ext(sTest, 0,   0, 0,   5, 5, 0,   c_red, 1);
//shader_reset();