
var _w = window_get_width();
var _h = window_get_height();

// Road dimensions
var _road_w = _w * 0.6;
var _road_x = (_w - _road_w) * 0.5;
var _lane_w = _road_w / lane_count;

// Draw grass background
draw_set_colour(make_colour_rgb(34, 120, 34));
draw_rectangle(0, 0, _w, _h, false);

// Draw road
draw_set_colour(make_colour_rgb(60, 60, 60));
draw_rectangle(_road_x, 0, _road_x + _road_w, _h, false);

// Road edges (white lines)
draw_set_colour(c_white);
draw_rectangle(_road_x - 2, 0, _road_x + 2, _h, false);
draw_rectangle(_road_x + _road_w - 2, 0, _road_x + _road_w + 2, _h, false);

// Dashed lane lines
draw_set_colour(c_yellow);
var _dash_h = 40;
var _gap_h = 30;
var _cycle = _dash_h + _gap_h;
var _scroll = line_offset mod _cycle;

for (var _l = 1; _l < lane_count; _l++) {
    var _lx = _road_x + _lane_w * _l;
    var _ly = -_cycle + _scroll;
    while (_ly < _h) {
        draw_rectangle(_lx - 2, _ly, _lx + 2, _ly + _dash_h, false);
        _ly += _cycle;
    }
}

// Draw player car
if (instance_exists(obj_player) && !game_over) {
    var _px = obj_player.x;
    var _py = obj_player.y;
    // Car body (green)
    draw_set_colour(make_colour_rgb(0, 200, 60));
    draw_rectangle(_px - 20, _py - 30, _px + 20, _py + 30, false);
    // Windshield
    draw_set_colour(make_colour_rgb(100, 200, 255));
    draw_rectangle(_px - 14, _py - 20, _px + 14, _py - 6, false);
    // Wheels
    draw_set_colour(c_black);
    draw_rectangle(_px - 24, _py - 22, _px - 18, _py - 10, false);
    draw_rectangle(_px + 18, _py - 22, _px + 24, _py - 10, false);
    draw_rectangle(_px - 24, _py + 10, _px - 18, _py + 22, false);
    draw_rectangle(_px + 18, _py + 10, _px + 24, _py + 22, false);
}

// Draw obstacles
with (obj_obstacle) {
    var _ox = x;
    var _oy = y;
    // Car body (red)
    draw_set_colour(make_colour_rgb(200, 40, 40));
    draw_rectangle(_ox - 20, _oy - 30, _ox + 20, _oy + 30, false);
    // Windshield (facing player = rear window)
    draw_set_colour(make_colour_rgb(80, 80, 80));
    draw_rectangle(_ox - 14, _oy + 6, _ox + 14, _oy + 20, false);
    // Wheels
    draw_set_colour(c_black);
    draw_rectangle(_ox - 24, _oy - 22, _ox - 18, _oy - 10, false);
    draw_rectangle(_ox + 18, _oy - 22, _ox + 24, _oy - 10, false);
    draw_rectangle(_ox - 24, _oy + 10, _ox - 18, _oy + 22, false);
    draw_rectangle(_ox + 18, _oy + 10, _ox + 24, _oy + 22, false);
}

// Touch zone hints
if (game_active && !game_over) {
    draw_set_alpha(0.06);
    draw_set_colour(c_white);
    draw_rectangle(0, 0, _w * 0.4, _h, false);
    draw_rectangle(_w * 0.6, 0, _w, _h, false);
    draw_set_alpha(1);

    draw_set_font(fnt_default);
    draw_set_colour(make_colour_rgb(255, 255, 255));
    draw_set_alpha(0.15);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_w * 0.15, _h * 0.5, "<", 0, _w, 5, 5, 0);
    draw_text_ext_transformed(_w * 0.85, _h * 0.5, ">", 0, _w, 5, 5, 0);
    draw_set_alpha(1);
}

// HUD
draw_set_font(fnt_default);

// Score (top center)
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_colour(c_black);
draw_text_ext_transformed(_w * 0.5 + 2, 12, $"{points}", 20, _w, 2.5, 2.5, 0);
draw_set_colour(c_white);
draw_text_ext_transformed(_w * 0.5, 10, $"{points}", 20, _w, 2.5, 2.5, 0);

// Speed indicator (top left)
draw_set_halign(fa_left);
var _speed_pct = floor((game_speed / max_speed) * 100);
draw_set_colour(c_black);
draw_text_ext_transformed(12, 12, $"SPD: {_speed_pct}%", 20, _w, 1.5, 1.5, 0);
draw_set_colour(c_lime);
draw_text_ext_transformed(10, 10, $"SPD: {_speed_pct}%", 20, _w, 1.5, 1.5, 0);

// Title
draw_set_halign(fa_center);
draw_set_colour(c_white);
draw_set_alpha(0.3);
draw_text_ext_transformed(_w * 0.5, _h - 20, "LANE RACER", 0, _w, 1, 1, 0);
draw_set_alpha(1);

// Game Over overlay
if (game_over) {
    draw_set_alpha(0.7);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour(c_red);
    draw_text_ext_transformed(_w * 0.5, _h * 0.28, "CRASH!", 0, _w, 4.5, 4.5, 0);

    draw_set_colour(c_white);
    draw_text_ext_transformed(_w * 0.5, _h * 0.42, $"Distance: {points}", 0, _w, 2.5, 2.5, 0);

    draw_set_colour(c_yellow);
    draw_text_ext_transformed(_w * 0.5, _h * 0.52, $"Top Speed: {_speed_pct}%", 0, _w, 2, 2, 0);

    draw_set_colour(c_lime);
    draw_text_ext_transformed(_w * 0.5, _h * 0.72, "Tap to Race Again", 0, _w, 2, 2, 0);
}
