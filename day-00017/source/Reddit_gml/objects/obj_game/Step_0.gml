
var _w = window_get_width();
var _h = window_get_height();

anim_t++;
if (tap_cd > 0) tap_cd--;

// ============================================================
// WAVE START LOGIC
// ============================================================
if (wave_start) {
	wave_start = false;
	wave++;
	wave_phase = 0;
	wave_timer = 90; // 1.5 sec pre-launch
	wave_text_alpha = 1;

	// Reset comet
	comet_x = 50;
	comet_y = _h * 0.3 + random(_h * 0.4);
	comet_vx = 2.0 + wave * 0.2;
	comet_vy = -0.5 + random(1.0);

	// Clear planets
	planet_count = 0;
	planets_remaining = max(3, MAX_PLANETS - floor((wave - 1) / 3));

	// Generate gates
	gate_count = min(2 + wave, GATE_MAX);
	gates_got = 0;

	for (var i = 0; i < gate_count; i++) {
		var _placed = false;
		var _attempts = 0;
		while (!_placed && _attempts < 50) {
			var _gx = _w * 0.25 + random(_w * 0.65);
			var _gy = 70 + random(_h - 140);

			var _ok = true;
			for (var j = 0; j < i; j++) {
				if (point_distance(_gx, _gy, gate_x[j], gate_y[j]) < 80) {
					_ok = false;
					break;
				}
			}
			if (point_distance(_gx, _gy, comet_x, comet_y) < 100) _ok = false;

			if (_ok) {
				gate_x[i] = _gx;
				gate_y[i] = _gy;
				_placed = true;
			}
			_attempts++;
		}
		if (!_placed) {
			gate_x[i] = _w * 0.25 + random(_w * 0.65);
			gate_y[i] = 70 + random(_h - 140);
		}
		gate_collected[i] = false;
		gate_anim[i] = -1;
	}

	// Reset trail
	trail_count = 0;
	for (var i = 0; i < TRAIL_MAX; i++) {
		trail_x[i] = comet_x;
		trail_y[i] = comet_y;
	}
}

// ============================================================
// STATE: WAITING (title screen)
// ============================================================
if (game_state == 0) {
	if (device_mouse_check_button_pressed(0, mb_left) && tap_cd <= 0) {
		game_state = 1;
		points = 0;
		wave = 0;
		wave_start = true;
		tap_cd = 15;
	}
}

// ============================================================
// STATE: PLAYING
// ============================================================
if (game_state == 1) {

	// --- PRE-LAUNCH PHASE ---
	if (wave_phase == 0) {
		wave_timer--;
		wave_text_alpha = max(0, wave_text_alpha - 0.015);

		// Allow planet placement during pre-launch
		if (device_mouse_check_button_pressed(0, mb_left) && tap_cd <= 0 && planets_remaining > 0) {
			var _mx = device_mouse_x_to_gui(0);
			var _my = device_mouse_y_to_gui(0);

			var _valid = true;
			if (point_distance(_mx, _my, comet_x, comet_y) < 50) _valid = false;
			if (_my < 55) _valid = false;
			for (var i = 0; i < planet_count; i++) {
				if (point_distance(_mx, _my, planet_x[i], planet_y[i]) < 50) _valid = false;
			}

			if (_valid) {
				planet_x[planet_count] = _mx;
				planet_y[planet_count] = _my;
				planet_col[planet_count] = pcols[planet_count mod 5];
				planet_age[planet_count] = 0;
				planet_count++;
				planets_remaining--;
				tap_cd = 10;
			}
		}

		if (wave_timer <= 0) {
			wave_phase = 1;
		}
	}

	// --- ACTIVE PHASE ---
	if (wave_phase == 1) {

		// Planet placement
		if (device_mouse_check_button_pressed(0, mb_left) && tap_cd <= 0 && planets_remaining > 0) {
			var _mx = device_mouse_x_to_gui(0);
			var _my = device_mouse_y_to_gui(0);

			var _valid = true;
			if (point_distance(_mx, _my, comet_x, comet_y) < 40) _valid = false;
			if (_my < 55) _valid = false;
			for (var i = 0; i < planet_count; i++) {
				if (point_distance(_mx, _my, planet_x[i], planet_y[i]) < 50) _valid = false;
			}

			if (_valid) {
				planet_x[planet_count] = _mx;
				planet_y[planet_count] = _my;
				planet_col[planet_count] = pcols[planet_count mod 5];
				planet_age[planet_count] = 0;
				planet_count++;
				planets_remaining--;
				tap_cd = 10;
			}
		}

		// Apply gravity from each planet
		for (var i = 0; i < planet_count; i++) {
			var _dx = planet_x[i] - comet_x;
			var _dy = planet_y[i] - comet_y;
			var _r = max(point_distance(comet_x, comet_y, planet_x[i], planet_y[i]), 35);
			var _strength = GRAVITY / _r;
			comet_vx += _strength * _dx / _r;
			comet_vy += _strength * _dy / _r;
		}

		// Cap speed
		var _spd = point_distance(0, 0, comet_vx, comet_vy);
		if (_spd > SPEED_CAP) {
			comet_vx = comet_vx / _spd * SPEED_CAP;
			comet_vy = comet_vy / _spd * SPEED_CAP;
		}

		// Move comet
		comet_x += comet_vx;
		comet_y += comet_vy;

		// Update trail
		for (var i = TRAIL_MAX - 1; i > 0; i--) {
			trail_x[i] = trail_x[i - 1];
			trail_y[i] = trail_y[i - 1];
		}
		trail_x[0] = comet_x;
		trail_y[0] = comet_y;
		trail_count = min(trail_count + 1, TRAIL_MAX);

		// Check gate collisions
		for (var i = 0; i < gate_count; i++) {
			if (!gate_collected[i]) {
				var _gd = point_distance(comet_x, comet_y, gate_x[i], gate_y[i]);
				if (_gd < GATE_COLLECT_DIST) {
					gate_collected[i] = true;
					gate_anim[i] = 0;
					gates_got++;
					var _pts = 100 * wave;
					points += _pts;

					// Score popup
					popup_text = "+" + string(_pts);
					popup_x = gate_x[i];
					popup_y = gate_y[i];
					popup_timer = 40;

					// Particles
					for (var p = 0; p < 8; p++) {
						if (part_count < PART_MAX) {
							var _ang = random(360);
							var _sp = 1 + random(3);
							part_px[part_count] = gate_x[i];
							part_py[part_count] = gate_y[i];
							part_vx[part_count] = lengthdir_x(_sp, _ang);
							part_vy[part_count] = lengthdir_y(_sp, _ang);
							part_life[part_count] = 20 + irandom(15);
							part_col[part_count] = COL_GATE;
							part_count++;
						}
					}

					// Check all collected
					if (gates_got >= gate_count) {
						var _bonus = 500 * wave;
						points += _bonus;
						popup_text = "CLEAR! +" + string(_bonus);
						popup_timer = 60;
						wave_phase = 2;
						wave_timer = 60;
					}
				}
			}
		}

		// Check planet collision (crash)
		for (var i = 0; i < planet_count; i++) {
			if (point_distance(comet_x, comet_y, planet_x[i], planet_y[i]) < PLANET_RADIUS + COMET_RADIUS) {
				death_timer = 90;
				game_state = 2;

				// Explosion particles
				for (var p = 0; p < 15; p++) {
					if (part_count < PART_MAX) {
						var _ang = random(360);
						var _sp = 2 + random(4);
						part_px[part_count] = comet_x;
						part_py[part_count] = comet_y;
						part_vx[part_count] = lengthdir_x(_sp, _ang);
						part_vy[part_count] = lengthdir_y(_sp, _ang);
						part_life[part_count] = 25 + irandom(20);
						part_col[part_count] = COL_COMET;
						part_count++;
					}
				}

				if (points > best_score) best_score = points;
				api_submit_score(points, function(_s, _o, _r, _p) {});
				break;
			}
		}

		// Check off screen
		if (game_state == 1) {
			var _margin = 60;
			if (comet_x < -_margin || comet_x > _w + _margin || comet_y < -_margin || comet_y > _h + _margin) {
				if (gates_got == 0 && wave > 1) {
					// No gates collected after wave 1 = game over
					death_timer = 90;
					game_state = 2;
					if (points > best_score) best_score = points;
					api_submit_score(points, function(_s, _o, _r, _p) {});
				} else {
					// Next wave
					wave_start = true;
				}
			}
		}
	}

	// --- WAVE COMPLETE PHASE ---
	if (wave_phase == 2) {
		wave_timer--;
		if (wave_timer <= 0) {
			wave_start = true;
		}
	}
}

// ============================================================
// STATE: DEAD
// ============================================================
if (game_state == 2) {
	death_timer--;
	if (death_timer < 0) death_timer = 0;

	if (device_mouse_check_button_pressed(0, mb_left) && tap_cd <= 0 && death_timer <= 30) {
		game_state = 1;
		points = 0;
		wave = 0;
		wave_start = true;
		tap_cd = 15;
	}
}

// ============================================================
// UPDATE PARTICLES
// ============================================================
var _new_count = 0;
for (var i = 0; i < part_count; i++) {
	part_life[i]--;
	if (part_life[i] > 0) {
		part_px[i] += part_vx[i];
		part_py[i] += part_vy[i];
		part_vx[i] *= 0.96;
		part_vy[i] *= 0.96;
		if (i != _new_count) {
			part_px[_new_count] = part_px[i];
			part_py[_new_count] = part_py[i];
			part_vx[_new_count] = part_vx[i];
			part_vy[_new_count] = part_vy[i];
			part_life[_new_count] = part_life[i];
			part_col[_new_count] = part_col[i];
		}
		_new_count++;
	}
}
part_count = _new_count;

// Update gate animations
for (var i = 0; i < gate_count; i++) {
	if (gate_anim[i] >= 0) gate_anim[i]++;
}

// Update planet animations
for (var i = 0; i < planet_count; i++) {
	planet_age[i]++;
}

// Update popup
if (popup_timer > 0) {
	popup_timer--;
	popup_y -= 0.5;
}
