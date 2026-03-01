
var _w = window_get_width();
var _h = window_get_height();
if (_w < 1 || _h < 1) exit;

draw_set_colour(c_black);
draw_rectangle(0, 0, _w, _h, false);

if (game_state == 0) {
	draw_set_colour(c_yellow);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);
	draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Generating Maze...", 0, _w, 2, 2, 0);
	exit;
}

var _cs = cell_size;
var _ox = maze_offset_x;
var _oy = maze_offset_y;

// ============================================================
// MAZE
// ============================================================
for (var _my = 0; _my < MAZE_H; _my++) {
	for (var _mx = 0; _mx < MAZE_W; _mx++) {
		var _idx = _my * MAZE_W + _mx;
		var _px = _ox + _mx * _cs;
		var _py = _oy + _my * _cs;

		if (maze[_idx] == 0) {
			draw_set_colour(make_colour_rgb(25, 25, 90));
			draw_roundrect(_px + 1, _py + 1, _px + _cs - 1, _py + _cs - 1, false);
			draw_set_colour(make_colour_rgb(50, 50, 180));
			draw_roundrect(_px + 1, _py + 1, _px + _cs - 1, _py + _cs - 1, true);
		} else {
			var _dot = dots[_idx];
			var _cx = _px + _cs * 0.5;
			var _cy = _py + _cs * 0.5;

			if (_dot == 1) {
				draw_set_colour(c_white);
				draw_circle(_cx, _cy, max(1, _cs * 0.1), false);
			} else if (_dot == 2) {
				draw_set_colour(c_white);
				var _pulse = 0.2 + sin(current_time * 0.005) * 0.08;
				draw_circle(_cx, _cy, max(2, _cs * _pulse), false);
			} else if (_dot == 3) {
				draw_set_colour(c_yellow);
				draw_circle(_cx, _cy, max(2, _cs * 0.18), false);
			} else if (_dot == 4) {
				draw_set_colour(make_colour_rgb(100, 200, 255));
				draw_circle(_cx, _cy, max(2, _cs * 0.18), false);
			}
		}
	}
}

// ============================================================
// GHOST SPAWN AREA
// ============================================================
var _pen_cx = (MAZE_W div 2) + 0.5;
var _pen_cy = 1.5;
var _pen_px = _ox + _pen_cx * _cs;
var _pen_py = _oy + _pen_cy * _cs;
var _pen_rw = _cs * 1.6;
var _pen_rh = _cs * 1.1;
var _pen_pulse = 0.4 + sin(current_time * 0.003) * 0.15;
draw_set_alpha(_pen_pulse);
draw_set_colour(make_colour_rgb(30, 10, 50));
draw_roundrect(_pen_px - _pen_rw, _pen_py - _pen_rh, _pen_px + _pen_rw, _pen_py + _pen_rh, false);
draw_set_alpha(0.5 + sin(current_time * 0.005) * 0.3);
draw_set_colour(make_colour_rgb(80, 40, 140));
draw_roundrect(_pen_px - _pen_rw, _pen_py - _pen_rh, _pen_px + _pen_rw, _pen_py + _pen_rh, true);
// Orbiting particles inside pen
for (var _pi = 0; _pi < 4; _pi++) {
	var _pa = current_time * 0.002 + _pi * 1.57;
	var _pdx = cos(_pa) * _pen_rw * 0.5;
	var _pdy = sin(_pa) * _pen_rh * 0.4;
	draw_set_colour(make_colour_rgb(120, 60, 200));
	draw_set_alpha(0.4 + sin(current_time * 0.008 + _pi) * 0.3);
	draw_circle(_pen_px + _pdx, _pen_py + _pdy, max(1, _cs * 0.06), false);
}
draw_set_alpha(1.0);

// ============================================================
// SLIMES (GHOSTS)
// ============================================================
for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
	if (!ghost_active[_gi]) continue;

	// Spawn animation: forming slime at pen
	if (ghost_spawn_timer[_gi] > 0) {
		var _init_timer = _gi * 120;
		if (_init_timer <= 0) continue;
		var _sp_ratio = 1.0 - (ghost_spawn_timer[_gi] / _init_timer);
		if (_sp_ratio <= 0) continue;
		var _sp_px = _ox + ((MAZE_W div 2) + 0.5) * _cs;
		var _sp_py = _oy + 1.5 * _cs;
		var _sp_r = _cs * 0.4 * _sp_ratio;
		draw_set_alpha(0.3 + _sp_ratio * 0.7);
		draw_set_colour(ghost_colors[ghost_type[_gi]]);
		draw_circle(_sp_px, _sp_py, _sp_r, false);
		draw_set_colour(merge_colour(ghost_colors[ghost_type[_gi]], c_white, 0.3));
		draw_circle(_sp_px - _sp_r * 0.3, _sp_py - _sp_r * 0.3, _sp_r * 0.25, false);
		draw_set_alpha(1.0);
		continue;
	}

	// Position from tile-to-tile model
	var _gfx = ghost_gx[_gi] + dir_dx[ghost_dir[_gi]] * ghost_progress[_gi] + 0.5;
	var _gfy = ghost_gy[_gi] + dir_dy[ghost_dir[_gi]] * ghost_progress[_gi] + 0.5;
	var _gpx = _ox + _gfx * _cs;
	var _gpy = _oy + _gfy * _cs;
	var _gr = _cs * 0.4;

	// --- EATEN STATE: eyes only ---
	if (ghost_state[_gi] == 3) {
		draw_set_alpha(0.7);
		var _eox = dir_dx[ghost_dir[_gi]] * _gr * 0.1;
		var _eoy = dir_dy[ghost_dir[_gi]] * _gr * 0.1;
		draw_set_colour(c_white);
		draw_circle(_gpx - _gr * 0.3, _gpy - _gr * 0.15, _gr * 0.22, false);
		draw_circle(_gpx + _gr * 0.3, _gpy - _gr * 0.15, _gr * 0.22, false);
		draw_set_colour(make_colour_rgb(20, 20, 60));
		draw_circle(_gpx - _gr * 0.3 + _eox, _gpy - _gr * 0.15 + _eoy, _gr * 0.11, false);
		draw_circle(_gpx + _gr * 0.3 + _eox, _gpy - _gr * 0.15 + _eoy, _gr * 0.11, false);
		draw_set_alpha(1.0);
		continue;
	}

	// --- FRIGHTENED STATE ---
	if (ghost_state[_gi] == 2) {
		var _flash = (fright_timer < 90 && (fright_timer div 10) mod 2 == 0);
		var _body_col = _flash ? c_white : make_colour_rgb(33, 33, 222);

		// Blob body
		draw_set_colour(_body_col);
		draw_circle(_gpx, _gpy, _gr, false);
		draw_rectangle(_gpx - _gr, _gpy, _gpx + _gr, _gpy + _gr * 0.5, false);

		// Drips
		for (var _di = 0; _di < 3; _di++) {
			var _ddx = _gpx - _gr * 0.6 + _di * _gr * 0.6;
			var _ddy = _gpy + _gr * 0.5 + sin(current_time * 0.008 + _di * 2) * _gr * 0.15;
			draw_circle(_ddx, _ddy, _gr * 0.15, false);
		}

		// Scared eyes (small dots)
		draw_set_colour(_flash ? make_colour_rgb(33, 33, 222) : c_white);
		draw_circle(_gpx - _gr * 0.25, _gpy - _gr * 0.15, _gr * 0.08, false);
		draw_circle(_gpx + _gr * 0.25, _gpy - _gr * 0.15, _gr * 0.08, false);

		// Zigzag mouth
		var _mmy = _gpy + _gr * 0.25;
		for (var _mi = -2; _mi <= 2; _mi++) {
			draw_circle(_gpx + _mi * _gr * 0.18, _mmy + ((_mi mod 2 == 0) ? -_gr * 0.04 : _gr * 0.04), _gr * 0.05, false);
		}
		continue;
	}

	// --- NORMAL STATE: Slime blob ---
	draw_set_colour(ghost_colors[ghost_type[_gi]]);

	// Main blob body (squished circle + rect for rounded-bottom shape)
	var _bob = sin(current_time * 0.006 + _gi * 1.5) * _gr * 0.08;
	draw_circle(_gpx, _gpy - _gr * 0.1 + _bob, _gr, false);
	draw_rectangle(_gpx - _gr, _gpy - _gr * 0.1 + _bob, _gpx + _gr, _gpy + _gr * 0.45 + _bob, false);

	// Highlight/sheen
	draw_set_colour(merge_colour(ghost_colors[ghost_type[_gi]], c_white, 0.35));
	draw_circle(_gpx - _gr * 0.25, _gpy - _gr * 0.35 + _bob, _gr * 0.25, false);

	// Drip circles hanging off bottom
	draw_set_colour(ghost_colors[ghost_type[_gi]]);
	for (var _di = 0; _di < 3; _di++) {
		var _ddx = _gpx - _gr * 0.6 + _di * _gr * 0.6;
		var _ddy = _gpy + _gr * 0.45 + _bob + sin(current_time * 0.008 + _di * 2 + _gi) * _gr * 0.15;
		draw_circle(_ddx, _ddy, _gr * 0.18, false);
	}

	// Eyes: large white with dark pupils looking in ghost_dir
	draw_set_colour(c_white);
	draw_circle(_gpx - _gr * 0.3, _gpy - _gr * 0.15 + _bob, _gr * 0.25, false);
	draw_circle(_gpx + _gr * 0.3, _gpy - _gr * 0.15 + _bob, _gr * 0.25, false);
	draw_set_colour(make_colour_rgb(20, 20, 60));
	var _eox = dir_dx[ghost_dir[_gi]] * _gr * 0.1;
	var _eoy = dir_dy[ghost_dir[_gi]] * _gr * 0.1;
	draw_circle(_gpx - _gr * 0.3 + _eox, _gpy - _gr * 0.15 + _eoy + _bob, _gr * 0.12, false);
	draw_circle(_gpx + _gr * 0.3 + _eox, _gpy - _gr * 0.15 + _eoy + _bob, _gr * 0.12, false);
}

// ============================================================
// KNIGHT (PLAYER)
// ============================================================
if (game_state != 5 || game_over_timer > 120) {
	var _pfx = pac_gx + dir_dx[pac_dir] * pac_progress + 0.5;
	var _pfy = pac_gy + dir_dy[pac_dir] * pac_progress + 0.5;
	var _ppx = _ox + _pfx * _cs;
	var _ppy = _oy + _pfy * _cs;
	var _pr = _cs * 0.42;

	// Bob when moving
	var _kbob = 0;
	if (pac_moving) _kbob = sin(current_time * 0.008) * _pr * 0.12;

	var _draw_pac = true;
	if (invincible_timer > 0 && (invincible_timer div 5) mod 2 == 0) _draw_pac = false;

	if (_draw_pac) {
		// Armor body (silver roundrect)
		draw_set_colour(make_colour_rgb(180, 190, 200));
		draw_roundrect(_ppx - _pr * 0.6, _ppy - _pr * 0.3 + _kbob, _ppx + _pr * 0.6, _ppy + _pr * 0.7 + _kbob, false);
		// Body highlight
		draw_set_colour(make_colour_rgb(210, 220, 230));
		draw_roundrect(_ppx - _pr * 0.35, _ppy - _pr * 0.2 + _kbob, _ppx + _pr * 0.1, _ppy + _pr * 0.3 + _kbob, false);

		// Helmet (dark gray circle on top)
		draw_set_colour(make_colour_rgb(100, 105, 115));
		draw_circle(_ppx, _ppy - _pr * 0.45 + _kbob, _pr * 0.5, false);
		// Helmet highlight
		draw_set_colour(make_colour_rgb(140, 148, 160));
		draw_circle(_ppx - _pr * 0.15, _ppy - _pr * 0.6 + _kbob, _pr * 0.18, false);
		// Visor slit
		draw_set_colour(make_colour_rgb(30, 30, 40));
		draw_rectangle(_ppx - _pr * 0.35, _ppy - _pr * 0.45 + _kbob, _ppx + _pr * 0.35, _ppy - _pr * 0.35 + _kbob, false);
		// Eyes in visor
		draw_set_colour(make_colour_rgb(180, 220, 255));
		draw_circle(_ppx - _pr * 0.15, _ppy - _pr * 0.4 + _kbob, max(1, _pr * 0.06), false);
		draw_circle(_ppx + _pr * 0.15, _ppy - _pr * 0.4 + _kbob, max(1, _pr * 0.06), false);

		// Sword extending in pac_dir
		var _sdx = dir_dx[pac_dir];
		var _sdy = dir_dy[pac_dir];
		var _sword_ox = _ppx + _sdx * _pr * 0.6;
		var _sword_oy = _ppy + _sdy * _pr * 0.6 + _kbob;
		var _sword_ex = _ppx + _sdx * _pr * 1.5;
		var _sword_ey = _ppy + _sdy * _pr * 1.5 + _kbob;
		// Blade
		draw_set_colour(make_colour_rgb(220, 225, 235));
		draw_line_width(_sword_ox, _sword_oy, _sword_ex, _sword_ey, max(1, _pr * 0.1));
		// Crossguard
		draw_set_colour(make_colour_rgb(200, 170, 50));
		var _cgx = _ppx + _sdx * _pr * 0.65;
		var _cgy = _ppy + _sdy * _pr * 0.65 + _kbob;
		if (_sdx != 0) {
			draw_rectangle(_cgx - _pr * 0.05, _cgy - _pr * 0.2, _cgx + _pr * 0.05, _cgy + _pr * 0.2, false);
		} else {
			draw_rectangle(_cgx - _pr * 0.2, _cgy - _pr * 0.05, _cgx + _pr * 0.2, _cgy + _pr * 0.05, false);
		}
	}
}

// ============================================================
// HUD
// ============================================================
draw_set_font(fnt_default);
draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_colour(c_white);
var _hs = max(1.2, min(_w, _h) / 400);
draw_text_ext_transformed(10, 8, string(points), 0, _w, _hs, _hs, 0);

draw_set_halign(fa_center);
draw_set_colour(make_colour_rgb(200, 170, 50));
draw_text_ext_transformed(_w * 0.5, 8, "Round " + string(round_num), 0, _w, _hs * 0.8, _hs * 0.8, 0);

draw_set_halign(fa_right);
for (var _li = 0; _li < lives; _li++) {
	var _lx = _w - 15 - _li * (_hs * 14);
	// Knight helmet icon
	draw_set_colour(make_colour_rgb(100, 105, 115));
	draw_circle(_lx, 13, max(2, _hs * 5), false);
	// Visor slit
	draw_set_colour(make_colour_rgb(30, 30, 40));
	draw_rectangle(_lx - _hs * 3, 13 - _hs * 0.5, _lx + _hs * 3, 13 + _hs * 0.5, false);
}

// Power-up bars
var _ty = 30;
draw_set_halign(fa_center);
if (fright_timer > 0) {
	draw_set_colour(make_colour_rgb(33, 33, 222));
	var _bw = (_w * 0.3) * (fright_timer / max(1, fright_duration_base + fright_duration_bonus));
	draw_rectangle(_w * 0.5 - _bw * 0.5, _ty, _w * 0.5 + _bw * 0.5, _ty + 4, false);
}
if (speed_boost_timer > 0) {
	draw_set_colour(c_yellow);
	var _bw2 = (_w * 0.3) * (speed_boost_timer / 240);
	draw_rectangle(_w * 0.5 - _bw2 * 0.5, _ty + 6, _w * 0.5 + _bw2 * 0.5, _ty + 10, false);
}
if (freeze_timer > 0) {
	draw_set_colour(make_colour_rgb(100, 200, 255));
	var _bw3 = (_w * 0.3) * (freeze_timer / 180);
	draw_rectangle(_w * 0.5 - _bw3 * 0.5, _ty + 12, _w * 0.5 + _bw3 * 0.5, _ty + 16, false);
}
// Dot progress bar (75% threshold)
if (game_state == 1 && total_dots > 0) {
	var _req = floor(total_dots * 0.75);
	var _prog = min(dots_eaten / _req, 1.0);
	var _bar_full = _w * 0.3;
	var _bar_x = _w * 0.5 - _bar_full * 0.5;
	var _bar_y = _ty + 20;
	draw_set_colour(make_colour_rgb(60, 60, 60));
	draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_full, _bar_y + 4, false);
	draw_set_colour(make_colour_rgb(50, 200, 50));
	if (_prog > 0) draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_full * _prog, _bar_y + 4, false);
	draw_set_colour(make_colour_rgb(180, 180, 180));
	draw_set_halign(fa_center); draw_set_valign(fa_top);
	draw_text_ext_transformed(_w * 0.5, _bar_y + 6, string(dots_eaten) + "/" + string(_req), 0, _w, max(0.7, _hs * 0.45), max(0.7, _hs * 0.45), 0);
}

if (game_state == 1 && !pac_moving && pac_progress == 0 && dots_eaten == 0) {
	draw_set_colour(make_colour_rgb(200, 200, 200));
	draw_set_halign(fa_center); draw_set_valign(fa_bottom);
	draw_text_ext_transformed(_w * 0.5, _h - 10, "Swipe to move", 0, _w, _hs * 0.7, _hs * 0.7, 0);
}

// ============================================================
// OVERLAYS
// ============================================================
if (game_state == 2) {
	draw_set_alpha(0.5); draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false); draw_set_alpha(1.0);
	draw_set_colour(c_red); draw_set_halign(fa_center); draw_set_valign(fa_middle);
	draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Ouch!", 0, _w, 3, 3, 0);
}

if (game_state == 3) {
	if ((round_clear_timer div 8) mod 2 == 0) {
		draw_set_alpha(0.3); draw_set_colour(c_white);
		draw_rectangle(0, 0, _w, _h, false); draw_set_alpha(1.0);
	}
	draw_set_colour(c_yellow); draw_set_halign(fa_center); draw_set_valign(fa_middle);
	draw_text_ext_transformed(_w * 0.5, _h * 0.45, "Round Clear!", 0, _w, 3, 3, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.55, "+" + string(500 * round_num) + " bonus", 0, _w, 2, 2, 0);
}

if (game_state == 4) {
	draw_set_alpha(0.85); draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false); draw_set_alpha(1.0);

	draw_set_colour(c_yellow); draw_set_halign(fa_center); draw_set_valign(fa_middle);
	var _ts = max(1.5, _hs * 1.2);
	draw_text_ext_transformed(_w * 0.5, _h * 0.25, "Choose Upgrade", 0, _w, _ts, _ts, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.35, "Round " + string(round_num - 1) + " Complete!", 0, _w, _ts * 0.6, _ts * 0.6, 0);

	var _unames = ["Speed+", "Longer Fright", "Ghost Slow", "Magnet", "Extra Life", "Wall Phase"];
	var _udescs = ["+10% move speed", "+2s power pellets", "Ghosts 10% slower", "Collect nearby dots", "+1 life", "+1 wall pass/round"];
	var _ucols = [c_yellow, make_colour_rgb(33, 33, 222), make_colour_rgb(100, 200, 255), make_colour_rgb(255, 100, 255), c_green, make_colour_rgb(200, 200, 200)];
	var _bw = _w * 0.35; var _bh = _h * 0.18; var _gap = _w * 0.05;
	var _tw = _bw * 2 + _gap; var _sbx = (_w - _tw) * 0.5; var _by = _h * 0.5;

	for (var _ui = 0; _ui < 2; _ui++) {
		var _bx = _sbx + _ui * (_bw + _gap);
		var _upg = upgrade_choices[_ui];
		draw_set_colour(make_colour_rgb(40, 40, 80));
		draw_roundrect(_bx, _by, _bx + _bw, _by + _bh, false);
		draw_set_colour(_ucols[_upg]);
		draw_roundrect(_bx, _by, _bx + _bw, _by + _bh, true);
		var _ns = max(1.0, _hs * 0.7);
		draw_text_ext_transformed(_bx + _bw * 0.5, _by + _bh * 0.35, _unames[_upg], 0, _bw - 10, _ns, _ns, 0);
		draw_set_colour(make_colour_rgb(180, 180, 180));
		draw_text_ext_transformed(_bx + _bw * 0.5, _by + _bh * 0.7, _udescs[_upg], 0, _bw - 10, max(0.8, _hs * 0.5), max(0.8, _hs * 0.5), 0);
	}
}

if (game_state == 5) {
	draw_set_alpha(0.7); draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false); draw_set_alpha(1.0);
	draw_set_halign(fa_center); draw_set_valign(fa_middle);
	draw_set_colour(c_red);
	draw_text_ext_transformed(_w * 0.5, _h * 0.35, "GAME OVER", 0, _w, 3, 3, 0);
	draw_set_colour(c_yellow);
	draw_text_ext_transformed(_w * 0.5, _h * 0.48, "Score: " + string(points), 0, _w, 2.5, 2.5, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.58, "Round " + string(round_num), 0, _w, 2, 2, 0);
	if (game_over_timer <= 0) {
		draw_set_colour(make_colour_rgb(180, 180, 180));
		draw_text_ext_transformed(_w * 0.5, _h * 0.72, "Tap to Restart", 0, _w, 1.5, 1.5, 0);
	}
}
