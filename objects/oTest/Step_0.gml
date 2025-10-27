// Feather disable all

if (mouse_check_button(mb_left))
{
    scale = lerp(0.1, 10, clamp(mouse_x / room_width, 0, 1));
}