// Feather disable all

/// @param x
/// @param y
/// @param string

function MsdfDrawText(_x, _y, _string)
{
    shader_set(__shdMsdf);
    draw_text(_x, _y, _string);
    shader_reset();
}