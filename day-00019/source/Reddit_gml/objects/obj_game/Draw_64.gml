
// === TINY TOWN Draw ===
var _w = window_get_width();
var _h = window_get_height();
window_width = _w;
window_height = _h;

if (_w < 10 || _h < 10) exit;

// Layout calculations
var _hud_h = _h * 0.12;
var _grid_area_h = _h - _hud_h - 8;
var _cs_w = floor((_w - 20) / grid_cols);
var _cs_h = floor(_grid_area_h / grid_rows);
cell_size = min(_cs_w, _cs_h);
// Clamp cell_size to reasonable range
if (cell_size < 20) cell_size = 20;
if (cell_size > 200) cell_size = 200;

var _gw = grid_cols * cell_size;
var _gh = grid_rows * cell_size;
grid_ox = (_w - _gw) * 0.5;
grid_oy = _hud_h + ((_h - _hud_h - _gh) * 0.5);

// Background
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(35, 40, 50));
draw_rectangle(0, 0, _w, _h, false);

// === DRAW GRID ===
for (var _r = 0; _r < grid_rows; _r++) {
    for (var _c = 0; _c < grid_cols; _c++) {
        var _x1 = grid_ox + _c * cell_size;
        var _y1 = grid_oy + _r * cell_size;
        var _x2 = _x1 + cell_size - 2;
        var _y2 = _y1 + cell_size - 2;
        var _i = _r * grid_cols + _c;
        var _type = grid_type[_i];

        // Combo zone flags
        var _cf = cell_combo_flags[_i];
        var _has_combo = (_cf != 0);

        // Compute blended combo border color from all active flags
        var _combo_cr = 0; var _combo_cg = 0; var _combo_cb = 0; var _cfcount = 0;
        if ((_cf & CFLAG_MARKET) != 0)  { _combo_cr += 255; _combo_cg += 180; _combo_cb += 50;  _cfcount++; }
        if ((_cf & CFLAG_PLAZA) != 0)   { _combo_cr += 230; _combo_cg += 100; _combo_cb += 255; _cfcount++; }
        if ((_cf & CFLAG_BIZ) != 0)     { _combo_cr += 100; _combo_cg += 200; _combo_cb += 255; _cfcount++; }
        if ((_cf & CFLAG_SUBURB) != 0)  { _combo_cr += 100; _combo_cg += 255; _combo_cb += 150; _cfcount++; }
        if ((_cf & CFLAG_RESERVE) != 0) { _combo_cr += 50;  _combo_cg += 220; _combo_cb += 100; _cfcount++; }
        if (_cfcount > 1) { _combo_cr = floor(_combo_cr / _cfcount); _combo_cg = floor(_combo_cg / _cfcount); _combo_cb = floor(_combo_cb / _cfcount); }
        _combo_cr = min(255, _combo_cr); _combo_cg = min(255, _combo_cg); _combo_cb = min(255, _combo_cb);

        // Cell background — tinted if in combo
        if (_type == EMPTY) {
            draw_set_colour(make_colour_rgb(55, 60, 70));
        } else if (_has_combo) {
            draw_set_colour(make_colour_rgb(
                30 + floor(_combo_cr * 0.15),
                30 + floor(_combo_cg * 0.15),
                30 + floor(_combo_cb * 0.15)));
        } else {
            draw_set_colour(make_colour_rgb(45, 50, 60));
        }
        draw_roundrect_ext(_x1, _y1, _x2, _y2, 4, 4, false);

        // Cell border — thick + colored if combo, normal otherwise
        if (_has_combo) {
            draw_set_colour(make_colour_rgb(_combo_cr, _combo_cg, _combo_cb));
            draw_roundrect_ext(_x1 - 1, _y1 - 1, _x2 + 1, _y2 + 1, 5, 5, true);
            draw_roundrect_ext(_x1, _y1, _x2, _y2, 4, 4, true);
        } else {
            draw_set_colour(make_colour_rgb(70, 75, 85));
            draw_roundrect_ext(_x1, _y1, _x2, _y2, 4, 4, true);
        }

        if (_type == EMPTY) {
            // Draw "+" hint
            draw_set_colour(make_colour_rgb(80, 85, 95));
            var _cx = (_x1 + _x2) * 0.5;
            var _cy = (_y1 + _y2) * 0.5;
            var _ps = cell_size * 0.15;
            draw_line_width(_cx - _ps, _cy, _cx + _ps, _cy, 2);
            draw_line_width(_cx, _cy - _ps, _cx, _cy + _ps, 2);
            continue;
        }

        // Draw building
        var _bx1 = _x1 + cell_size * 0.1;
        var _by1 = _y1 + cell_size * 0.15;
        var _bx2 = _x2 - cell_size * 0.1;
        var _by2 = _y2 - cell_size * 0.08;
        var _bcx = (_x1 + _x2) * 0.5;
        var _bcy = (_y1 + _y2) * 0.5;
        var _br = build_r[_type];
        var _bg = build_g[_type];
        var _bb = build_b[_type];

        // Event overlay - storm darkens, boom glows
        if (evt_type == EVENT_STORM && evt_target == _i) {
            _br = floor(_br * 0.3);
            _bg = floor(_bg * 0.3);
            _bb = floor(_bb * 0.3);
        }
        if (evt_type == EVENT_BOOM && evt_target == _i) {
            var _pulse = 0.5 + sin(evt_flash * 0.15) * 0.5;
            _br = min(255, _br + floor(100 * _pulse));
            _bg = min(255, _bg + floor(80 * _pulse));
            _bb = floor(_bb * 0.5);
        }

        draw_set_colour(make_colour_rgb(_br, _bg, _bb));

        if (_type == HOUSE) {
            // House: square base + triangle roof
            draw_roundrect_ext(_bx1, _bcy, _bx2, _by2, 3, 3, false);
            draw_triangle(_bx1, _bcy, _bx2, _bcy, _bcx, _by1, false);
            // Door
            draw_set_colour(make_colour_rgb(max(0, _br - 40), max(0, _bg - 40), max(0, _bb - 40)));
            var _dw = cell_size * 0.1;
            draw_rectangle(_bcx - _dw, _by2 - cell_size * 0.2, _bcx + _dw, _by2, false);
        } else if (_type == SHOP) {
            // Shop: wide rect + awning
            draw_roundrect_ext(_bx1, _bcy - cell_size * 0.05, _bx2, _by2, 3, 3, false);
            // Awning stripes
            draw_set_colour(make_colour_rgb(min(255, _br + 40), min(255, _bg + 20), _bb));
            draw_rectangle(_bx1, _bcy - cell_size * 0.1, _bx2, _bcy + cell_size * 0.05, false);
            // $ sign
            draw_set_colour(make_colour_rgb(255, 255, 255));
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var _font_scale = cell_size / 80;
            draw_text_ext_transformed(_bcx, _bcy + cell_size * 0.12, "$", 0, cell_size, _font_scale, _font_scale, 0);
        } else if (_type == PARK) {
            // Park: green ground + tree
            draw_set_colour(make_colour_rgb(50, 120, 50));
            draw_roundrect_ext(_bx1, _by2 - cell_size * 0.15, _bx2, _by2, 3, 3, false);
            // Tree trunk
            draw_set_colour(make_colour_rgb(139, 90, 43));
            var _tw = cell_size * 0.06;
            draw_rectangle(_bcx - _tw, _bcy, _bcx + _tw, _by2 - cell_size * 0.15, false);
            // Tree canopy
            draw_set_colour(make_colour_rgb(_br, _bg, _bb));
            var _tr = cell_size * 0.22;
            draw_circle(_bcx, _bcy - cell_size * 0.05, _tr, false);
        } else if (_type == TOWER) {
            // Tower: tall rect + spire
            var _tw2 = cell_size * 0.2;
            draw_roundrect_ext(_bcx - _tw2, _bcy - cell_size * 0.1, _bcx + _tw2, _by2, 2, 2, false);
            // Spire
            draw_triangle(_bcx - _tw2 - 2, _bcy - cell_size * 0.1,
                          _bcx + _tw2 + 2, _bcy - cell_size * 0.1,
                          _bcx, _by1 - cell_size * 0.05, false);
            // Windows
            draw_set_colour(make_colour_rgb(255, 255, 200));
            var _wsize = cell_size * 0.06;
            draw_rectangle(_bcx - _wsize, _bcy + cell_size * 0.05 - _wsize,
                          _bcx + _wsize, _bcy + cell_size * 0.05 + _wsize, false);
            draw_rectangle(_bcx - _wsize, _bcy + cell_size * 0.2 - _wsize,
                          _bcx + _wsize, _bcy + cell_size * 0.2 + _wsize, false);
        }

        // Draw level stars
        var _lvl = grid_level[_i];
        if (_lvl > 0) {
            draw_set_colour(make_colour_rgb(255, 220, 50));
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            var _star_str = "";
            for (var _s = 0; _s < _lvl; _s++) _star_str += "*";
            var _ss = cell_size / 100;
            draw_text_ext_transformed(_bcx, _y1 + 2, _star_str, 0, cell_size, _ss, _ss, 0);
        }

        // Combo zone labels — draw each zone name individually
        if (_has_combo) {
            var _cns = cell_size / 110;
            var _label_y = _y2 - 3;
            draw_set_halign(fa_center);
            draw_set_valign(fa_bottom);

            // Draw each active zone name, stacked from bottom
            if ((_cf & CFLAG_RESERVE) != 0) {
                draw_set_colour(make_colour_rgb(0, 0, 0));
                draw_text_transformed(_bcx + 1, _label_y + 1, "Reserve", _cns, _cns, 0);
                draw_set_colour(make_colour_rgb(50, 220, 100));
                draw_text_transformed(_bcx, _label_y, "Reserve", _cns, _cns, 0);
                _label_y -= 10 * _cns;
            }
            if ((_cf & CFLAG_SUBURB) != 0) {
                draw_set_colour(make_colour_rgb(0, 0, 0));
                draw_text_transformed(_bcx + 1, _label_y + 1, "Suburb", _cns, _cns, 0);
                draw_set_colour(make_colour_rgb(100, 255, 150));
                draw_text_transformed(_bcx, _label_y, "Suburb", _cns, _cns, 0);
                _label_y -= 10 * _cns;
            }
            if ((_cf & CFLAG_BIZ) != 0) {
                draw_set_colour(make_colour_rgb(0, 0, 0));
                draw_text_transformed(_bcx + 1, _label_y + 1, "Biz Dist", _cns, _cns, 0);
                draw_set_colour(make_colour_rgb(100, 200, 255));
                draw_text_transformed(_bcx, _label_y, "Biz Dist", _cns, _cns, 0);
                _label_y -= 10 * _cns;
            }
            if ((_cf & CFLAG_PLAZA) != 0) {
                draw_set_colour(make_colour_rgb(0, 0, 0));
                draw_text_transformed(_bcx + 1, _label_y + 1, "Plaza", _cns, _cns, 0);
                draw_set_colour(make_colour_rgb(230, 100, 255));
                draw_text_transformed(_bcx, _label_y, "Plaza", _cns, _cns, 0);
                _label_y -= 10 * _cns;
            }
            if ((_cf & CFLAG_MARKET) != 0) {
                draw_set_colour(make_colour_rgb(0, 0, 0));
                draw_text_transformed(_bcx + 1, _label_y + 1, "Market", _cns, _cns, 0);
                draw_set_colour(make_colour_rgb(255, 180, 50));
                draw_text_transformed(_bcx, _label_y, "Market", _cns, _cns, 0);
                _label_y -= 10 * _cns;
            }

            // Multiplier badge in top-right corner
            var _badge_r = cell_size * 0.1;
            draw_set_colour(make_colour_rgb(_combo_cr, _combo_cg, _combo_cb));
            draw_circle(_x2 - _badge_r - 1, _y1 + _badge_r + 1, _badge_r, false);
            draw_set_colour(make_colour_rgb(0, 0, 0));
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var _bs = cell_size / 100;
            draw_text_transformed(_x2 - _badge_r - 1, _y1 + _badge_r + 1, "x" + string(cell_combo[_i]), _bs, _bs, 0);
        }

        // Storm overlay effect
        if (evt_type == EVENT_STORM && evt_target == _i) {
            draw_set_alpha(0.3 + sin(evt_flash * 0.1) * 0.15);
            draw_set_colour(make_colour_rgb(100, 100, 120));
            draw_roundrect_ext(_x1, _y1, _x2, _y2, 4, 4, false);
            draw_set_alpha(1);
            // Rain lines
            draw_set_colour(make_colour_rgb(150, 170, 200));
            for (var _rl = 0; _rl < 4; _rl++) {
                var _rx = _x1 + random(cell_size);
                var _ry = _y1 + random(cell_size * 0.5);
                draw_line_width(_rx, _ry, _rx - 3, _ry + 8, 1);
            }
        }

        // Boom glow effect
        if (evt_type == EVENT_BOOM && evt_target == _i) {
            var _glow_a = 0.2 + sin(evt_flash * 0.15) * 0.15;
            draw_set_alpha(_glow_a);
            draw_set_colour(make_colour_rgb(255, 200, 0));
            draw_roundrect_ext(_x1 - 3, _y1 - 3, _x2 + 3, _y2 + 3, 6, 6, false);
            draw_set_alpha(1);
        }
    }
}

// === DRAW VISITORS ===
for (var _v = 0; _v < max_visitors; _v++) {
    if (!vis_active[_v]) continue;
    var _vr = cell_size * 0.06;
    if (_vr < 3) _vr = 3;
    if (vis_vip[_v]) {
        // VIP: gold with sparkle
        draw_set_colour(make_colour_rgb(255, 215, 0));
        draw_circle(vis_x[_v], vis_y[_v], _vr + 1, false);
        draw_set_colour(make_colour_rgb(255, 255, 200));
        draw_circle(vis_x[_v], vis_y[_v], _vr * 0.5, false);
    } else {
        draw_set_colour(make_colour_rgb(200, 220, 255));
        draw_circle(vis_x[_v], vis_y[_v], _vr, false);
    }
}

// === DRAW FLOAT TEXT ===
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var _f = 0; _f < max_floats; _f++) {
    if (ft_life[_f] <= 0) continue;
    var _fa = ft_life[_f] / 60;
    draw_set_alpha(_fa);
    draw_set_colour(make_colour_rgb(ft_r[_f], ft_g[_f], ft_b[_f]));
    var _fscale = cell_size / 80;
    draw_text_ext_transformed(ft_x[_f], ft_y[_f], ft_text[_f], 0, 200, _fscale, _fscale, 0);
}
draw_set_alpha(1);

// === DRAW HUD ===
// Top bar background
draw_set_colour(make_colour_rgb(25, 28, 38));
draw_rectangle(0, 0, _w, _hud_h, false);

var _hud_scale = _hud_h / 50;
var _pad = 12;

// Coins
draw_set_colour(make_colour_rgb(255, 210, 50));
draw_circle(_pad + 10 * _hud_scale, _hud_h * 0.35, 8 * _hud_scale, false);
draw_set_colour(make_colour_rgb(200, 160, 30));
draw_circle(_pad + 10 * _hud_scale, _hud_h * 0.35, 8 * _hud_scale, true);

draw_set_colour(make_colour_rgb(255, 255, 255));
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_text_ext_transformed(_pad + 22 * _hud_scale, _hud_h * 0.35, string(coins), 0, _w, _hud_scale * 0.9, _hud_scale * 0.9, 0);

// Score
draw_set_colour(make_colour_rgb(150, 200, 255));
draw_set_halign(fa_right);
draw_text_ext_transformed(_w - _pad, _hud_h * 0.25, "Score: " + string(points), 0, _w, _hud_scale * 0.6, _hud_scale * 0.6, 0);

// Star rating
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
var _star_display = "";
for (var _si = 0; _si < 5; _si++) {
    if (_si < star_rating) {
        _star_display += "*";
    } else {
        _star_display += ".";
    }
}
draw_set_colour(make_colour_rgb(255, 220, 50));
draw_text_ext_transformed(_w - _pad, _hud_h * 0.5, _star_display, 0, _w, _hud_scale * 0.7, _hud_scale * 0.7, 0);
// Combo count
if (combo_count > 0) {
    draw_set_colour(make_colour_rgb(200, 180, 100));
    draw_text_ext_transformed(_w - _pad - 50 * _hud_scale, _hud_h * 0.5, string(combo_count) + " combos", 0, _w, _hud_scale * 0.4, _hud_scale * 0.4, 0);
}

// Year and timer bar
var _bar_y = _hud_h * 0.7;
var _bar_h = _hud_h * 0.18;
var _bar_x = _pad;
var _bar_w = _w - _pad * 2;

// Year text
draw_set_colour(make_colour_rgb(200, 200, 200));
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_text_ext_transformed(_bar_x, _bar_y, "Year " + string(min(year, max_years)) + "/" + string(max_years), 0, _w, _hud_scale * 0.55, _hud_scale * 0.55, 0);

// Timer bar
var _timer_x = _bar_x + 80 * _hud_scale;
var _timer_w = _bar_w - 80 * _hud_scale;
draw_set_colour(make_colour_rgb(50, 55, 65));
draw_roundrect_ext(_timer_x, _bar_y - _bar_h * 0.5, _timer_x + _timer_w, _bar_y + _bar_h * 0.5, 3, 3, false);
var _prog = year_timer / year_duration;
if (_prog > 1) _prog = 1;
draw_set_colour(make_colour_rgb(80, 180, 120));
draw_roundrect_ext(_timer_x, _bar_y - _bar_h * 0.5, _timer_x + _timer_w * _prog, _bar_y + _bar_h * 0.5, 3, 3, false);

// Event banner
if (evt_type != EVENT_NONE && evt_text != "") {
    var _eb_y = _hud_h + 2;
    var _eb_h = _hud_h * 0.4;
    if (evt_type == EVENT_BOOM) {
        draw_set_colour(make_colour_rgb(80, 60, 0));
    } else if (evt_type == EVENT_STORM) {
        draw_set_colour(make_colour_rgb(40, 40, 60));
    } else {
        draw_set_colour(make_colour_rgb(60, 50, 10));
    }
    draw_set_alpha(0.85);
    draw_rectangle(0, _eb_y, _w, _eb_y + _eb_h, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    if (evt_type == EVENT_BOOM) {
        draw_set_colour(make_colour_rgb(255, 200, 50));
    } else if (evt_type == EVENT_STORM) {
        draw_set_colour(make_colour_rgb(150, 170, 220));
    } else {
        draw_set_colour(make_colour_rgb(255, 215, 0));
    }
    draw_text_ext_transformed(_w * 0.5, _eb_y + _eb_h * 0.5, evt_text, 0, _w, _hud_scale * 0.55, _hud_scale * 0.55, 0);
}

// === YEAR FLASH ===
if (year_flash > 0) {
    var _yf_a = year_flash / 90;
    draw_set_alpha(_yf_a * 0.7);
    draw_set_colour(make_colour_rgb(255, 255, 255));
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(min(1, _yf_a * 1.5));
    draw_set_colour(make_colour_rgb(50, 50, 80));
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _ys = _hud_scale * 3;
    draw_text_ext_transformed(_w * 0.5, _h * 0.4, "Year " + string(min(year, max_years)) + "!", 0, _w, _ys, _ys, 0);
    draw_set_alpha(1);
}

// === STAR MILESTONE FLASH ===
if (star_flash > 0) {
    var _sf_a = star_flash / 150;
    // Gold banner across middle
    draw_set_alpha(_sf_a * 0.85);
    draw_set_colour(make_colour_rgb(40, 30, 5));
    var _ban_h = _h * 0.12;
    draw_rectangle(0, _h * 0.38, _w, _h * 0.38 + _ban_h, false);
    draw_set_alpha(min(1, _sf_a * 1.5));
    draw_set_colour(make_colour_rgb(255, 220, 50));
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _sfs = _hud_scale * 1.5;
    draw_text_ext_transformed(_w * 0.5, _h * 0.38 + _ban_h * 0.5, star_flash_text, 0, _w, _sfs, _sfs, 0);
    // Sparkle particles
    draw_set_colour(make_colour_rgb(255, 255, 200));
    draw_set_alpha(_sf_a * 0.6);
    for (var _sp = 0; _sp < 6; _sp++) {
        var _spx = _w * 0.15 + (_w * 0.7) * (_sp / 5);
        var _spy = _h * 0.38 + _ban_h * 0.5 + sin(current_time * 0.008 + _sp) * _ban_h * 0.3;
        draw_circle(_spx, _spy, 2 + sin(current_time * 0.01 + _sp * 2) * 2, false);
    }
    draw_set_alpha(1);
}

// === DRAW BUILD MENU ===
if (menu_open && game_state == 1) {
    // Darken background
    draw_set_alpha(0.5);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);

    // Highlight selected cell
    var _sel_col = menu_cell mod grid_cols;
    var _sel_row = menu_cell div grid_cols;
    draw_set_colour(make_colour_rgb(255, 255, 100));
    draw_set_alpha(0.4);
    draw_roundrect_ext(grid_ox + _sel_col * cell_size - 2, grid_oy + _sel_row * cell_size - 2,
                       grid_ox + (_sel_col + 1) * cell_size, grid_oy + (_sel_row + 1) * cell_size, 4, 4, false);
    draw_set_alpha(1);

    var _menu_w = min(_w * 0.85, cell_size * 4.5);
    var _menu_h = min(_h * 0.55, cell_size * 3.5);
    var _menu_x = (_w - _menu_w) * 0.5;
    var _menu_y = (_h - _menu_h) * 0.5;

    // Panel background
    draw_set_colour(make_colour_rgb(40, 44, 58));
    draw_roundrect_ext(_menu_x, _menu_y, _menu_x + _menu_w, _menu_y + _menu_h, 8, 8, false);
    draw_set_colour(make_colour_rgb(80, 90, 110));
    draw_roundrect_ext(_menu_x, _menu_y, _menu_x + _menu_w, _menu_y + _menu_h, 8, 8, true);

    var _ms = _hud_scale * 0.7;

    if (menu_mode == 0) {
        // BUILD MENU
        draw_set_colour(make_colour_rgb(255, 255, 255));
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_text_ext_transformed(_w * 0.5, _menu_y + 8, "BUILD", 0, _menu_w, _ms * 1.2, _ms * 1.2, 0);

        var _btn_h = _menu_h * 0.17;
        var _btn_margin = 4;
        var _btn_y_start = _menu_y + _menu_h * 0.25;

        for (var _b = 1; _b <= 4; _b++) {
            var _by = _btn_y_start + (_b - 1) * (_btn_h + _btn_margin);
            var _cost = build_cost[_b];
            _cost = round(_cost * (1 + (year - 1) * 0.2));
            var _locked = (_b == TOWER && stars_reached < 2);
            var _can_afford = (coins >= _cost);

            // Button background
            if (_locked) {
                draw_set_colour(make_colour_rgb(35, 35, 40));
            } else if (_can_afford) {
                draw_set_colour(make_colour_rgb(50, 60, 75));
            } else {
                draw_set_colour(make_colour_rgb(45, 40, 40));
            }
            draw_roundrect_ext(_menu_x + 8, _by, _menu_x + _menu_w - 8, _by + _btn_h, 4, 4, false);

            // Building color indicator
            if (!_locked) {
                draw_set_colour(make_colour_rgb(build_r[_b], build_g[_b], build_b[_b]));
            } else {
                draw_set_colour(make_colour_rgb(60, 60, 60));
            }
            draw_roundrect_ext(_menu_x + 14, _by + 4, _menu_x + 14 + _btn_h - 8, _by + _btn_h - 4, 3, 3, false);

            // Name
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            if (_locked) {
                draw_set_colour(make_colour_rgb(100, 100, 100));
                draw_text_ext_transformed(_menu_x + 20 + _btn_h, _by + _btn_h * 0.5, build_names[_b] + " (2*)", 0, _menu_w, _ms * 0.8, _ms * 0.8, 0);
            } else {
                draw_set_colour(_can_afford ? make_colour_rgb(230, 230, 230) : make_colour_rgb(180, 100, 100));
                draw_text_ext_transformed(_menu_x + 20 + _btn_h, _by + _btn_h * 0.5, build_names[_b], 0, _menu_w, _ms * 0.8, _ms * 0.8, 0);
            }

            // Cost
            draw_set_halign(fa_right);
            if (_can_afford && !_locked) {
                draw_set_colour(make_colour_rgb(255, 210, 50));
            } else {
                draw_set_colour(make_colour_rgb(120, 120, 120));
            }
            draw_text_ext_transformed(_menu_x + _menu_w - 16, _by + _btn_h * 0.5, string(_cost) + "c", 0, _menu_w, _ms * 0.7, _ms * 0.7, 0);

            // Income info
            if (_b != PARK && !_locked) {
                draw_set_colour(make_colour_rgb(100, 200, 100));
                draw_set_halign(fa_right);
                draw_text_ext_transformed(_menu_x + _menu_w - 16, _by + _btn_h * 0.85, "+" + string(build_income[_b]) + "/tick", 0, _menu_w, _ms * 0.45, _ms * 0.45, 0);
            } else if (_b == PARK && !_locked) {
                draw_set_colour(make_colour_rgb(100, 200, 100));
                draw_set_halign(fa_right);
                draw_text_ext_transformed(_menu_x + _menu_w - 16, _by + _btn_h * 0.85, "boost adj.", 0, _menu_w, _ms * 0.45, _ms * 0.45, 0);
            }
        }
    } else {
        // UPGRADE MENU
        var _type2 = grid_type[menu_cell];
        var _lvl2 = grid_level[menu_cell];

        draw_set_colour(make_colour_rgb(build_r[_type2], build_g[_type2], build_b[_type2]));
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_text_ext_transformed(_w * 0.5, _menu_y + 8, build_names[_type2], 0, _menu_w, _ms * 1.2, _ms * 1.2, 0);

        // Level info
        draw_set_colour(make_colour_rgb(255, 220, 50));
        draw_text_ext_transformed(_w * 0.5, _menu_y + _menu_h * 0.2, "Level " + string(_lvl2) + "/3", 0, _menu_w, _ms * 0.8, _ms * 0.8, 0);

        // Current income
        var _cur_income = build_income[_type2] * (1 + _lvl2 * 0.5);
        draw_set_colour(make_colour_rgb(100, 200, 100));
        if (_type2 != PARK) {
            draw_text_ext_transformed(_w * 0.5, _menu_y + _menu_h * 0.32, "Income: " + string(round(_cur_income)) + "/tick", 0, _menu_w, _ms * 0.7, _ms * 0.7, 0);
        } else {
            draw_text_ext_transformed(_w * 0.5, _menu_y + _menu_h * 0.32, "Boost: +" + string(1 + _lvl2) + " to neighbors", 0, _menu_w, _ms * 0.7, _ms * 0.7, 0);
        }
        // Show combo status — all zones
        var _mcf = cell_combo_flags[menu_cell];
        if (_mcf != 0) {
            var _mc_label = "";
            if ((_mcf & CFLAG_MARKET) != 0)  { if (_mc_label != "") _mc_label += " + "; _mc_label += "Market"; }
            if ((_mcf & CFLAG_PLAZA) != 0)   { if (_mc_label != "") _mc_label += " + "; _mc_label += "Plaza"; }
            if ((_mcf & CFLAG_BIZ) != 0)     { if (_mc_label != "") _mc_label += " + "; _mc_label += "Biz Dist"; }
            if ((_mcf & CFLAG_SUBURB) != 0)  { if (_mc_label != "") _mc_label += " + "; _mc_label += "Suburb"; }
            if ((_mcf & CFLAG_RESERVE) != 0) { if (_mc_label != "") _mc_label += " + "; _mc_label += "Reserve"; }
            draw_set_colour(make_colour_rgb(255, 200, 80));
            draw_text_ext_transformed(_w * 0.5, _menu_y + _menu_h * 0.45, _mc_label + " x" + string(cell_combo[menu_cell]), 0, _menu_w, _ms * 0.55, _ms * 0.55, 0);
        } else {
            draw_set_colour(make_colour_rgb(120, 120, 120));
            draw_text_ext_transformed(_w * 0.5, _menu_y + _menu_h * 0.45, "No combo", 0, _menu_w, _ms * 0.5, _ms * 0.5, 0);
        }

        // Upgrade button
        var _btn_w = _menu_w * 0.6;
        var _btn_h2 = _menu_h * 0.22;
        var _btn_x = _menu_x + (_menu_w - _btn_w) * 0.5;
        var _btn_y2 = _menu_y + _menu_h * 0.55;

        if (_lvl2 < 3) {
            var _ucost = round(build_cost[_type2] * power(2, _lvl2 + 1) * (1 + (year - 1) * 0.2));
            var _can_aff = (coins >= _ucost);

            if (_can_aff) {
                draw_set_colour(make_colour_rgb(60, 120, 80));
            } else {
                draw_set_colour(make_colour_rgb(80, 50, 50));
            }
            draw_roundrect_ext(_btn_x, _btn_y2, _btn_x + _btn_w, _btn_y2 + _btn_h2, 6, 6, false);

            draw_set_colour(_can_aff ? make_colour_rgb(255, 255, 255) : make_colour_rgb(150, 100, 100));
            draw_set_valign(fa_middle);
            draw_text_ext_transformed(_w * 0.5, _btn_y2 + _btn_h2 * 0.5, "Upgrade: " + string(_ucost) + "c", 0, _btn_w, _ms * 0.75, _ms * 0.75, 0);
        } else {
            draw_set_colour(make_colour_rgb(50, 55, 65));
            draw_roundrect_ext(_btn_x, _btn_y2, _btn_x + _btn_w, _btn_y2 + _btn_h2, 6, 6, false);
            draw_set_colour(make_colour_rgb(150, 150, 150));
            draw_set_valign(fa_middle);
            draw_text_ext_transformed(_w * 0.5, _btn_y2 + _btn_h2 * 0.5, "MAX LEVEL", 0, _btn_w, _ms * 0.75, _ms * 0.75, 0);
        }

        // Demolish button
        var _dem_y = _btn_y2 + _btn_h2 + 8;
        var _dem_w = _btn_w * 0.5;
        var _dem_x = _menu_x + (_menu_w - _dem_w) * 0.5;
        var _dem_h = _btn_h2 * 0.7;
        draw_set_colour(make_colour_rgb(120, 40, 40));
        draw_roundrect_ext(_dem_x, _dem_y, _dem_x + _dem_w, _dem_y + _dem_h, 4, 4, false);
        draw_set_colour(make_colour_rgb(220, 150, 150));
        draw_text_ext_transformed(_w * 0.5, _dem_y + _dem_h * 0.5, "Demolish", 0, _dem_w, _ms * 0.55, _ms * 0.55, 0);
    }
}

// === GAME OVER SCREEN ===
if (game_state == 2) {
    draw_set_alpha(0.75);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Title
    var _go_s = _hud_scale * 2.5;
    draw_set_colour(make_colour_rgb(255, 220, 80));
    draw_text_ext_transformed(_w * 0.5, _h * 0.3, "TINY TOWN", 0, _w, _go_s, _go_s, 0);

    draw_set_colour(make_colour_rgb(200, 200, 200));
    draw_text_ext_transformed(_w * 0.5, _h * 0.42, "5 Years Complete!", 0, _w, _go_s * 0.5, _go_s * 0.5, 0);

    // Final score
    draw_set_colour(make_colour_rgb(255, 255, 255));
    draw_text_ext_transformed(_w * 0.5, _h * 0.55, "Final Score: " + string(points), 0, _w, _go_s * 0.7, _go_s * 0.7, 0);

    // Buildings placed
    var _bcount = 0;
    for (var _bi = 0; _bi < grid_total; _bi++) {
        if (grid_type[_bi] != EMPTY) _bcount++;
    }
    draw_set_colour(make_colour_rgb(180, 180, 200));
    draw_text_ext_transformed(_w * 0.5, _h * 0.63, string(_bcount) + " buildings | " + string(combo_count) + " combos", 0, _w, _go_s * 0.4, _go_s * 0.4, 0);

    // Star rating display
    var _go_stars = "";
    for (var _gsi = 0; _gsi < 5; _gsi++) {
        if (_gsi < stars_reached) _go_stars += "*"; else _go_stars += ".";
    }
    draw_set_colour(make_colour_rgb(255, 220, 50));
    draw_text_ext_transformed(_w * 0.5, _h * 0.71, _go_stars, 0, _w, _go_s * 0.6, _go_s * 0.6, 0);

    // Tap to restart
    var _blink = 0.5 + sin(current_time * 0.005) * 0.5;
    draw_set_alpha(_blink);
    draw_set_colour(make_colour_rgb(200, 200, 200));
    draw_text_ext_transformed(_w * 0.5, _h * 0.78, "Tap to play again", 0, _w, _go_s * 0.4, _go_s * 0.4, 0);
    draw_set_alpha(1);

    // Handle restart tap
    if (device_mouse_check_button_pressed(0, mb_left)) {
        // Reset everything
        for (var _ri = 0; _ri < grid_total; _ri++) {
            grid_type[_ri] = EMPTY;
            grid_level[_ri] = 0;
        }
        coins = 50;
        points = 0;
        total_earned = 0;
        year = 1;
        year_timer = 0;
        income_timer = 0;
        evt_timer = 0;
        evt_type = EVENT_NONE;
        evt_target = -1;
        evt_text = "";
        visitor_spawn_timer = 0;
        for (var _vi = 0; _vi < max_visitors; _vi++) vis_active[_vi] = false;
        for (var _fi = 0; _fi < max_floats; _fi++) ft_life[_fi] = 0;
        for (var _ci = 0; _ci < grid_total; _ci++) { cell_combo[_ci] = 1.0; cell_combo_flags[_ci] = 0; }
        combo_count = 0;
        star_rating = 0;
        stars_reached = 0;
        star_income_mult = 1.0;
        star_flash = 0;
        menu_open = false;
        game_state = 1;
    }
}

// === LOADING STATE ===
if (game_state == 0) {
    draw_set_colour(make_colour_rgb(255, 255, 255));
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _ls = _hud_scale * 1.2;
    draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Loading...", 0, _w, _ls, _ls, 0);
}
