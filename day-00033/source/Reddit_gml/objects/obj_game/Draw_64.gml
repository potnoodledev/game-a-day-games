
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

// === BACKGROUND: Dusk sky gradient ===
draw_set_alpha(1);
var _grad_steps = 8;
var _step_h = _h / _grad_steps;
var _si = 0;
repeat(_grad_steps) {
	var _t = _si / _grad_steps;
	var _col = merge_colour(bg_color_top, bg_color_bot, _t);
	draw_rectangle_colour(0, _si * _step_h, _w, (_si + 1) * _step_h, _col, _col, _col, _col, false);
	_si++;
}

// === STARS (subtle background detail) ===
draw_set_alpha(0.3);
draw_set_colour(c_white);
// Deterministic stars based on position
randomize(); // Seed doesn't matter, they flicker naturally
var _star_i = 0;
repeat(30) {
	var _sx = (_star_i * 137 + 50) mod _w;
	var _sy = (_star_i * 97 + 30) mod (_h * 0.6);
	var _star_alpha = 0.15 + sin(state_timer * 0.03 + _star_i * 2.1) * 0.15;
	draw_set_alpha(_star_alpha);
	draw_circle(_sx, _sy, 1, false);
	_star_i++;
}
draw_set_alpha(1);

// === DRAW BIRDS ===
var _i = 0;
repeat(num_birds) {
	if (bird_alive[_i]) {
		var _bx = bird_x[_i];
		var _by = bird_y[_i];
		var _bvx = bird_vx[_i];
		var _bvy = bird_vy[_i];

		// Bird color: slightly varies per bird
		var _hue_shift = (_i * 37) mod 60;
		var _bird_col = make_colour_rgb(
			180 + _hue_shift,
			190 + (_hue_shift div 2),
			220
		);

		// Speed-based brightness
		var _spd = sqrt(_bvx * _bvx + _bvy * _bvy);
		var _bright = 0.6 + (_spd / boid_speed_max) * 0.4;

		// Draw bird as a V-shape (wing angle based on velocity)
		var _angle = point_direction(0, 0, _bvx, _bvy);
		var _wing_len = 5 + _spd * 0.5;

		// Body dot
		draw_set_alpha(_bright);
		draw_set_colour(_bird_col);
		draw_circle(_bx, _by, 2, false);

		// Wings (two lines forming a V)
		var _wing_angle = 35;
		var _la = _angle + 180 + _wing_angle;
		var _ra = _angle + 180 - _wing_angle;
		var _lx = _bx + lengthdir_x(_wing_len, _la);
		var _ly = _by + lengthdir_y(_wing_len, _la);
		var _rx = _bx + lengthdir_x(_wing_len, _ra);
		var _ry = _by + lengthdir_y(_wing_len, _ra);

		draw_set_alpha(_bright * 0.8);
		draw_line_width(_bx, _by, _lx, _ly, 1.5);
		draw_line_width(_bx, _by, _rx, _ry, 1.5);
	}
	_i++;
}

// === DRAW HAWKS ===
var _hi = 0;
repeat(max_hawks) {
	if (hawk_alive[_hi]) {
		var _hx = hawk_x[_hi];
		var _hy = hawk_y[_hi];
		var _hvx = hawk_vx[_hi];
		var _hvy = hawk_vy[_hi];

		// Red warning circle
		draw_set_alpha(0.15);
		draw_set_colour(c_red);
		draw_circle(_hx, _hy, 25, false);

		// Hawk body
		var _angle = point_direction(0, 0, _hvx, _hvy);
		var _wing_len = 12;

		draw_set_alpha(1);
		draw_set_colour(make_colour_rgb(180, 60, 30));
		draw_circle(_hx, _hy, 4, false);

		// Hawk wings (wider, more aggressive)
		var _la = _angle + 180 + 50;
		var _ra = _angle + 180 - 50;
		var _lx = _hx + lengthdir_x(_wing_len, _la);
		var _ly = _hy + lengthdir_y(_wing_len, _la);
		var _rx = _hx + lengthdir_x(_wing_len, _ra);
		var _ry = _hy + lengthdir_y(_wing_len, _ra);

		draw_set_colour(make_colour_rgb(200, 80, 40));
		draw_line_width(_hx, _hy, _lx, _ly, 2.5);
		draw_line_width(_hx, _hy, _rx, _ry, 2.5);
	}
	_hi++;
}

// === KILL EFFECTS (feather burst) ===
var _ki = 0;
repeat(max_kill_fx) {
	if (kill_fx_age[_ki] >= 0) {
		var _t = kill_fx_age[_ki] / 25; // 0→1
		var _kx = kill_fx_x[_ki];
		var _ky = kill_fx_y[_ki];
		var _alpha = (1 - _t);

		// Red flash
		draw_set_alpha(_alpha * 0.5);
		draw_set_colour(make_colour_rgb(255, 60, 40));
		draw_circle(_kx, _ky, 6 + _t * 12, false);

		// Scattered feather particles (6 directions)
		draw_set_colour(make_colour_rgb(220, 210, 240));
		var _fi = 0;
		repeat(6) {
			var _angle = _fi * 60 + _ki * 30;
			var _dist = _t * 25 + _fi * 3;
			var _fx = _kx + lengthdir_x(_dist, _angle);
			var _fy = _ky + lengthdir_y(_dist, _angle);
			draw_set_alpha(_alpha * 0.7);
			draw_circle(_fx, _fy, 1.5 - _t, false);
			_fi++;
		}
	}
	_ki++;
}

// === TOUCH RIPPLES ===
var _ri = 0;
repeat(max_ripples) {
	if (ripple_age[_ri] >= 0) {
		var _t = ripple_age[_ri] / 30; // 0 → 1
		var _radius = 10 + _t * 50;
		var _alpha = (1 - _t) * 0.35;
		draw_set_alpha(_alpha);
		draw_set_colour(c_white);
		draw_circle(ripple_x[_ri], ripple_y[_ri], _radius, true);
	}
	_ri++;
}

// Active touch glow
if (touch_active && game_state == 1) {
	draw_set_alpha(0.15);
	draw_set_colour(c_white);
	draw_circle(touch_x, touch_y, 35, false);
	draw_set_alpha(0.08);
	draw_circle(touch_x, touch_y, 70, false);
}

// === UI ===
draw_set_alpha(1);
draw_set_font(fnt_default);

if (game_state == 1) {
	// Flock counter (top center)
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);

	// Timer (top center)
	var _secs = max(0, ceil(game_timer / 60));
	var _timer_col = (_secs <= 10) ? make_colour_rgb(255, 80, 60) : c_white;
	draw_set_colour(_timer_col);
	draw_text_ext_transformed(_w * 0.5, 12, string(_secs), 0, _w, 3, 3, 0);

	// Flock count below timer
	draw_set_alpha(0.6);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, 52, string(score_display) + " birds", 0, _w, 1.5, 1.5, 0);

	// Best score (top left)
	draw_set_halign(fa_left);
	draw_set_alpha(0.4);
	draw_text_ext_transformed(10, 10, "BEST: " + string(points), 0, _w, 1.2, 1.2, 0);

	// Hawks count (top right)
	if (num_hawks > 0) {
		draw_set_halign(fa_right);
		draw_set_alpha(0.6);
		draw_set_colour(make_colour_rgb(255, 100, 80));
		draw_text_ext_transformed(_w - 10, 10, string(num_hawks) + " hawks", 0, _w, 1.2, 1.2, 0);
	}
}
else if (game_state == 0) {
	// Title screen
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _pulse = 0.7 + sin(title_pulse) * 0.3;
	draw_set_alpha(_pulse);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.2, "MURMURATION", 0, _w, 3, 3, 0);

	draw_set_alpha(0.5);
	draw_text_ext_transformed(_w * 0.5, _h * 0.2 + 50, "guide the flock", 0, _w, 1.5, 1.5, 0);

	// Instructions
	draw_set_alpha(0.45);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.42, "Touch to attract birds", 0, _w, 1.4, 1.4, 0);
	draw_set_colour(make_colour_rgb(255, 100, 80));
	draw_text_ext_transformed(_w * 0.5, _h * 0.42 + 30, "Dodge the hawks — they never stop", 0, _w, 1.4, 1.4, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.42 + 60, "Survive 60 seconds", 0, _w, 1.4, 1.4, 0);

	draw_set_alpha(0.4 + sin(title_pulse * 1.5) * 0.3);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.75, "TAP TO BEGIN", 0, _w, 2, 2, 0);

	// High score
	if (points > 0) {
		draw_set_alpha(0.4);
		draw_text_ext_transformed(_w * 0.5, _h * 0.75 + 45, "BEST FLOCK: " + string(points), 0, _w, 1.3, 1.3, 0);
	}
}
else if (game_state == 2) {
	// Game over
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _survived = (game_timer <= 0);
	draw_set_alpha(1);

	if (_survived) {
		draw_set_colour(make_colour_rgb(100, 255, 160));
		draw_text_ext_transformed(_w * 0.5, _h * 0.3, "SURVIVED!", 0, _w, 3, 3, 0);
	} else {
		draw_set_colour(c_white);
		draw_text_ext_transformed(_w * 0.5, _h * 0.3, "FLOCK SCATTERED", 0, _w, 2.5, 2.5, 0);
	}

	draw_set_alpha(0.7);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.45, "Best flock: " + string(best_flock), 0, _w, 2, 2, 0);
	draw_text_ext_transformed(_w * 0.5, _h * 0.45 + 40, "Birds lost: " + string(birds_lost), 0, _w, 1.5, 1.5, 0);

	if (best_flock >= points && best_flock > 0) {
		draw_set_colour(make_colour_rgb(255, 220, 100));
		draw_text_ext_transformed(_w * 0.5, _h * 0.6, "NEW BEST!", 0, _w, 2, 2, 0);
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
