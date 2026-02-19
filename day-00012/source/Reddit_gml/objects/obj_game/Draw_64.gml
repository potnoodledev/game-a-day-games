// ========================================
// GAME OF LIFE — Draw_64.gml (Rogue-like)
// ========================================

if (game_state == 0) {
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.5, "Loading...", 0, scr_w, 2, 2, 0);
    exit;
}

var _font_scale = max(scr_w / 500, 1.2);

// --- Background ---
draw_set_colour(bg_color);
draw_rectangle(0, 0, scr_w, scr_h, false);

// --- Grid area ---
var _gx = grid_offset_x;
var _gy = grid_offset_y;
var _gw = grid_cols * cell_size;
var _gh = grid_rows * cell_size;
var _cs = cell_size;
var _pad = max(1, floor(_cs * 0.08));

// Grid background
draw_set_colour(grid_bg_color);
draw_rectangle(_gx, _gy, _gx + _gw, _gy + _gh, false);

// --- Walls ---
for (var _r = 0; _r < grid_rows; _r++) {
    for (var _c = 0; _c < grid_cols; _c++) {
        if (wall_grid[_r * grid_cols + _c] == 1) {
            var _wx = _gx + _c * _cs;
            var _wy = _gy + _r * _cs;
            draw_set_colour(wall_color);
            draw_rectangle(_wx, _wy, _wx + _cs, _wy + _cs, false);
            // subtle top-left highlight
            draw_set_colour(wall_hi_color);
            draw_set_alpha(0.4);
            draw_rectangle(_wx, _wy, _wx + _cs, _wy + 1, false);
            draw_rectangle(_wx, _wy, _wx + 1, _wy + _cs, false);
            draw_set_alpha(1);
        }
    }
}

// --- Grid lines (only on non-wall cells) ---
draw_set_colour(grid_line_color);
draw_set_alpha(0.35);
for (var _c = 0; _c <= grid_cols; _c++) {
    var _lx = _gx + _c * _cs;
    draw_line(_lx, _gy, _lx, _gy + _gh);
}
for (var _r = 0; _r <= grid_rows; _r++) {
    var _ly = _gy + _r * _cs;
    draw_line(_gx, _ly, _gx + _gw, _ly);
}
draw_set_alpha(1);

// --- Targets ---
for (var _i = 0; _i < array_length(target_list); _i++) {
    var _t = target_list[_i];
    var _tx = _gx + _t.col * _cs;
    var _ty = _gy + _t.row * _cs;
    var _tcx = _tx + _cs * 0.5;
    var _tcy = _ty + _cs * 0.5;

    if (_t.hit) {
        // Hit target: filled gold
        draw_set_colour(target_hit_color);
        draw_set_alpha(0.3);
        draw_rectangle(_tx + _pad, _ty + _pad, _tx + _cs - _pad, _ty + _cs - _pad, false);
        draw_set_alpha(1);
    } else {
        // Unhit target: pulsing gold diamond
        var _pulse = 0.6 + sin(current_time * 0.005 + _i * 1.5) * 0.3;
        draw_set_alpha(_pulse);
        draw_set_colour(target_color);
        var _half = (_cs - _pad * 2) * 0.45;
        // Diamond shape using 4 triangles
        draw_triangle(_tcx, _tcy - _half, _tcx + _half, _tcy, _tcx, _tcy + _half, false);
        draw_triangle(_tcx, _tcy - _half, _tcx - _half, _tcy, _tcx, _tcy + _half, false);
        draw_set_alpha(1);
    }
}

// --- Alive Cells ---
for (var _r = 0; _r < grid_rows; _r++) {
    for (var _c = 0; _c < grid_cols; _c++) {
        if (grid[_r * grid_cols + _c] == 1) {
            var _cx = _gx + _c * _cs + _pad;
            var _cy = _gy + _r * _cs + _pad;
            var _cw = _cs - _pad * 2;

            // Check if this cell is on a target
            var _on_target = false;
            for (var _ti = 0; _ti < array_length(target_list); _ti++) {
                if (target_list[_ti].col == _c && target_list[_ti].row == _r) {
                    _on_target = true;
                    break;
                }
            }

            if (_on_target) {
                draw_set_colour(target_hit_color);
            } else {
                draw_set_colour(cell_alive_color);
            }
            draw_rectangle(_cx, _cy, _cx + _cw, _cy + _cw, false);

            // Highlight corner
            draw_set_colour(cell_highlight_color);
            draw_set_alpha(0.3);
            var _hl = max(2, floor(_cw * 0.35));
            draw_rectangle(_cx, _cy, _cx + _hl, _cy + _hl, false);
            draw_set_alpha(1);
        }
    }
}

// --- HUD (top bar) ---
var _hud_y = grid_offset_y * 0.5;

// Score (left)
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_ext_transformed(8, _hud_y, string(points), 0, scr_w, _font_scale * 1.3, _font_scale * 1.3, 0);

// Round (center)
draw_set_halign(fa_center);
draw_set_colour(make_color_rgb(150, 150, 180));
draw_text_ext_transformed(scr_w * 0.5, _hud_y, "Round " + string(round_num) + "/" + string(max_rounds), 0, scr_w, _font_scale * 0.9, _font_scale * 0.9, 0);

// Right side info
draw_set_halign(fa_right);
if (game_state == 1) {
    // Budget
    var _budget_clr = (cells_placed >= cell_budget) ? make_color_rgb(255, 100, 100) : make_color_rgb(100, 220, 160);
    draw_set_colour(_budget_clr);
    draw_text_ext_transformed(scr_w - 8, _hud_y, string(cells_placed) + "/" + string(cell_budget), 0, scr_w, _font_scale * 1.1, _font_scale * 1.1, 0);
} else if (game_state == 2) {
    // Generation
    draw_set_colour(make_color_rgb(100, 180, 255));
    draw_text_ext_transformed(scr_w - 8, _hud_y, "Gen " + string(sim_generation), 0, scr_w, _font_scale * 0.9, _font_scale * 0.9, 0);
}

// --- Targets remaining indicator (below round) ---
if (game_state == 1 || game_state == 2) {
    var _total_targets = array_length(target_list);
    if (_total_targets > 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_colour(target_color);
        var _tgt_scale = _font_scale * 0.6;
        var _tgt_text = string(targets_hit) + "/" + string(_total_targets) + " targets";
        draw_text_ext_transformed(scr_w * 0.5, _hud_y + _font_scale * 10, _tgt_text, 0, scr_w, _tgt_scale, _tgt_scale, 0);
    }
}

// --- Simulation info ---
if (game_state == 2) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_colour(cell_alive_color);
    var _info_y = _gy - 3;
    var _info_scale = _font_scale * 0.65;
    draw_text_ext_transformed(scr_w * 0.5, _info_y, "Pop: " + string(sim_population) + "  Peak: " + string(sim_peak_population), 0, scr_w, _info_scale, _info_scale, 0);

    // Generation progress bar
    var _bar_y = _gy + _gh + 2;
    var _bar_h = 3;
    var _prog = clamp(sim_generation / sim_max_gens, 0, 1);
    draw_set_colour(make_color_rgb(40, 40, 60));
    draw_rectangle(_gx, _bar_y, _gx + _gw, _bar_y + _bar_h, false);
    draw_set_colour(make_color_rgb(80, 160, 255));
    draw_rectangle(_gx, _bar_y, _gx + _gw * _prog, _bar_y + _bar_h, false);

    // Fast-forward hint
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    if (!sim_fast) {
        draw_set_alpha(0.35);
        draw_set_colour(c_white);
        draw_text_ext_transformed(scr_w * 0.5, _bar_y + _bar_h + 4, "tap to fast-forward", 0, scr_w, _font_scale * 0.55, _font_scale * 0.55, 0);
        draw_set_alpha(1);
    } else {
        draw_set_colour(make_color_rgb(255, 215, 0));
        draw_text_ext_transformed(scr_w * 0.5, _bar_y + _bar_h + 4, ">> FAST >>", 0, scr_w, _font_scale * 0.65, _font_scale * 0.65, 0);
    }
}

// --- Placing UI: buttons ---
if (game_state == 1) {
    // CLEAR button
    draw_set_colour(make_color_rgb(50, 40, 45));
    draw_roundrect(clr_btn_x, btn_y, clr_btn_x + clr_btn_w, btn_y + btn_h, false);
    draw_set_colour(make_color_rgb(65, 55, 60));
    draw_roundrect(clr_btn_x, btn_y, clr_btn_x + clr_btn_w, btn_y + btn_h, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(make_color_rgb(200, 160, 160));
    draw_text_ext_transformed(clr_btn_x + clr_btn_w * 0.5, btn_y + btn_h * 0.5, "CLEAR", 0, scr_w, _font_scale * 0.8, _font_scale * 0.8, 0);

    // GO button
    if (cells_placed > 0) {
        draw_set_colour(make_color_rgb(0, 160, 80));
    } else {
        draw_set_colour(make_color_rgb(40, 50, 45));
    }
    draw_roundrect(go_btn_x, btn_y, go_btn_x + go_btn_w, btn_y + btn_h, false);
    if (cells_placed > 0) {
        draw_set_colour(make_color_rgb(0, 220, 110));
    } else {
        draw_set_colour(make_color_rgb(50, 60, 55));
    }
    draw_roundrect(go_btn_x, btn_y, go_btn_x + go_btn_w, btn_y + btn_h, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(c_white);
    draw_text_ext_transformed(go_btn_x + go_btn_w * 0.5, btn_y + btn_h * 0.5, "GO", 0, scr_w, _font_scale * 1.2, _font_scale * 1.2, 0);

    // Hint text
    if (cells_placed == 0) {
        var _pulse = 0.3 + sin(current_time * 0.004) * 0.25;
        draw_set_alpha(_pulse);
        draw_set_colour(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_ext_transformed(scr_w * 0.5, _gy + _gh * 0.5, "Tap to place cells\nReach the targets!", 20, scr_w * 0.8, _font_scale * 0.9, _font_scale * 0.9, 0);
        draw_set_alpha(1);
    }
}

// --- Popups ---
for (var _i = 0; _i < array_length(popups); _i++) {
    var _p = popups[_i];
    var _alpha = clamp(_p.t / 12, 0, 1);
    draw_set_alpha(_alpha);
    draw_set_colour(_p.clr);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_p.x, _p.y, _p.txt, 0, scr_w, _font_scale * 0.9, _font_scale * 0.9, 0);
}
draw_set_alpha(1);

// =========================================
// POWER-UP SELECTION OVERLAY
// =========================================
if (game_state == 3) {
    draw_set_alpha(0.7);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Round complete header
    draw_set_colour(cell_alive_color);
    var _ts = _font_scale * 1.6;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.12, "Round " + string(round_num) + " Complete", 0, scr_w, _ts, _ts, 0);

    // Stats
    draw_set_colour(c_white);
    var _ts2 = _font_scale * 0.85;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.2, "Peak: " + string(sim_peak_population) + "  |  " + string(sim_generation) + " gens  |  " + string(targets_hit) + "/" + string(array_length(target_list)) + " targets", 0, scr_w * 0.95, _ts2, _ts2, 0);

    // Round score
    draw_set_colour(make_color_rgb(255, 215, 0));
    var _ts3 = _font_scale * 1.5;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.29, "+" + string(round_score), 0, scr_w, _ts3, _ts3, 0);

    // "Choose a power-up"
    draw_set_colour(make_color_rgb(180, 180, 210));
    var _ts4 = _font_scale * 1.0;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.38, "Choose a power-up:", 0, scr_w, _ts4, _ts4, 0);

    // Card 1
    var _pu1 = powerup_options[0];
    var _c1 = pu_colors[_pu1];
    draw_set_colour(make_color_rgb(30, 30, 50));
    draw_roundrect(card_x, card1_y, card_x + card_w, card1_y + card_h, false);
    draw_set_colour(_c1);
    draw_roundrect(card_x, card1_y, card_x + card_w, card1_y + card_h, true);
    // Accent bar
    draw_set_colour(_c1);
    draw_rectangle(card_x, card1_y, card_x + 5, card1_y + card_h, false);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_colour(_c1);
    var _name_scale = _font_scale * 1.1;
    draw_text_ext_transformed(card_x + 16, card1_y + card_h * 0.35, get_powerup_name(_pu1), 0, card_w, _name_scale, _name_scale, 0);
    draw_set_colour(make_color_rgb(160, 160, 180));
    var _desc_scale = _font_scale * 0.7;
    draw_text_ext_transformed(card_x + 16, card1_y + card_h * 0.7, get_powerup_desc(_pu1), 0, card_w - 24, _desc_scale, _desc_scale, 0);

    // Card 2
    var _pu2 = powerup_options[1];
    var _c2 = pu_colors[_pu2];
    draw_set_colour(make_color_rgb(30, 30, 50));
    draw_roundrect(card_x, card2_y, card_x + card_w, card2_y + card_h, false);
    draw_set_colour(_c2);
    draw_roundrect(card_x, card2_y, card_x + card_w, card2_y + card_h, true);
    draw_set_colour(_c2);
    draw_rectangle(card_x, card2_y, card_x + 5, card2_y + card_h, false);

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_set_colour(_c2);
    draw_text_ext_transformed(card_x + 16, card2_y + card_h * 0.35, get_powerup_name(_pu2), 0, card_w, _name_scale, _name_scale, 0);
    draw_set_colour(make_color_rgb(160, 160, 180));
    draw_text_ext_transformed(card_x + 16, card2_y + card_h * 0.7, get_powerup_desc(_pu2), 0, card_w - 24, _desc_scale, _desc_scale, 0);
}

// =========================================
// GAME OVER OVERLAY
// =========================================
if (game_state == 4) {
    draw_set_alpha(0.75);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, scr_w, scr_h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    draw_set_colour(cell_alive_color);
    var _ts = _font_scale * 2.2;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.2, "Game Complete!", 0, scr_w, _ts, _ts, 0);

    // Total score
    draw_set_colour(c_white);
    var _ts2 = _font_scale * 2.0;
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.32, string(points), 0, scr_w, _ts2, _ts2, 0);

    // Round breakdown
    draw_set_colour(make_color_rgb(130, 130, 160));
    var _ts3 = _font_scale * 0.7;
    var _by = scr_h * 0.42;
    for (var _i = 0; _i < array_length(round_scores); _i++) {
        draw_text_ext_transformed(scr_w * 0.5, _by + _i * 15 * _font_scale, "Round " + string(_i + 1) + ":  " + string(round_scores[_i]), 0, scr_w, _ts3, _ts3, 0);
    }

    // Tap to restart
    var _pulse = 0.35 + sin(current_time * 0.005) * 0.35;
    draw_set_alpha(_pulse);
    draw_set_colour(c_white);
    draw_text_ext_transformed(scr_w * 0.5, scr_h * 0.82, "Tap to play again", 0, scr_w, _font_scale, _font_scale, 0);
    draw_set_alpha(1);
}

// Reset draw state
draw_set_alpha(1);
draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
