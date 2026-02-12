
var _sw = window_get_width();
var _sh = window_get_height();
var _cx = _sw * 0.5;

draw_set_font(fnt_default);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

// Helper macro: draw text with outline (no closure — GML HTML5 can't capture outer locals)
#macro OUTLINE_OFF 2

if (game_state == 0) {
    // Title screen
    draw_set_colour(c_orange);
    draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.25, "FLAPPY CAT", 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.25, "FLAPPY CAT", 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx, _sh * 0.25 - OUTLINE_OFF, "FLAPPY CAT", 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx, _sh * 0.25 + OUTLINE_OFF, "FLAPPY CAT", 0, _sw, 4, 4, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _sh * 0.25, "FLAPPY CAT", 0, _sw, 4, 4, 0);

    draw_set_colour(c_black);
    draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.45, "Tap or press Space to start!", 0, _sw, 2, 2, 0);
    draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.45, "Tap or press Space to start!", 0, _sw, 2, 2, 0);
    draw_text_ext_transformed(_cx, _sh * 0.45 - OUTLINE_OFF, "Tap or press Space to start!", 0, _sw, 2, 2, 0);
    draw_text_ext_transformed(_cx, _sh * 0.45 + OUTLINE_OFF, "Tap or press Space to start!", 0, _sw, 2, 2, 0);
    draw_set_colour(c_yellow);
    draw_text_ext_transformed(_cx, _sh * 0.45, "Tap or press Space to start!", 0, _sw, 2, 2, 0);

    if (points > 0) {
        var _best = $"Best: {points}";
        draw_set_colour(c_black);
        draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.62, _best, 0, _sw, 2.5, 2.5, 0);
        draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.62, _best, 0, _sw, 2.5, 2.5, 0);
        draw_text_ext_transformed(_cx, _sh * 0.62 - OUTLINE_OFF, _best, 0, _sw, 2.5, 2.5, 0);
        draw_text_ext_transformed(_cx, _sh * 0.62 + OUTLINE_OFF, _best, 0, _sw, 2.5, 2.5, 0);
        draw_set_colour(c_lime);
        draw_text_ext_transformed(_cx, _sh * 0.62, _best, 0, _sw, 2.5, 2.5, 0);
    }

    // Bouncing cat hint
    var _bob = sin(current_time * 0.004) * 8;
    var _by = _sh * 0.78 + _bob;
    draw_set_colour(c_orange);
    draw_text_ext_transformed(_cx - OUTLINE_OFF, _by, "^ _ ^", 0, _sw, 3, 3, 0);
    draw_text_ext_transformed(_cx + OUTLINE_OFF, _by, "^ _ ^", 0, _sw, 3, 3, 0);
    draw_text_ext_transformed(_cx, _by - OUTLINE_OFF, "^ _ ^", 0, _sw, 3, 3, 0);
    draw_text_ext_transformed(_cx, _by + OUTLINE_OFF, "^ _ ^", 0, _sw, 3, 3, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _by, "^ _ ^", 0, _sw, 3, 3, 0);

} else if (game_state == 1) {
    // Score display during gameplay
    var _score_str = string(current_score);
    draw_set_colour(c_black);
    draw_text_ext_transformed(_cx - OUTLINE_OFF, 50, _score_str, 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx + OUTLINE_OFF, 50, _score_str, 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx, 50 - OUTLINE_OFF, _score_str, 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx, 50 + OUTLINE_OFF, _score_str, 0, _sw, 4, 4, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, 50, _score_str, 0, _sw, 4, 4, 0);

} else if (game_state == 2) {
    // Death screen
    draw_set_colour(c_red);
    draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.25, "GAME OVER", 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.25, "GAME OVER", 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx, _sh * 0.25 - OUTLINE_OFF, "GAME OVER", 0, _sw, 4, 4, 0);
    draw_text_ext_transformed(_cx, _sh * 0.25 + OUTLINE_OFF, "GAME OVER", 0, _sw, 4, 4, 0);
    draw_set_colour(c_white);
    draw_text_ext_transformed(_cx, _sh * 0.25, "GAME OVER", 0, _sw, 4, 4, 0);

    var _score_text = $"Score: {current_score}";
    draw_set_colour(c_black);
    draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.42, _score_text, 0, _sw, 3, 3, 0);
    draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.42, _score_text, 0, _sw, 3, 3, 0);
    draw_text_ext_transformed(_cx, _sh * 0.42 - OUTLINE_OFF, _score_text, 0, _sw, 3, 3, 0);
    draw_text_ext_transformed(_cx, _sh * 0.42 + OUTLINE_OFF, _score_text, 0, _sw, 3, 3, 0);
    draw_set_colour(c_yellow);
    draw_text_ext_transformed(_cx, _sh * 0.42, _score_text, 0, _sw, 3, 3, 0);

    if (current_score >= points && current_score > 0) {
        draw_set_colour(c_orange);
        draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.55, "NEW BEST!", 0, _sw, 2.5, 2.5, 0);
        draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.55, "NEW BEST!", 0, _sw, 2.5, 2.5, 0);
        draw_text_ext_transformed(_cx, _sh * 0.55 - OUTLINE_OFF, "NEW BEST!", 0, _sw, 2.5, 2.5, 0);
        draw_text_ext_transformed(_cx, _sh * 0.55 + OUTLINE_OFF, "NEW BEST!", 0, _sw, 2.5, 2.5, 0);
        draw_set_colour(c_lime);
        draw_text_ext_transformed(_cx, _sh * 0.55, "NEW BEST!", 0, _sw, 2.5, 2.5, 0);
    } else {
        var _best2 = $"Best: {points}";
        draw_set_colour(c_black);
        draw_text_ext_transformed(_cx - OUTLINE_OFF, _sh * 0.55, _best2, 0, _sw, 2, 2, 0);
        draw_text_ext_transformed(_cx + OUTLINE_OFF, _sh * 0.55, _best2, 0, _sw, 2, 2, 0);
        draw_text_ext_transformed(_cx, _sh * 0.55 - OUTLINE_OFF, _best2, 0, _sw, 2, 2, 0);
        draw_text_ext_transformed(_cx, _sh * 0.55 + OUTLINE_OFF, _best2, 0, _sw, 2, 2, 0);
        draw_set_colour(c_lime);
        draw_text_ext_transformed(_cx, _sh * 0.55, _best2, 0, _sw, 2, 2, 0);
    }

    if (death_timer <= 0) {
        var _bob2 = sin(current_time * 0.005) * 4;
        var _ry = _sh * 0.72 + _bob2;
        draw_set_colour(c_black);
        draw_text_ext_transformed(_cx - OUTLINE_OFF, _ry, "Tap to try again", 0, _sw, 2, 2, 0);
        draw_text_ext_transformed(_cx + OUTLINE_OFF, _ry, "Tap to try again", 0, _sw, 2, 2, 0);
        draw_text_ext_transformed(_cx, _ry - OUTLINE_OFF, "Tap to try again", 0, _sw, 2, 2, 0);
        draw_text_ext_transformed(_cx, _ry + OUTLINE_OFF, "Tap to try again", 0, _sw, 2, 2, 0);
        draw_set_colour(c_white);
        draw_text_ext_transformed(_cx, _ry, "Tap to try again", 0, _sw, 2, 2, 0);
    }
}

// Always show username in corner (small)
if (username != "") {
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_gray);
    draw_text_ext_transformed(8, 8, username, 0, _sw, 1, 1, 0);
}
