/// Draw_64 — First Person Tower Defense renderer

var _w = scr_w;
var _h = scr_h;
if (_w < 10) _w = window_get_width();
if (_h < 10) _h = window_get_height();

var _vp_x = _w * 0.5;
var _vp_y = _h * 0.28;
var _base_y = _h * 0.92;
var _road_hw_far = 15;
var _road_hw_near = _w * 0.38;

draw_set_font(fnt_default);

// === BACKGROUND: Sky ===
draw_set_colour(col_sky);
draw_rectangle(0, 0, _w, _vp_y + 20, false);

// === FLOOR ===
draw_set_colour(col_road);
draw_rectangle(0, _vp_y, _w, _h, false);

// === CORRIDOR: Road converging to vanishing point ===
// Left wall
var _lx_far = _vp_x - _road_hw_far;
var _lx_near = _vp_x - _road_hw_near;
draw_set_colour(col_wall_l);
draw_triangle(_lx_far, _vp_y, _lx_near, _base_y, 0, _base_y, false);

// Right wall
var _rx_far = _vp_x + _road_hw_far;
var _rx_near = _vp_x + _road_hw_near;
draw_set_colour(col_wall_r);
draw_triangle(_rx_far, _vp_y, _rx_near, _base_y, _w, _base_y, false);

// Ceiling
draw_set_colour(col_ceil);
draw_triangle(_lx_far, _vp_y, _rx_far, _vp_y, 0, 0, false);
draw_triangle(_rx_far, _vp_y, 0, 0, _w, 0, false);

// Road floor (darker)
var _col_floor2 = make_colour_rgb(40, 38, 55);
draw_set_colour(_col_floor2);
// Draw road trapezoid
draw_triangle(_lx_far, _vp_y, _rx_far, _vp_y, _lx_near, _base_y, false);
draw_triangle(_rx_far, _vp_y, _rx_near, _base_y, _lx_near, _base_y, false);

// Road lane lines (dashed)
draw_set_colour(make_colour_rgb(80, 75, 100));
draw_set_alpha(0.4);
for (var _d = 0.05; _d < 1.0; _d += 0.08) {
    var _ls = 0.1 + _d * 0.9;
    var _ly = lerp(_vp_y, _base_y, _d);
    var _lhw = lerp(_road_hw_far, _road_hw_near, _d);
    var _lw_line = 2 * _ls;
    // Left divider
    draw_rectangle(_vp_x - _lhw * 0.33 - _lw_line, _ly - 2 * _ls, _vp_x - _lhw * 0.33 + _lw_line, _ly + 2 * _ls, false);
    // Right divider
    draw_rectangle(_vp_x + _lhw * 0.33 - _lw_line, _ly - 2 * _ls, _vp_x + _lhw * 0.33 + _lw_line, _ly + 2 * _ls, false);
}
draw_set_alpha(1.0);

// === TOWER SLOTS ===
for (var ti = 0; ti < tower_count; ti++) {
    var _td = tower_slot_depth[ti];
    var _tscale = 0.1 + _td * 0.9;
    var _road_hw = lerp(_road_hw_far, _road_hw_near, _td);
    var _tsx = _vp_x + tower_side[ti] * (_road_hw + 20 * _tscale);
    var _tsy = lerp(_vp_y, _base_y, _td);
    var _sz = 18 * _tscale + 10;

    if (tower_has[ti]) {
        // Draw tower as a triangle (turret)
        var _tcol = make_colour_rgb(60, 180, 255);
        if (tower_level[ti] >= 3) _tcol = make_colour_rgb(255, 200, 50);
        else if (tower_level[ti] >= 2) _tcol = make_colour_rgb(100, 255, 150);
        draw_set_colour(_tcol);
        draw_triangle(_tsx, _tsy - _sz * 1.6, _tsx - _sz, _tsy + _sz * 0.4, _tsx + _sz, _tsy + _sz * 0.4, false);
        // Base
        draw_set_colour(make_colour_rgb(80, 80, 120));
        draw_rectangle(_tsx - _sz * 0.9, _tsy + _sz * 0.4, _tsx + _sz * 0.9, _tsy + _sz * 0.9, false);
        // Level indicator
        if (tower_level[ti] > 1) {
            draw_set_colour(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text_ext_transformed(_tsx, _tsy - _sz * 0.3, string(tower_level[ti]), 0, 200, _tscale * 1.8, _tscale * 1.8, 0);
        }
    } else {
        // Empty slot outline
        draw_set_colour(make_colour_rgb(120, 120, 160));
        draw_set_alpha(0.6);
        draw_rectangle(_tsx - _sz, _tsy - _sz, _tsx + _sz, _tsy + _sz, true);
        // Inner fill
        draw_set_colour(make_colour_rgb(60, 60, 90));
        draw_set_alpha(0.3);
        draw_rectangle(_tsx - _sz + 1, _tsy - _sz + 1, _tsx + _sz - 1, _tsy + _sz - 1, false);
        // Plus sign
        draw_set_alpha(0.8);
        draw_set_colour(make_colour_rgb(180, 180, 220));
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_ext_transformed(_tsx, _tsy, "+", 0, 200, _tscale * 2.5, _tscale * 2.5, 0);
        draw_set_alpha(1.0);
    }
}

// === ENEMIES ===
for (var ei = 0; ei < enemy_max; ei++) {
    if (!enemy_active[ei]) continue;

    var _ed = enemy_depth[ei];
    var _escale = 0.1 + _ed * 0.9;
    var _eroad_hw = lerp(_road_hw_far, _road_hw_near, _ed);
    var _esx = _vp_x + enemy_lane[ei] * _eroad_hw * 0.5 + enemy_x_off[ei] * _escale;
    var _esy = lerp(_vp_y, _base_y, _ed);
    var _esize = 10 + 22 * _escale;

    // Color by type
    var _ecol = make_colour_rgb(220, 60, 60); // basic red
    if (enemy_type[ei] == 1) _ecol = make_colour_rgb(255, 160, 40); // fast orange
    if (enemy_type[ei] == 2) _ecol = make_colour_rgb(150, 60, 200); // tank purple

    // Flash white on hit
    if (enemy_hit[ei] > 0) _ecol = c_white;

    draw_set_colour(_ecol);

    if (enemy_type[ei] == 2) {
        // Tank: larger rectangle
        draw_rectangle(_esx - _esize * 0.8, _esy - _esize, _esx + _esize * 0.8, _esy + _esize * 0.3, false);
        draw_set_colour(merge_colour(_ecol, c_black, 0.3));
        draw_rectangle(_esx - _esize * 0.6, _esy - _esize * 1.2, _esx + _esize * 0.6, _esy - _esize, false);
    } else if (enemy_type[ei] == 1) {
        // Fast: diamond
        draw_triangle(_esx, _esy - _esize, _esx - _esize * 0.6, _esy, _esx + _esize * 0.6, _esy, false);
        draw_triangle(_esx - _esize * 0.6, _esy, _esx + _esize * 0.6, _esy, _esx, _esy + _esize * 0.5, false);
    } else {
        // Basic: circle
        draw_circle(_esx, _esy - _esize * 0.3, _esize * 0.7, false);
    }

    // HP bar
    if (enemy_hp[ei] < enemy_hp_max[ei]) {
        var _bar_w = _esize * 1.2;
        var _bar_h = 3 * _escale + 1;
        var _bar_x = _esx - _bar_w * 0.5;
        var _bar_y = _esy - _esize * 1.3;
        draw_set_colour(c_black);
        draw_rectangle(_bar_x - 1, _bar_y - 1, _bar_x + _bar_w + 1, _bar_y + _bar_h + 1, false);
        draw_set_colour(c_red);
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
        draw_set_colour(c_lime);
        var _hp_ratio = enemy_hp[ei] / enemy_hp_max[ei];
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _hp_ratio, _bar_y + _bar_h, false);
    }
}

// === PROJECTILES ===
draw_set_colour(make_colour_rgb(255, 255, 100));
for (var i = 0; i < proj_max; i++) {
    if (!proj_active[i]) continue;
    var _t = 1.0 - (proj_life[i] / proj_life_max[i]);
    var _px = lerp(proj_sx[i], proj_tx[i], _t);
    var _py = lerp(proj_sy[i], proj_ty[i], _t);
    draw_circle(_px, _py, 3, false);
}

// === TAP EFFECTS ===
for (var i = 0; i < tap_fx_max; i++) {
    if (!tap_fx_active[i]) continue;
    var _t = tap_fx_life[i] / 10.0;
    var _radius = 15 + (1 - _t) * 20;
    draw_set_alpha(_t);
    draw_set_colour(c_white);
    draw_circle(tap_fx_x[i], tap_fx_y[i], _radius, true);
    draw_set_alpha(1.0);
}

// === FLOAT TEXT ===
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var i = 0; i < float_max; i++) {
    if (!float_active[i]) continue;
    var _alpha = min(1.0, float_life[i] / 20.0);
    draw_set_alpha(_alpha);
    draw_set_colour(float_col[i]);
    var _fscale = 1.5;
    if (float_col[i] == c_yellow) _fscale = 2.5; // wave text bigger
    draw_text_ext_transformed(float_x[i], float_y[i], float_text[i], 0, 400, _fscale, _fscale, 0);
}
draw_set_alpha(1.0);

// === DAMAGE FLASH ===
if (damage_flash > 0) {
    draw_set_alpha(damage_flash / 15.0);
    draw_set_colour(c_red);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);
}

// === HUD ===
var _hud_y = 8;
var _hud_scale = 1.8;
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// HP bar
var _hp_bar_w = _w * 0.35;
var _hp_bar_h = 16;
var _hp_bar_x = 10;
var _hp_bar_y = _hud_y;
draw_set_colour(c_black);
draw_rectangle(_hp_bar_x - 1, _hp_bar_y - 1, _hp_bar_x + _hp_bar_w + 1, _hp_bar_y + _hp_bar_h + 1, false);
draw_set_colour(make_colour_rgb(60, 20, 20));
draw_rectangle(_hp_bar_x, _hp_bar_y, _hp_bar_x + _hp_bar_w, _hp_bar_y + _hp_bar_h, false);
draw_set_colour(make_colour_rgb(220, 40, 40));
var _hp_pct = player_hp / player_hp_max;
draw_rectangle(_hp_bar_x, _hp_bar_y, _hp_bar_x + _hp_bar_w * _hp_pct, _hp_bar_y + _hp_bar_h, false);
draw_set_colour(c_white);
draw_set_halign(fa_center);
draw_text_ext_transformed(_hp_bar_x + _hp_bar_w * 0.5, _hp_bar_y + _hp_bar_h * 0.5 + 1, string(player_hp) + "/" + string(player_hp_max), 0, 400, 1.2, 1.2, 0);

// Gold
draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_colour(make_colour_rgb(255, 215, 0));
draw_text_ext_transformed(_w - 10, _hud_y, string(gold) + "g", 0, 400, _hud_scale, _hud_scale, 0);

// Wave
draw_set_halign(fa_center);
draw_set_colour(c_white);
draw_text_ext_transformed(_w * 0.5, _hud_y, "Wave " + string(wave), 0, 400, _hud_scale, _hud_scale, 0);

// Score
draw_set_halign(fa_left);
draw_set_colour(make_colour_rgb(180, 220, 255));
draw_text_ext_transformed(10, _hud_y + _hp_bar_h + 8, "Score: " + string(points), 0, 400, 1.4, 1.4, 0);

// Kills
draw_set_halign(fa_right);
draw_text_ext_transformed(_w - 10, _hud_y + _hp_bar_h + 26, "Kills: " + string(total_kills), 0, 400, 1.2, 1.2, 0);

// === Between-waves hint ===
if (!wave_active && wave_enemies_alive <= 0 && wave_timer < wave_delay && game_state == 1) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(make_colour_rgb(180, 180, 220));
    draw_set_alpha(0.7 + sin(wave_timer * 0.1) * 0.3);
    var _hint_txt = "Tap [+] slots to place towers";
    if (wave > 0) _hint_txt = "Next wave in " + string(ceil((wave_delay - wave_timer) / 60.0)) + "s - tap [+] for towers";
    draw_text_ext_transformed(_w * 0.5, _h * 0.5, _hint_txt, 0, _w * 0.8, 1.5, 1.5, 0);
    draw_set_alpha(1.0);
}

// === TOWER MENU ===
if (show_tower_menu && selected_tower_slot >= 0) {
    var _si = selected_tower_slot;

    // Darken background
    draw_set_alpha(0.5);
    draw_set_colour(c_black);
    draw_rectangle(0, _h * 0.65, _w, _h, false);
    draw_set_alpha(1.0);

    // Panel
    var _px = _w * 0.5;
    var _py = _h * 0.76;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    if (!tower_has[_si]) {
        // Buy tower
        draw_set_colour(c_white);
        draw_text_ext_transformed(_px, _py - 30, "Build Tower", 0, 400, 2.0, 2.0, 0);
        draw_set_colour(make_colour_rgb(255, 215, 0));
        draw_text_ext_transformed(_px, _py, "Cost: " + string(tower_cost) + "g", 0, 400, 1.6, 1.6, 0);

        // Button
        var _btn_col = (gold >= tower_cost) ? make_colour_rgb(60, 180, 80) : make_colour_rgb(100, 60, 60);
        draw_set_colour(_btn_col);
        draw_rectangle(_px - 80, _h * 0.82 - 25, _px + 80, _h * 0.82 + 25, false);
        draw_set_colour(c_white);
        var _btn_text = (gold >= tower_cost) ? "BUILD" : "Not enough gold";
        draw_text_ext_transformed(_px, _h * 0.82, _btn_text, 0, 300, 1.6, 1.6, 0);
    } else {
        // Upgrade tower
        var _ucost = tower_cost + tower_level[_si] * 30;
        draw_set_colour(c_white);
        draw_text_ext_transformed(_px, _py - 40, "Tower Lv." + string(tower_level[_si]), 0, 400, 2.0, 2.0, 0);
        draw_set_colour(make_colour_rgb(180, 200, 255));
        draw_text_ext_transformed(_px, _py - 10, "DMG:" + string(tower_damage[_si]) + "  RNG:" + string_format(tower_range[_si], 1, 2), 0, 400, 1.3, 1.3, 0);
        draw_set_colour(make_colour_rgb(255, 215, 0));
        draw_text_ext_transformed(_px, _py + 15, "Upgrade: " + string(_ucost) + "g", 0, 400, 1.4, 1.4, 0);

        var _btn_col2 = (gold >= _ucost) ? make_colour_rgb(60, 140, 220) : make_colour_rgb(100, 60, 60);
        draw_set_colour(_btn_col2);
        draw_rectangle(_px - 80, _h * 0.82 - 25, _px + 80, _h * 0.82 + 25, false);
        draw_set_colour(c_white);
        var _btn_text2 = (gold >= _ucost) ? "UPGRADE" : "Not enough gold";
        draw_text_ext_transformed(_px, _h * 0.82, _btn_text2, 0, 300, 1.6, 1.6, 0);
    }
}

// === GAME OVER ===
if (game_state == 2) {
    draw_set_alpha(0.7);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1.0);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_colour(c_red);
    draw_text_ext_transformed(_w * 0.5, _h * 0.3, "GAME OVER", 0, 400, 3.5, 3.5, 0);

    draw_set_colour(c_white);
    draw_text_ext_transformed(_w * 0.5, _h * 0.42, "Wave: " + string(wave), 0, 400, 2.2, 2.2, 0);
    draw_text_ext_transformed(_w * 0.5, _h * 0.48, "Kills: " + string(total_kills), 0, 400, 2.2, 2.2, 0);

    draw_set_colour(make_colour_rgb(255, 215, 0));
    draw_text_ext_transformed(_w * 0.5, _h * 0.56, "Score: " + string(points), 0, 400, 2.8, 2.8, 0);

    draw_set_colour(make_colour_rgb(180, 180, 220));
    draw_set_alpha(0.7 + sin(current_time * 0.005) * 0.3);
    draw_text_ext_transformed(_w * 0.5, _h * 0.68, "Tap to restart", 0, 400, 2.0, 2.0, 0);
    draw_set_alpha(1.0);
}

// === LOADING ===
if (game_state == 0) {
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Loading...", 0, 400, 2.5, 2.5, 0);
}
