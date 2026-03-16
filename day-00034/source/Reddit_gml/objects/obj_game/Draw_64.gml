
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

draw_set_font(fnt_default);

// === GRID LAYOUT ===
var _margin = 10;
var _top_bar = 70;
var _bot_bar = 100;
var _grid_area_w = _w - _margin * 2;
var _grid_area_h = _h - _top_bar - _bot_bar;
var _cell_w = _grid_area_w / grid_cols;
var _cell_h = _grid_area_h / grid_rows;
var _cell = min(_cell_w, _cell_h);
var _grid_w = _cell * grid_cols;
var _grid_h = _cell * grid_rows;
var _grid_x = (_w - _grid_w) * 0.5;
var _grid_y = _top_bar + (_grid_area_h - _grid_h) * 0.5;

var _qx = quake_shake_x;
var _qy = quake_shake_y;

// === BACKGROUND ===
draw_set_alpha(1);
draw_rectangle_colour(0, 0, _w, _h,
	make_colour_rgb(35, 55, 35),
	make_colour_rgb(35, 55, 35),
	make_colour_rgb(50, 75, 45),
	make_colour_rgb(50, 75, 45), false);

// === FAULT LINE ===
var _fault_px = _grid_x + fault_col * _cell + _cell * 0.5 + _qx;
var _fault_half_w = fault_width * _cell * 0.5;
draw_set_alpha(0.6);
draw_set_colour(make_colour_rgb(60, 30, 20));
draw_rectangle(_fault_px - _fault_half_w, _grid_y - 10 + _qy, _fault_px + _fault_half_w, _grid_y + _grid_h + 10 + _qy, false);
draw_set_alpha(0.3);
draw_set_colour(make_colour_rgb(180, 60, 20));
draw_line_width(_fault_px - _fault_half_w, _grid_y - 10 + _qy, _fault_px - _fault_half_w, _grid_y + _grid_h + 10 + _qy, 2);
draw_line_width(_fault_px + _fault_half_w, _grid_y - 10 + _qy, _fault_px + _fault_half_w, _grid_y + _grid_h + 10 + _qy, 2);

// === CRACKS ===
var _ci = 0;
repeat(max_cracks) {
	if (crack_age[_ci] >= 0) {
		var _ca = 1 - crack_age[_ci] / 120;
		draw_set_alpha(_ca * 0.6);
		draw_set_colour(make_colour_rgb(80, 50, 30));
		draw_line_width(crack_x1[_ci] + _qx, crack_y1[_ci] + _qy, crack_x2[_ci] + _qx, crack_y2[_ci] + _qy, 2);
	}
	_ci++;
}

// === SEISMIC WAVE ===
if (quake_wave_x >= 0 && quake_wave_x <= 1) {
	var _wave_px = _grid_x + quake_wave_x * _grid_w;
	draw_set_alpha(0.25 * quake_intensity);
	draw_set_colour(make_colour_rgb(255, 200, 50));
	draw_line_width(_wave_px + _qx, _grid_y - 20 + _qy, _wave_px + _qx, _grid_y + _grid_h + 20 + _qy, 4);
	draw_set_alpha(0.1 * quake_intensity);
	draw_rectangle(_wave_px - 15 + _qx, _grid_y - 20 + _qy, _wave_px + 15 + _qx, _grid_y + _grid_h + 20 + _qy, false);
}

// === GRID CELLS ===
var _gi = 0;
repeat(grid_cols * grid_rows) {
	var _col = _gi mod grid_cols;
	var _row = _gi div grid_cols;
	var _cx = _grid_x + _col * _cell + _qx;
	var _cy = _grid_y + _row * _cell + _qy;

	// Cell background — tinted by fault proximity multiplier
	var _mult = fault_mult[_col];
	var _danger = (_mult - 1.0) / 2.0; // 0 at 1x, 1 at 3x
	var _bg_r = lerp(55, 100, _danger);
	var _bg_g = lerp(75, 55, _danger);
	var _bg_b = lerp(55, 40, _danger);
	draw_set_alpha(0.8);
	draw_set_colour(make_colour_rgb(_bg_r, _bg_g, _bg_b));
	draw_rectangle(_cx + 1, _cy + 1, _cx + _cell - 1, _cy + _cell - 1, false);

	// Multiplier label on empty cells
	if (grid_type[_gi] == 0 && _mult > 1 && game_state == 1 && !quake_active) {
		draw_set_alpha(0.25);
		draw_set_colour(make_colour_rgb(255, 220, 100));
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_text_ext_transformed(_cx + _cell * 0.5, _cy + _cell * 0.5, string(_mult) + "x", 0, _cell, 1, 1, 0);
	}

	// Grid lines
	draw_set_alpha(0.15);
	draw_set_colour(c_black);
	draw_rectangle(_cx, _cy, _cx + _cell, _cy + _cell, true);

	// Building
	if (grid_type[_gi] > 0) {
		var _sx = grid_shake_x[_gi];
		var _sy = grid_shake_y[_gi];
		var _bcx = _cx + _cell * 0.5 + _sx;
		var _bcy = _cy + _cell * 0.5 + _sy;
		var _btype = grid_type[_gi];
		var _hp_ratio = grid_hp[_gi] / max(1, grid_hp_max[_gi]);

		// Damage flash
		if (grid_flash[_gi] > 0) {
			draw_set_alpha(grid_flash[_gi] / 15 * 0.5);
			draw_set_colour(c_red);
			draw_rectangle(_cx + 2, _cy + 2, _cx + _cell - 2, _cy + _cell - 2, false);
		}

		// Repair flash
		if (repair_flash[_gi] > 0) {
			draw_set_alpha(repair_flash[_gi] / 10 * 0.4);
			draw_set_colour(make_colour_rgb(100, 255, 100));
			draw_rectangle(_cx + 2, _cy + 2, _cx + _cell - 2, _cy + _cell - 2, false);
		}

		// Brace indicator
		if (grid_braced[_gi]) {
			draw_set_alpha(0.3);
			draw_set_colour(make_colour_rgb(80, 150, 255));
			draw_rectangle(_cx + 1, _cy + 1, _cx + _cell - 1, _cy + _cell - 1, false);
			draw_set_alpha(0.7);
			draw_rectangle(_cx + 1, _cy + 1, _cx + _cell - 1, _cy + _cell - 1, true);
		}

		draw_set_alpha(1);

		var _pad = _cell * 0.15;
		var _bl = _cx + _pad + _sx;
		var _bt = _cy + _pad + _sy;
		var _br = _cx + _cell - _pad + _sx;
		var _bb = _cy + _cell - _pad + _sy;

		if (_btype == 1) {
			var _roof_h = (_bb - _bt) * 0.35;
			draw_set_colour(merge_colour(make_colour_rgb(180, 140, 100), c_red, 1 - _hp_ratio));
			draw_rectangle(_bl + 2, _bt + _roof_h, _br - 2, _bb, false);
			draw_set_colour(merge_colour(make_colour_rgb(160, 80, 60), c_dkgray, 1 - _hp_ratio));
			draw_triangle(_bl, _bt + _roof_h, _br, _bt + _roof_h, (_bl + _br) * 0.5, _bt, false);
			draw_set_colour(make_colour_rgb(200, 220, 255));
			var _ww = (_br - _bl) * 0.2;
			draw_rectangle(_bcx - _ww, _bt + _roof_h + 3, _bcx + _ww, _bt + _roof_h + 3 + _ww * 1.5, false);
		}
		else if (_btype == 2) {
			draw_set_colour(merge_colour(make_colour_rgb(150, 160, 180), c_red, 1 - _hp_ratio));
			draw_rectangle(_bl + 1, _bt, _br - 1, _bb, false);
			draw_set_colour(make_colour_rgb(200, 220, 255));
			var _ww = (_br - _bl) * 0.15;
			var _wgap = (_br - _bl) * 0.12;
			draw_rectangle(_bl + _wgap, _bt + 4, _bl + _wgap + _ww, _bt + 4 + _ww, false);
			draw_rectangle(_br - _wgap - _ww, _bt + 4, _br - _wgap, _bt + 4 + _ww, false);
			draw_rectangle(_bl + _wgap, _bcy, _bl + _wgap + _ww, _bcy + _ww, false);
			draw_rectangle(_br - _wgap - _ww, _bcy, _br - _wgap, _bcy + _ww, false);
		}
		else if (_btype == 3) {
			var _tw = (_br - _bl) * 0.6;
			draw_set_colour(merge_colour(make_colour_rgb(130, 140, 170), c_red, 1 - _hp_ratio));
			draw_rectangle(_bcx - _tw * 0.5, _bt + 4, _bcx + _tw * 0.5, _bb, false);
			draw_set_colour(make_colour_rgb(180, 180, 190));
			draw_line_width(_bcx, _bt + 4, _bcx, _bt - 2, 2);
			draw_set_colour(make_colour_rgb(200, 220, 255));
			var _ww = _tw * 0.3;
			var _wy = _bt + 8;
			repeat(3) {
				draw_rectangle(_bcx - _ww, _wy, _bcx + _ww, _wy + _ww * 0.8, false);
				_wy += _ww * 1.5;
			}
		}

		// HP bar (only if damaged)
		if (grid_hp[_gi] < grid_hp_max[_gi]) {
			var _bar_w = _cell * 0.6;
			var _bar_h = 4;
			var _bar_x = _cx + (_cell - _bar_w) * 0.5 + _sx;
			var _bar_y = _bb + 2 + _sy;
			draw_set_alpha(0.6);
			draw_set_colour(c_dkgray);
			draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
			draw_set_colour(merge_colour(c_red, c_lime, _hp_ratio));
			draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _hp_ratio, _bar_y + _bar_h, false);
		}

		// Upgrade arrow (pulsing up-arrow when full HP and upgradeable)
		if (grid_upgrade_ready[_gi] && !quake_active) {
			var _arr_alpha = 0.4 + sin(state_timer * 0.15 + _gi) * 0.3;
			draw_set_alpha(_arr_alpha);
			draw_set_colour(make_colour_rgb(100, 255, 150));
			var _ax = _cx + _cell * 0.5 + _sx;
			var _ay = _cy + 4 + _sy;
			draw_triangle(_ax - 5, _ay + 6, _ax + 5, _ay + 6, _ax, _ay, false);
		}
	}

	_gi++;
}

// === DEBRIS ===
var _di = 0;
repeat(max_debris) {
	if (debris_age[_di] >= 0) {
		var _da = 1 - debris_age[_di] / 40;
		draw_set_alpha(_da);
		draw_set_colour(debris_col[_di]);
		draw_rectangle(debris_x[_di] + _qx - 2, debris_y[_di] + _qy - 2,
			debris_x[_di] + _qx + 2, debris_y[_di] + _qy + 2, false);
	}
	_di++;
}

// === RIPPLES ===
var _ri = 0;
repeat(max_ripples) {
	if (ripple_age[_ri] >= 0) {
		var _t = ripple_age[_ri] / 20;
		draw_set_alpha((1 - _t) * 0.4);
		draw_set_colour(c_white);
		draw_circle(ripple_x[_ri], ripple_y[_ri], 8 + _t * 30, true);
	}
	_ri++;
}

// === FLOAT TEXT (income popups) ===
var _fi = 0;
repeat(max_floats) {
	if (float_age[_fi] >= 0) {
		var _ft = float_age[_fi] / 50;
		draw_set_alpha((1 - _ft) * 0.8);
		draw_set_colour(make_colour_rgb(255, 220, 100));
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_text_ext_transformed(float_x[_fi], float_y[_fi], float_text[_fi], 0, _w, 1.5, 1.5, 0);
	}
	_fi++;
}

// === UI ===
draw_set_alpha(1);

if (game_state == 1) {
	// Top bar
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);

	// Timer
	var _secs = max(0, ceil(game_timer / 60));
	var _timer_col = (_secs <= 10) ? make_colour_rgb(255, 80, 60) : c_white;
	draw_set_colour(_timer_col);
	draw_text_ext_transformed(_w * 0.5, 5, string(_secs), 0, _w, 2.5, 2.5, 0);

	// Score + income rate
	draw_set_colour(c_white);
	draw_set_alpha(0.6);
	draw_text_ext_transformed(_w * 0.5, 38, "Score: " + string(income_accumulated) + "  (" + string(income) + "/s)", 0, _w, 1.2, 1.2, 0);

	// Best
	draw_set_halign(fa_left);
	draw_set_alpha(0.4);
	draw_text_ext_transformed(8, 8, "Best: " + string(points), 0, _w, 1.1, 1.1, 0);

	// Quake count
	draw_set_halign(fa_right);
	draw_set_alpha(0.4);
	draw_text_ext_transformed(_w - 8, 8, "Quakes: " + string(quake_number), 0, _w, 1.1, 1.1, 0);

	// Earthquake warning with direction
	if (warning_timer > 0 && !quake_active) {
		var _warn_alpha = 0.5 + sin(warning_timer * 0.3) * 0.4;
		draw_set_alpha(_warn_alpha);
		draw_set_colour(make_colour_rgb(255, 200, 50));
		draw_set_halign(fa_center);

		var _dir_text = "";
		if (quake_warning_dir < 0) _dir_text = "<<< QUAKE FROM LEFT <<<";
		else if (quake_warning_dir > 0) _dir_text = ">>> QUAKE FROM RIGHT >>>";
		else _dir_text = "=== EARTHQUAKE INCOMING ===";

		draw_text_ext_transformed(_w * 0.5, _grid_y - 22, _dir_text, 0, _w, 1.3, 1.3, 0);
	}

	// Aftershock warning
	if (aftershock_queue > 0 && !quake_active) {
		draw_set_alpha(0.5 + sin(state_timer * 0.4) * 0.3);
		draw_set_colour(make_colour_rgb(255, 150, 50));
		draw_set_halign(fa_center);
		draw_text_ext_transformed(_w * 0.5, _grid_y - 22, "AFTERSHOCK INCOMING (" + string(aftershock_queue) + " remaining)", 0, _w, 1.2, 1.2, 0);
	}

	// During quake: brace instruction
	if (quake_active) {
		draw_set_alpha(0.7 + sin(state_timer * 0.4) * 0.3);
		draw_set_colour(make_colour_rgb(80, 150, 255));
		draw_set_halign(fa_center);
		draw_text_ext_transformed(_w * 0.5, _grid_y - 22, "TAP TO BRACE!", 0, _w, 1.4, 1.4, 0);
	}

	// Bottom bar: build selector
	draw_set_alpha(0.85);
	draw_set_colour(make_colour_rgb(30, 30, 30));
	draw_rectangle(0, _h - _bot_bar, _w, _h, false);

	var _btn_w = min(80, _w / 4);
	var _btn_h = 40;
	var _btn_y = _h - _bot_bar + 10;
	var _btn_start_x = (_w - _btn_w * 3 - 10 * 2) * 0.5;

	if (!quake_active) {
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		draw_set_alpha(0.4);
		draw_set_colour(c_white);
		draw_text_ext_transformed(_w * 0.5, _h - _bot_bar - 16, "Tap: build | damaged: repair | full HP: upgrade", 0, _w, 0.95, 0.95, 0);
	}

	var _bi = 1;
	repeat(3) {
		var _bx = _btn_start_x + (_bi - 1) * (_btn_w + 10);
		var _selected = (_bi == build_selection);

		draw_set_alpha(1);
		draw_set_colour(_selected ? make_colour_rgb(60, 100, 160) : make_colour_rgb(50, 50, 60));
		draw_rectangle(_bx, _btn_y, _bx + _btn_w, _btn_y + _btn_h, false);
		draw_set_colour(_selected ? c_white : make_colour_rgb(100, 100, 110));
		draw_rectangle(_bx, _btn_y, _bx + _btn_w, _btn_y + _btn_h, true);

		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_colour(c_white);
		draw_text_ext_transformed(_bx + _btn_w * 0.5, _btn_y + _btn_h * 0.5 - 2, build_names[_bi], 0, _btn_w, 1.1, 1.1, 0);

		draw_set_alpha(0.5);
		draw_set_valign(fa_top);
		draw_text_ext_transformed(_bx + _btn_w * 0.5, _btn_y + _btn_h + 2, string(build_value[_bi]) + "pt " + string(build_hp[_bi]) + "HP", 0, _btn_w + 20, 0.9, 0.9, 0);

		_bi++;
	}
}
else if (game_state == 0) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _pulse = 0.7 + sin(title_pulse) * 0.3;
	draw_set_alpha(_pulse);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.15, "FAULT LINE", 0, _w, 3, 3, 0);

	draw_set_alpha(0.5);
	draw_text_ext_transformed(_w * 0.5, _h * 0.15 + 50, "city on the edge", 0, _w, 1.5, 1.5, 0);

	draw_set_alpha(0.45);
	draw_set_colour(make_colour_rgb(255, 220, 100));
	draw_text_ext_transformed(_w * 0.5, _h * 0.38, "Build near the fault for 2-3x points", 0, _w, 1.3, 1.3, 0);
	draw_set_colour(make_colour_rgb(255, 150, 50));
	draw_text_ext_transformed(_w * 0.5, _h * 0.38 + 26, "Brace buildings during quakes", 0, _w, 1.3, 1.3, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.38 + 52, "Repair + upgrade between quakes", 0, _w, 1.3, 1.3, 0);
	draw_set_colour(make_colour_rgb(255, 100, 80));
	draw_text_ext_transformed(_w * 0.5, _h * 0.38 + 78, "Watch for aftershocks!", 0, _w, 1.3, 1.3, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.38 + 104, "Survive 60 seconds — score = income over time", 0, _w, 1.2, 1.2, 0);

	draw_set_alpha(0.4 + sin(title_pulse * 1.5) * 0.3);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.8, "TAP TO BEGIN", 0, _w, 2, 2, 0);

	if (points > 0) {
		draw_set_alpha(0.4);
		draw_text_ext_transformed(_w * 0.5, _h * 0.8 + 40, "BEST: " + string(points), 0, _w, 1.3, 1.3, 0);
	}
}
else if (game_state == 2) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.25, "TIME'S UP!", 0, _w, 3, 3, 0);

	draw_set_alpha(0.7);
	draw_set_colour(make_colour_rgb(255, 220, 100));
	draw_text_ext_transformed(_w * 0.5, _h * 0.4, "Score: " + string(income_accumulated), 0, _w, 2.5, 2.5, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.4 + 45, "Population: " + string(population) + "  Quakes: " + string(quake_number), 0, _w, 1.4, 1.4, 0);

	if (income_accumulated >= points && income_accumulated > 0) {
		draw_set_colour(make_colour_rgb(255, 220, 100));
		draw_text_ext_transformed(_w * 0.5, _h * 0.55, "NEW BEST!", 0, _w, 2, 2, 0);
	}

	if (state_timer > 60) {
		draw_set_alpha(0.4 + sin(state_timer * 0.08) * 0.3);
		draw_set_colour(c_white);
		draw_text_ext_transformed(_w * 0.5, _h * 0.75, "TAP TO RETRY", 0, _w, 1.8, 1.8, 0);
	}
}

draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
