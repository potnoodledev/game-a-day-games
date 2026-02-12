
var _pulse = 1 + sin(degtorad(wobble * 3)) * 0.15;
draw_sprite_ext(spr_bomb, 0, x, y, _pulse, _pulse, wobble, c_white, 1);
