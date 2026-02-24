
var _w = display_get_gui_width();
var _h = display_get_gui_height();

// ============================================================
// BACKGROUND
// ============================================================
draw_set_color(COL_BG);
draw_rectangle(0, 0, _w, _h, false);

// Stars
for (var i = 0; i < STAR_COUNT; i++) {
	var _sx = star_sx[i] * _w;
	var _sy = star_sy[i] * _h;
	var _sb = star_br[i] * (0.6 + 0.4 * sin(anim_t * 0.02 + i));
	draw_set_color(make_color_rgb(floor(180 * _sb), floor(180 * _sb), floor(255 * _sb)));
	draw_set_alpha(_sb);
	draw_circle(_sx, _sy, 1, false);
}
draw_set_alpha(1);

// Only draw game elements when playing or dead
if (game_state == 1 || game_state == 2) {

	// ============================================================
	// TRAJECTORY PREVIEW (behind everything)
	// ============================================================
	if (game_state == 1 && (wave_phase == 0 || wave_phase == 1)) {
		var _pred_steps = 80;
		if (wave_phase == 1) _pred_steps = 40;

		var _px = comet_x;
		var _py = comet_y;
		var _pvx = comet_vx;
		var _pvy = comet_vy;

		for (var step = 0; step < _pred_steps; step++) {
			// Simulate gravity
			for (var i = 0; i < planet_count; i++) {
				var _ddx = planet_x[i] - _px;
				var _ddy = planet_y[i] - _py;
				var _dr = max(point_distance(_px, _py, planet_x[i], planet_y[i]), 35);
				var _str = GRAVITY / _dr;
				_pvx += _str * _ddx / _dr;
				_pvy += _str * _ddy / _dr;
			}
			// Cap predicted speed
			var _ps = point_distance(0, 0, _pvx, _pvy);
			if (_ps > SPEED_CAP) {
				_pvx = _pvx / _ps * SPEED_CAP;
				_pvy = _pvy / _ps * SPEED_CAP;
			}
			_px += _pvx;
			_py += _pvy;

			// Draw dot every 3 steps
			if (step mod 3 == 0) {
				var _da = 0.25 * (1 - step / _pred_steps);
				draw_set_alpha(_da);
				draw_set_color(COL_COMET);
				draw_circle(_px, _py, 1.5, false);
			}

			if (_px < -50 || _px > _w + 50 || _py < -50 || _py > _h + 50) break;
		}
		draw_set_alpha(1);
	}

	// ============================================================
	// GATES
	// ============================================================
	for (var i = 0; i < gate_count; i++) {
		if (gate_anim[i] >= 0 && gate_anim[i] < 25) {
			// Collected: expanding + fading ring
			var _t = gate_anim[i] / 25;
			var _gr = GATE_RADIUS + _t * 35;
			draw_set_alpha(1 - _t);
			draw_set_color(COL_GATE_HIT);
			draw_circle(gate_x[i], gate_y[i], _gr, true);
			draw_circle(gate_x[i], gate_y[i], _gr - 2, true);
			draw_set_alpha(1);
		} else if (!gate_collected[i]) {
			// Active gate: pulsing ring
			var _pulse = 1 + 0.12 * sin(anim_t * 0.08 + i * 2);
			var _gr = GATE_RADIUS * _pulse;

			// Outer glow
			draw_set_alpha(0.15);
			draw_set_color(COL_GATE);
			draw_circle(gate_x[i], gate_y[i], _gr + 10, false);

			// Ring
			draw_set_alpha(0.8);
			draw_set_color(COL_GATE);
			draw_circle(gate_x[i], gate_y[i], _gr, true);
			draw_circle(gate_x[i], gate_y[i], _gr - 2, true);

			draw_set_alpha(1);
		}
	}

	// ============================================================
	// PLANETS
	// ============================================================
	for (var i = 0; i < planet_count; i++) {
		var _scale = min(1, planet_age[i] / 10);
		var _pr = PLANET_RADIUS * _scale;

		// Glow
		draw_set_alpha(0.12);
		draw_set_color(planet_col[i]);
		draw_circle(planet_x[i], planet_y[i], _pr + 18, false);

		// Body
		draw_set_alpha(0.85);
		draw_set_color(planet_col[i]);
		draw_circle(planet_x[i], planet_y[i], _pr, false);

		// Highlight
		draw_set_alpha(0.25);
		draw_set_color(c_white);
		draw_circle(planet_x[i] - _pr * 0.3, planet_y[i] - _pr * 0.3, _pr * 0.35, false);

		draw_set_alpha(1);
	}

	// ============================================================
	// COMET TRAIL
	// ============================================================
	if (game_state == 1 && wave_phase >= 1) {
		for (var i = 0; i < trail_count; i++) {
			var _t = i / TRAIL_MAX;
			var _tr = max(1, COMET_RADIUS * (1 - _t * 0.8));
			draw_set_alpha((1 - _t) * 0.6);
			draw_set_color(merge_color(COL_COMET, COL_TRAIL, _t));
			draw_circle(trail_x[i], trail_y[i], _tr, false);
		}
		draw_set_alpha(1);
	}

	// ============================================================
	// COMET
	// ============================================================
	if (game_state == 1) {
		var _cpulse = 1;
		if (wave_phase == 0) _cpulse = 1 + 0.25 * sin(anim_t * 0.15);

		// Glow
		draw_set_alpha(0.25);
		draw_set_color(COL_COMET);
		draw_circle(comet_x, comet_y, (COMET_RADIUS + 10) * _cpulse, false);

		// Body
		draw_set_alpha(1);
		draw_set_color(c_white);
		draw_circle(comet_x, comet_y, COMET_RADIUS * _cpulse, false);
		draw_set_color(COL_COMET);
		draw_circle(comet_x, comet_y, (COMET_RADIUS - 2) * _cpulse, false);
	}

	// ============================================================
	// PARTICLES
	// ============================================================
	for (var i = 0; i < part_count; i++) {
		draw_set_alpha(part_life[i] / 30);
		draw_set_color(part_col[i]);
		draw_circle(part_px[i], part_py[i], 2, false);
	}
	draw_set_alpha(1);

	// ============================================================
	// SCORE POPUP
	// ============================================================
	if (popup_timer > 0) {
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_alpha(popup_timer / 40);
		draw_set_color(COL_GATE_HIT);
		draw_set_font(fnt_default);
		draw_text_transformed(popup_x, popup_y - 20, popup_text, 1.5, 1.5, 0);
		draw_set_alpha(1);
	}

	// ============================================================
	// HUD
	// ============================================================
	draw_set_font(fnt_default);
	draw_set_valign(fa_top);

	// Score (top left)
	draw_set_halign(fa_left);
	draw_set_color(c_white);
	draw_text_transformed(12, 10, "Score: " + string(points), 1.5, 1.5, 0);

	// Wave (top center)
	draw_set_halign(fa_center);
	draw_set_color(make_color_rgb(180, 180, 220));
	draw_text_transformed(_w * 0.5, 10, "Wave " + string(wave), 1.5, 1.5, 0);

	// Planets remaining (top right)
	draw_set_halign(fa_right);
	draw_set_color(make_color_rgb(150, 130, 200));
	var _pdots = "";
	for (var i = 0; i < planets_remaining; i++) _pdots += "o ";
	draw_text_transformed(_w - 12, 10, _pdots, 1.5, 1.5, 0);

	// Gates (top right, below planets)
	draw_set_color(COL_GATE);
	draw_text_transformed(_w - 12, 32, string(gates_got) + "/" + string(gate_count), 1.3, 1.3, 0);
}

// ============================================================
// WAVE TEXT OVERLAY
// ============================================================
if (game_state == 1 && wave_text_alpha > 0.01) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);

	draw_set_alpha(wave_text_alpha);
	draw_set_color(c_white);
	draw_text_transformed(_w * 0.5, _h * 0.5 - 25, "WAVE " + string(wave), 3.5, 3.5, 0);

	draw_set_alpha(wave_text_alpha * 0.7);
	draw_set_color(make_color_rgb(150, 150, 200));
	draw_text_transformed(_w * 0.5, _h * 0.5 + 20, "Tap to place gravity wells", 1.5, 1.5, 0);

	draw_set_alpha(1);
}

// ============================================================
// TITLE SCREEN
// ============================================================
if (game_state == 0) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);

	// Title
	draw_set_color(COL_COMET);
	draw_text_transformed(_w * 0.5, _h * 0.5 - 50, "ORBITAL", 4, 4, 0);

	// Subtitle
	draw_set_color(make_color_rgb(180, 180, 220));
	draw_text_transformed(_w * 0.5, _h * 0.5 + 5, "Slingshot through the stars", 1.8, 1.8, 0);

	// CTA
	var _cta_alpha = 0.5 + 0.5 * sin(anim_t * 0.06);
	draw_set_alpha(_cta_alpha);
	draw_set_color(c_white);
	draw_text_transformed(_w * 0.5, _h * 0.5 + 50, "Tap to Start", 2, 2, 0);
	draw_set_alpha(1);

	// Best score
	if (best_score > 0) {
		draw_set_color(make_color_rgb(100, 100, 150));
		draw_text_transformed(_w * 0.5, _h * 0.5 + 90, "Best: " + string(best_score), 1.5, 1.5, 0);
	}
}

// ============================================================
// GAME OVER SCREEN
// ============================================================
if (game_state == 2) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);

	var _fade = clamp(1 - death_timer / 60, 0, 1);

	// Dim overlay
	draw_set_alpha(_fade * 0.5);
	draw_set_color(c_black);
	draw_rectangle(0, 0, _w, _h, false);

	draw_set_alpha(_fade);

	// Game Over
	draw_set_color(COL_COMET);
	draw_text_transformed(_w * 0.5, _h * 0.5 - 55, "GAME OVER", 3.5, 3.5, 0);

	// Score
	draw_set_color(c_white);
	draw_text_transformed(_w * 0.5, _h * 0.5, "Score: " + string(points), 2.5, 2.5, 0);

	// Wave
	draw_set_color(make_color_rgb(180, 180, 220));
	draw_text_transformed(_w * 0.5, _h * 0.5 + 35, "Wave " + string(wave), 2, 2, 0);

	// New best
	if (points >= best_score && points > 0) {
		draw_set_color(COL_GATE_HIT);
		draw_text_transformed(_w * 0.5, _h * 0.5 + 65, "NEW BEST!", 2, 2, 0);
	}

	// Retry prompt
	if (death_timer <= 30) {
		var _ra = 0.5 + 0.5 * sin(anim_t * 0.08);
		draw_set_alpha(_fade * _ra);
		draw_set_color(make_color_rgb(150, 150, 200));
		draw_text_transformed(_w * 0.5, _h * 0.5 + 105, "Tap to Retry", 1.8, 1.8, 0);
	}

	draw_set_alpha(1);
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
draw_set_color(c_white);
