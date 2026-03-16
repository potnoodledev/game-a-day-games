
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

// === TOUCH ===
var _cur_touch = mouse_check_button(mb_left);
touch_pressed = (_cur_touch && !prev_touch);
touch_released = (!_cur_touch && prev_touch);
prev_touch = _cur_touch;

var _tx = device_mouse_x_to_gui(0);
var _ty = device_mouse_y_to_gui(0);

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

// === TITLE STATE ===
if (game_state == 0) {
	title_pulse += 0.05;

	if (touch_pressed) {
		game_state = 1;
		state_timer = 0;
		game_timer = game_timer_max;
		quake_number = 0;
		next_quake = 360;
		quake_interval = 600;
		quake_active = false;
		fault_width = 0.3;
		build_selection = 1;
		population = 0;
		income = 0;
		income_timer = 0;
		income_accumulated = 0;
		warning_timer = 0;
		aftershock_queue = 0;

		// Clear grid
		var _gi = 0;
		repeat(grid_cols * grid_rows) {
			grid_type[_gi] = 0;
			grid_hp[_gi] = 0;
			grid_hp_max[_gi] = 0;
			grid_braced[_gi] = false;
			grid_flash[_gi] = 0;
			grid_shake_x[_gi] = 0;
			grid_shake_y[_gi] = 0;
			repair_flash[_gi] = 0;
			grid_upgrade_ready[_gi] = false;
			_gi++;
		}

		// Starter houses on corners
		grid_type[0] = 1; grid_hp[0] = 3; grid_hp_max[0] = 3;
		grid_type[6] = 1; grid_hp[6] = 3; grid_hp_max[6] = 3;
		grid_type[28] = 1; grid_hp[28] = 3; grid_hp_max[28] = 3;
		grid_type[34] = 1; grid_hp[34] = 3; grid_hp_max[34] = 3;
	}
	exit;
}

// === GAME OVER ===
if (game_state == 2) {
	state_timer++;
	if (state_timer > 60 && touch_pressed) {
		game_state = 0;
	}
	exit;
}

// === PLAYING ===
state_timer++;
game_timer--;

// Update FX: ripples
var _ri = 0;
repeat(max_ripples) {
	if (ripple_age[_ri] >= 0) {
		ripple_age[_ri]++;
		if (ripple_age[_ri] > 20) ripple_age[_ri] = -1;
	}
	_ri++;
}

// Update FX: debris
var _di = 0;
repeat(max_debris) {
	if (debris_age[_di] >= 0) {
		debris_x[_di] += debris_vx[_di];
		debris_y[_di] += debris_vy[_di];
		debris_vy[_di] += 0.3;
		debris_age[_di]++;
		if (debris_age[_di] > 40) debris_age[_di] = -1;
	}
	_di++;
}

// Update FX: cracks
var _ci = 0;
repeat(max_cracks) {
	if (crack_age[_ci] >= 0) {
		crack_age[_ci]++;
		if (crack_age[_ci] > 120) crack_age[_ci] = -1;
	}
	_ci++;
}

// Update FX: float text
var _fi = 0;
repeat(max_floats) {
	if (float_age[_fi] >= 0) {
		float_y[_fi] -= 0.8;
		float_age[_fi]++;
		if (float_age[_fi] > 50) float_age[_fi] = -1;
	}
	_fi++;
}

// Decay building shake + flashes
var _gi = 0;
repeat(grid_cols * grid_rows) {
	grid_shake_x[_gi] *= 0.85;
	grid_shake_y[_gi] *= 0.85;
	if (grid_flash[_gi] > 0) grid_flash[_gi]--;
	if (repair_flash[_gi] > 0) repair_flash[_gi]--;
	// Upgrade ready indicator
	grid_upgrade_ready[_gi] = (grid_type[_gi] > 0 && grid_type[_gi] < 3 && grid_hp[_gi] >= grid_hp_max[_gi]);
	_gi++;
}

// === DIFFICULTY ===
var _progress = 1 - (game_timer / game_timer_max);
fault_width = 0.3 + _progress * 1.2;

// === EARTHQUAKE WARNING ===
var _time_to_quake = next_quake - state_timer;
if (_time_to_quake > 0 && _time_to_quake < 120 && !quake_active) {
	warning_timer++;
} else if (!quake_active) {
	warning_timer = 0;
}

// === TRIGGER EARTHQUAKE (or aftershock) ===
var _should_trigger = false;
var _is_aftershock = false;

if (state_timer >= next_quake && !quake_active) {
	_should_trigger = true;
} else if (aftershock_queue > 0 && !quake_active) {
	aftershock_timer--;
	if (aftershock_timer <= 0) {
		_should_trigger = true;
		_is_aftershock = true;
	}
}

if (_should_trigger) {
	quake_active = true;
	quake_timer = 0;
	quake_wave_x = -0.5;

	if (_is_aftershock) {
		// Aftershock: shorter, weaker, random epicenter near main
		aftershock_queue--;
		quake_intensity = aftershock_intensity * random_range(0.4, 0.7);
		quake_duration = 40 + irandom(20);
		quake_epicenter_col = clamp(quake_epicenter_col + irandom_range(-2, 2), 0, grid_cols - 1);
	} else {
		// Main quake
		quake_number++;
		quake_intensity = min(1.0, 0.3 + quake_number * 0.12);
		quake_duration = 60 + quake_number * 15;
		quake_duration = min(quake_duration, 150);
		quake_epicenter_col = irandom(grid_cols - 1);

		// Queue aftershocks (more for stronger quakes)
		if (quake_intensity >= 0.5) {
			aftershock_queue = 1 + floor((quake_intensity - 0.5) * 4);
			aftershock_queue = min(aftershock_queue, 3);
			aftershock_intensity = quake_intensity;
		}
	}

	// Set warning direction for NEXT quake
	quake_warning_dir = sign(quake_epicenter_col - fault_col);
	if (quake_warning_dir == 0) quake_warning_dir = choose(-1, 1);

	// Clear braces
	_gi = 0;
	repeat(grid_cols * grid_rows) {
		grid_braced[_gi] = false;
		_gi++;
	}
	brace_target = -1;
}

// === EARTHQUAKE UPDATE ===
if (quake_active) {
	quake_timer++;

	// Seismic wave sweeps across
	quake_wave_x += quake_wave_speed / 60;

	// Screen shake
	var _shake_amt = quake_intensity * 8 * (1 - quake_timer / quake_duration);
	quake_shake_x = random_range(-_shake_amt, _shake_amt);
	quake_shake_y = random_range(-_shake_amt, _shake_amt);

	// Damage buildings as wave passes
	_gi = 0;
	repeat(grid_cols * grid_rows) {
		var _col = _gi mod grid_cols;
		var _row = _gi div grid_cols;

		if (grid_type[_gi] > 0) {
			var _wave_col = quake_wave_x * grid_cols;
			if (abs(_col - _wave_col) < 0.6) {
				var _epi_dist = abs(_col - quake_epicenter_col);
				var _fault_dist = abs(_col - fault_col);

				var _dmg_chance = quake_intensity * 0.4;
				_dmg_chance += (1 - _epi_dist / grid_cols) * 0.3;
				_dmg_chance += max(0, 1 - _fault_dist / 2) * 0.3;

				if (grid_braced[_gi]) _dmg_chance *= 0.25;

				if (random(1) < _dmg_chance) {
					grid_hp[_gi]--;
					grid_flash[_gi] = 15;
					grid_shake_x[_gi] = random_range(-6, 6);
					grid_shake_y[_gi] = random_range(-4, 4);

					// Debris
					var _bx = _grid_x + _col * _cell + _cell * 0.5;
					var _by = _grid_y + _row * _cell + _cell * 0.5;
					var _dbi = 0;
					repeat(3) {
						debris_x[debris_next] = _bx + random_range(-_cell * 0.3, _cell * 0.3);
						debris_y[debris_next] = _by;
						debris_vx[debris_next] = random_range(-3, 3);
						debris_vy[debris_next] = random_range(-5, -1);
						debris_age[debris_next] = 0;
						debris_col[debris_next] = make_colour_rgb(140 + irandom(60), 120 + irandom(40), 100 + irandom(30));
						debris_next = (debris_next + 1) mod max_debris;
						_dbi++;
					}

					// Destroyed
					if (grid_hp[_gi] <= 0) {
						grid_type[_gi] = 0;
						grid_hp[_gi] = 0;
						grid_hp_max[_gi] = 0;

						var _dbi2 = 0;
						repeat(6) {
							debris_x[debris_next] = _bx + random_range(-_cell * 0.4, _cell * 0.4);
							debris_y[debris_next] = _by + random_range(-_cell * 0.3, _cell * 0.3);
							debris_vx[debris_next] = random_range(-4, 4);
							debris_vy[debris_next] = random_range(-7, -2);
							debris_age[debris_next] = 0;
							debris_col[debris_next] = make_colour_rgb(180 + irandom(40), 80 + irandom(40), 40 + irandom(30));
							debris_next = (debris_next + 1) mod max_debris;
							_dbi2++;
						}

						crack_x1[crack_next] = _bx + random_range(-_cell * 0.5, 0);
						crack_y1[crack_next] = _by + random_range(-_cell * 0.3, _cell * 0.3);
						crack_x2[crack_next] = _bx + random_range(0, _cell * 0.5);
						crack_y2[crack_next] = _by + random_range(-_cell * 0.3, _cell * 0.3);
						crack_age[crack_next] = 0;
						crack_next = (crack_next + 1) mod max_cracks;
					}
				}
			}
		}
		_gi++;
	}

	// Fault swallows buildings during strong quakes
	if (quake_intensity > 0.5) {
		_gi = 0;
		repeat(grid_cols * grid_rows) {
			var _col = _gi mod grid_cols;
			if (grid_type[_gi] > 0) {
				var _fault_dist = abs(_col - fault_col);
				if (_fault_dist < fault_width * 0.5 && random(1) < 0.01 * quake_intensity) {
					grid_type[_gi] = 0;
					grid_hp[_gi] = 0;
					grid_hp_max[_gi] = 0;
					grid_flash[_gi] = 20;
				}
			}
			_gi++;
		}
	}

	// End earthquake
	if (quake_timer >= quake_duration) {
		quake_active = false;
		quake_shake_x = 0;
		quake_shake_y = 0;
		quake_wave_x = -1;

		// Schedule aftershock timer
		if (aftershock_queue > 0) {
			aftershock_timer = 90 + irandom(60); // 1.5-2.5 sec delay
		}

		// Schedule next main quake (only if no aftershocks pending)
		if (aftershock_queue <= 0) {
			quake_interval = max(240, quake_interval - 60);
			next_quake = state_timer + quake_interval;

			// Pre-determine next epicenter direction for warning
			var _next_epi = irandom(grid_cols - 1);
			quake_warning_dir = sign(_next_epi - fault_col);
			if (quake_warning_dir == 0) quake_warning_dir = choose(-1, 1);
		}
	}
}

// === TOUCH HANDLING ===
if (touch_pressed) {
	// Spawn ripple
	ripple_x[ripple_next] = _tx;
	ripple_y[ripple_next] = _ty;
	ripple_age[ripple_next] = 0;
	ripple_next = (ripple_next + 1) mod max_ripples;

	// Check grid tap
	var _gcol = floor((_tx - _grid_x) / _cell);
	var _grow = floor((_ty - _grid_y) / _cell);

	if (_gcol >= 0 && _gcol < grid_cols && _grow >= 0 && _grow < grid_rows) {
		var _idx = _grow * grid_cols + _gcol;

		if (quake_active) {
			// During quake: BRACE
			if (grid_type[_idx] > 0 && grid_hp[_idx] > 0) {
				if (brace_target >= 0) grid_braced[brace_target] = false;
				brace_target = _idx;
				grid_braced[_idx] = true;
			}
		} else {
			if (grid_type[_idx] == 0) {
				// Place building
				grid_type[_idx] = build_selection;
				grid_hp[_idx] = build_hp[build_selection];
				grid_hp_max[_idx] = build_hp[build_selection];
				grid_flash[_idx] = 0;
				repair_flash[_idx] = 10;
			} else if (grid_hp[_idx] < grid_hp_max[_idx]) {
				// Repair
				grid_hp[_idx] = min(grid_hp[_idx] + 1, grid_hp_max[_idx]);
				repair_flash[_idx] = 10;
			} else if (grid_type[_idx] < 3) {
				// Upgrade
				var _new_type = grid_type[_idx] + 1;
				grid_type[_idx] = _new_type;
				grid_hp[_idx] = build_hp[_new_type];
				grid_hp_max[_idx] = build_hp[_new_type];
				repair_flash[_idx] = 10;
			}
		}
	}

	// Build selector buttons
	var _btn_w = min(80, _w / 4);
	var _btn_h = 40;
	var _btn_y = _h - _bot_bar + 10;
	var _btn_start_x = (_w - _btn_w * 3 - 10 * 2) * 0.5;

	var _bi = 1;
	repeat(3) {
		var _bx = _btn_start_x + (_bi - 1) * (_btn_w + 10);
		if (_tx >= _bx && _tx <= _bx + _btn_w && _ty >= _btn_y && _ty <= _btn_y + _btn_h) {
			build_selection = _bi;
		}
		_bi++;
	}
}

// === COMPUTE POPULATION + INCOME ===
population = 0;
income = 0;
_gi = 0;
repeat(grid_cols * grid_rows) {
	if (grid_type[_gi] > 0 && grid_hp[_gi] > 0) {
		var _col = _gi mod grid_cols;
		var _val = build_value[grid_type[_gi]];
		var _hp_ratio = grid_hp[_gi] / max(1, grid_hp_max[_gi]);
		var _mult = fault_mult[_col];
		var _effective = ceil(_val * _hp_ratio * _mult);
		population += _effective;
		income += _effective;
	}
	_gi++;
}

// Income tick: every 60 frames (1 sec), add population to score
income_timer++;
if (income_timer >= 60) {
	income_timer = 0;
	if (income > 0) {
		income_accumulated += income;
		points = max(points, income_accumulated);

		// Float text showing income earned
		float_x[float_next] = _w * 0.5;
		float_y[float_next] = _grid_y - 5;
		float_text[float_next] = "+" + string(income);
		float_age[float_next] = 0;
		float_next = (float_next + 1) mod max_floats;
	}
}

// === GAME OVER ===
if (game_timer <= 0 && game_state == 1) {
	game_state = 2;
	state_timer = 0;
	points = max(points, income_accumulated);
	api_submit_score(points, undefined);
}
