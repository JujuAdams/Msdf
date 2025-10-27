// Feather disable all

var _string = "Hello World";

MsdfSetShader();
draw_set_font(fArialMSDF);
draw_text_transformed(20, 20, _string, scale, scale, 0);
shader_reset();

var _width = string_width(_string);

draw_set_font(fSDFButNotTagged);
draw_text_transformed(20 + scale*_width, 20, _string, scale, scale, 0);
draw_text_transformed(20, 20 + scale*40, _string, scale, scale, 0);

draw_set_font(fRaster);
draw_text_transformed(20 + scale*_width, 20 + scale*40, _string, scale, scale, 0);