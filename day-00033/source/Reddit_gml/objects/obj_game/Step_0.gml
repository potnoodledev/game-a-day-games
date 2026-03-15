
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

// === TOUCH INPUT ===
if (mouse_check_button(mb_left)) {
	touch_active = true;
	touch_x = device_mouse_x_to_gui(0);
	touch_y = device_mouse_y_to_gui(0);

	// Spawn ripple every few frames while touching
	ripple_interval++;
	if (ripple_interval >= 6) {
		ripple_interval = 0;
		ripple_x[ripple_next] = touch_x;
		ripple_y[ripple_next] = touch_y;
		ripple_age[ripple_next] = 0;
		ripple_next = (ripple_next + 1) mod max_ripples;
	}
} else {
	touch_active = false;
	ripple_interval = 0;
}

// Update ripples
var _ri = 0;
repeat(max_ripples) {
	if (ripple_age[_ri] >= 0) {
		ripple_age[_ri]++;
		if (ripple_age[_ri] > 30) ripple_age[_ri] = -1;
	}
	_ri++;
}

// Update kill effects
var _ki = 0;
repeat(max_kill_fx) {
	if (kill_fx_age[_ki] >= 0) {
		kill_fx_age[_ki]++;
		if (kill_fx_age[_ki] > 25) kill_fx_age[_ki] = -1;
	}
	_ki++;
}

// === TITLE STATE ===
if (game_state == 0) {
	title_pulse += 0.05;

	// Spawn demo flock
	if (num_birds == 0) {
		var _cx = _w * 0.5;
		var _cy = _h * 0.5;
		var _i = 0;
		repeat(40) {
			bird_x[_i] = _cx + random_range(-100, 100);
			bird_y[_i] = _cy + random_range(-100, 100);
			bird_vx[_i] = random_range(-2, 2);
			bird_vy[_i] = random_range(-2, 2);
			bird_alive[_i] = true;
			_i++;
		}
		num_birds = 40;
	}

	// Update demo boids (simplified)
	var _i = 0;
	repeat(num_birds) {
		if (bird_alive[_i]) {
			// Simple cohesion toward center
			var _cx = _w * 0.5;
			var _cy = _h * 0.5;
			var _dx = _cx - bird_x[_i];
			var _dy = _cy - bird_y[_i];
			var _dist = sqrt(_dx * _dx + _dy * _dy);
			if (_dist > 1) {
				bird_vx[_i] += (_dx / _dist) * 0.1;
				bird_vy[_i] += (_dy / _dist) * 0.1;
			}

			// Separation from neighbors
			var _j = 0;
			repeat(num_birds) {
				if (_j != _i && bird_alive[_j]) {
					var _sx = bird_x[_i] - bird_x[_j];
					var _sy = bird_y[_i] - bird_y[_j];
					var _sd = sqrt(_sx * _sx + _sy * _sy);
					if (_sd < 20 && _sd > 0) {
						bird_vx[_i] += (_sx / _sd) * 0.5;
						bird_vy[_i] += (_sy / _sd) * 0.5;
					}
				}
				_j++;
			}

			// Random drift
			bird_vx[_i] += random_range(-0.1, 0.1);
			bird_vy[_i] += random_range(-0.1, 0.1);

			// Clamp speed
			var _spd = sqrt(bird_vx[_i] * bird_vx[_i] + bird_vy[_i] * bird_vy[_i]);
			if (_spd > 3) {
				bird_vx[_i] = (bird_vx[_i] / _spd) * 3;
				bird_vy[_i] = (bird_vy[_i] / _spd) * 3;
			}

			bird_x[_i] += bird_vx[_i];
			bird_y[_i] += bird_vy[_i];
		}
		_i++;
	}

	// Tap to start
	if (touch_active) {
		game_state = 1;
		state_timer = 0;
		difficulty_timer = 0;
		birds_lost = 0;
		birds_collected = 0;
		best_flock = 0;

		// Reset birds around touch point
		num_birds = 0;
		var _bi = 0;
		repeat(max_birds) {
			bird_alive[_bi] = false;
			_bi++;
		}

		// Spawn starting flock
		_bi = 0;
		repeat(30) {
			bird_x[_bi] = touch_x + random_range(-40, 40);
			bird_y[_bi] = touch_y + random_range(-40, 40);
			bird_vx[_bi] = random_range(-1.5, 1.5);
			bird_vy[_bi] = random_range(-1.5, 1.5);
			bird_alive[_bi] = true;
			_bi++;
		}
		num_birds = 30;
		best_flock = 30;

		// Reset hawks
		num_hawks = 0;
		var _hi = 0;
		repeat(max_hawks) {
			hawk_alive[_hi] = false;
			_hi++;
		}

		stray_timer = 0;
		next_hawk_spawn = 360;
		hawk_spawn_interval = 300;
		hawk_speed_ramp = 0;
		game_timer = game_timer_max;
		var _hri = 0;
		repeat(max_hawks) { hawk_speed_cur[_hri] = 0; _hri++; }
		score_display = 0;
	}
	exit;
}

// === GAME OVER STATE ===
if (game_state == 2) {
	state_timer++;

	// Tap to restart after delay
	if (state_timer > 60 && touch_active) {
		game_state = 0;
		num_birds = 0;
		num_hawks = 0;
		var _bi = 0;
		repeat(max_birds) { bird_alive[_bi] = false; _bi++; }
		var _hi = 0;
		repeat(max_hawks) { hawk_alive[_hi] = false; _hi++; }
	}
	exit;
}

// === PLAYING STATE ===
state_timer++;
difficulty_timer++;
game_timer--;

// Time's up — survived!
if (game_timer <= 0 && game_state == 1) {
	game_state = 2;
	state_timer = 0;
	// Count alive birds for final score
	var _alive_final = 0;
	var _fi = 0;
	repeat(num_birds) { if (bird_alive[_fi]) _alive_final++; _fi++; }
	best_flock = max(best_flock, _alive_final);
	points = max(points, best_flock);
	api_submit_score(points, undefined);
}

// --- Difficulty scaling ---
// Progress through 60s: 0.0 → 1.0
var _progress = 1 - (game_timer / game_timer_max);
// Hawks get globally faster: +4 speed over the full game
hawk_speed_ramp = _progress * 4.0;

if (difficulty_timer >= next_hawk_spawn) {
	// Spawn a hawk from random edge
	var _slot = -1;
	var _hi = 0;
	repeat(max_hawks) {
		if (!hawk_alive[_hi]) { _slot = _hi; break; }
		_hi++;
	}

	if (_slot >= 0) {
		var _side = irandom(3);
		if (_side == 0) { hawk_x[_slot] = -30; hawk_y[_slot] = random(_h); }
		else if (_side == 1) { hawk_x[_slot] = _w + 30; hawk_y[_slot] = random(_h); }
		else if (_side == 2) { hawk_x[_slot] = random(_w); hawk_y[_slot] = -30; }
		else { hawk_x[_slot] = random(_w); hawk_y[_slot] = _h + 30; }

		// Start with a small initial velocity toward center
		var _tox = (_w * 0.5) - hawk_x[_slot];
		var _toy = (_h * 0.5) - hawk_y[_slot];
		var _tod = sqrt(_tox * _tox + _toy * _toy);
		if (_tod > 0) { hawk_vx[_slot] = (_tox / _tod) * 0.5; hawk_vy[_slot] = (_toy / _tod) * 0.5; }
		else { hawk_vx[_slot] = 0; hawk_vy[_slot] = 0; }
		hawk_alive[_slot] = true;
		hawk_target[_slot] = -1;
		hawk_kills[_slot] = 0;
		hawk_speed_cur[_slot] = 0.5;
		num_hawks++;
	}

	// Spawn faster over time: 300 → 45 frames (5s → 0.75s)
	hawk_spawn_interval = max(45, hawk_spawn_interval - 30);
	next_hawk_spawn = difficulty_timer + hawk_spawn_interval;
}

// Decrease stray interval over time (more strays = more to collect)
stray_interval = max(40, 90 - floor(state_timer / 300) * 5);

// --- Spawn stray birds ---
stray_timer++;
if (stray_timer >= stray_interval) {
	stray_timer = 0;

	// Find empty slot
	var _slot = -1;
	var _bi = 0;
	repeat(max_birds) {
		if (!bird_alive[_bi]) { _slot = _bi; break; }
		_bi++;
	}

	if (_slot >= 0) {
		var _side = irandom(3);
		if (_side == 0) { bird_x[_slot] = -10; bird_y[_slot] = random(_h); bird_vx[_slot] = random_range(1, 2); bird_vy[_slot] = random_range(-1, 1); }
		else if (_side == 1) { bird_x[_slot] = _w + 10; bird_y[_slot] = random(_h); bird_vx[_slot] = random_range(-2, -1); bird_vy[_slot] = random_range(-1, 1); }
		else if (_side == 2) { bird_x[_slot] = random(_w); bird_y[_slot] = -10; bird_vx[_slot] = random_range(-1, 1); bird_vy[_slot] = random_range(1, 2); }
		else { bird_x[_slot] = random(_w); bird_y[_slot] = _h + 10; bird_vx[_slot] = random_range(-1, 1); bird_vy[_slot] = random_range(-2, -1); }
		bird_alive[_slot] = true;
		if (_slot >= num_birds) num_birds = _slot + 1;
	}
}

// === BOIDS UPDATE ===
// First, compute flock center for cohesion
var _flock_cx = 0;
var _flock_cy = 0;
var _flock_count = 0;
var _i = 0;
repeat(num_birds) {
	if (bird_alive[_i]) {
		_flock_cx += bird_x[_i];
		_flock_cy += bird_y[_i];
		_flock_count++;
	}
	_i++;
}
if (_flock_count > 0) {
	_flock_cx /= _flock_count;
	_flock_cy /= _flock_count;
}

// Update each bird
_i = 0;
repeat(num_birds) {
	if (bird_alive[_i]) {
		var _bx = bird_x[_i];
		var _by = bird_y[_i];
		var _ax = 0; // acceleration
		var _ay = 0;

		// --- Separation ---
		var _sep_x = 0;
		var _sep_y = 0;
		var _j = 0;
		// Only check nearby birds (sample for performance)
		var _check_count = min(num_birds, 60);
		var _step_size = max(1, num_birds div _check_count);
		_j = 0;
		while (_j < num_birds) {
			if (_j != _i && bird_alive[_j]) {
				var _dx = _bx - bird_x[_j];
				var _dy = _by - bird_y[_j];
				var _d2 = _dx * _dx + _dy * _dy;
				if (_d2 < boid_separation_dist * boid_separation_dist && _d2 > 0) {
					var _d = sqrt(_d2);
					_sep_x += (_dx / _d) * (boid_separation_dist - _d) / boid_separation_dist;
					_sep_y += (_dy / _d) * (boid_separation_dist - _d) / boid_separation_dist;
				}
			}
			_j += _step_size;
		}
		_ax += _sep_x * boid_separation_weight;
		_ay += _sep_y * boid_separation_weight;

		// --- Alignment (match velocity of nearby birds) ---
		var _ali_vx = 0;
		var _ali_vy = 0;
		var _ali_count = 0;
		_j = 0;
		while (_j < num_birds) {
			if (_j != _i && bird_alive[_j]) {
				var _dx = _bx - bird_x[_j];
				var _dy = _by - bird_y[_j];
				var _d2 = _dx * _dx + _dy * _dy;
				if (_d2 < boid_alignment_dist * boid_alignment_dist) {
					_ali_vx += bird_vx[_j];
					_ali_vy += bird_vy[_j];
					_ali_count++;
				}
			}
			_j += _step_size;
		}
		if (_ali_count > 0) {
			_ali_vx /= _ali_count;
			_ali_vy /= _ali_count;
			_ax += (_ali_vx - bird_vx[_i]) * boid_alignment_weight * 0.1;
			_ay += (_ali_vy - bird_vy[_i]) * boid_alignment_weight * 0.1;
		}

		// --- Cohesion (steer toward flock center) ---
		var _coh_dx = _flock_cx - _bx;
		var _coh_dy = _flock_cy - _by;
		var _coh_d = sqrt(_coh_dx * _coh_dx + _coh_dy * _coh_dy);
		if (_coh_d > 1) {
			_ax += (_coh_dx / _coh_d) * boid_cohesion_weight * 0.05;
			_ay += (_coh_dy / _coh_d) * boid_cohesion_weight * 0.05;
		}

		// --- Player attraction (touch) ---
		if (touch_active) {
			var _px = touch_x - _bx;
			var _py = touch_y - _by;
			var _pd = sqrt(_px * _px + _py * _py);
			if (_pd > 5 && _pd < 300) {
				var _pf = (300 - _pd) / 300; // stronger when closer
				_ax += (_px / _pd) * boid_player_weight * _pf;
				_ay += (_py / _pd) * boid_player_weight * _pf;
			}
		}

		// --- Predator avoidance ---
		var _hi = 0;
		repeat(num_hawks) {
			if (hawk_alive[_hi]) {
				var _hx = _bx - hawk_x[_hi];
				var _hy = _by - hawk_y[_hi];
				var _hd = sqrt(_hx * _hx + _hy * _hy);
				if (_hd < 120 && _hd > 0) {
					var _hf = (120 - _hd) / 120;
					_ax += (_hx / _hd) * boid_predator_weight * _hf;
					_ay += (_hy / _hd) * boid_predator_weight * _hf;
				}
			}
			_hi++;
		}

		// --- Edge avoidance ---
		if (_bx < boid_edge_margin) _ax += boid_edge_weight * (boid_edge_margin - _bx) / boid_edge_margin;
		if (_bx > _w - boid_edge_margin) _ax -= boid_edge_weight * (_bx - (_w - boid_edge_margin)) / boid_edge_margin;
		if (_by < boid_edge_margin) _ay += boid_edge_weight * (boid_edge_margin - _by) / boid_edge_margin;
		if (_by > _h - boid_edge_margin) _ay -= boid_edge_weight * (_by - (_h - boid_edge_margin)) / boid_edge_margin;

		// --- Random jitter ---
		_ax += random_range(-0.15, 0.15);
		_ay += random_range(-0.15, 0.15);

		// Apply acceleration
		bird_vx[_i] += _ax * 0.3;
		bird_vy[_i] += _ay * 0.3;

		// Clamp speed
		var _spd = sqrt(bird_vx[_i] * bird_vx[_i] + bird_vy[_i] * bird_vy[_i]);
		if (_spd > boid_speed_max) {
			bird_vx[_i] = (bird_vx[_i] / _spd) * boid_speed_max;
			bird_vy[_i] = (bird_vy[_i] / _spd) * boid_speed_max;
		}

		// Move
		bird_x[_i] += bird_vx[_i];
		bird_y[_i] += bird_vy[_i];

		// Birds pushed off screen are lost
		if (bird_x[_i] < -20 || bird_x[_i] > _w + 20 || bird_y[_i] < -20 || bird_y[_i] > _h + 20) {
			bird_alive[_i] = false;
			birds_lost++;
			_flock_count--;
		}
	}
	_i++;
}

// === HAWKS UPDATE ===
// Hawks are FAST but heavy — they accelerate in straight lines and bleed speed on turns.
// Outmanoeuvre them with sharp direction changes.
var _hi = 0;
repeat(max_hawks) {
	if (hawk_alive[_hi]) {
		// Per-hawk top speed: base + ramp + kills bonus
		var _max_spd = hawk_top_speed + hawk_speed_ramp + hawk_kills[_hi] * 0.2;
		var _cur_spd = hawk_speed_cur[_hi];

		// Find closest bird to chase
		var _best_dist = 999999;
		var _best_bird = -1;
		var _bi = 0;
		repeat(num_birds) {
			if (bird_alive[_bi]) {
				var _dx = bird_x[_bi] - hawk_x[_hi];
				var _dy = bird_y[_bi] - hawk_y[_hi];
				var _d2 = _dx * _dx + _dy * _dy;
				if (_d2 < _best_dist) {
					_best_dist = _d2;
					_best_bird = _bi;
				}
			}
			_bi++;
		}

		hawk_target[_hi] = _best_bird;

		if (_best_bird >= 0) {
			// Desired direction toward target
			var _dx = bird_x[_best_bird] - hawk_x[_hi];
			var _dy = bird_y[_best_bird] - hawk_y[_hi];
			var _d = sqrt(_dx * _dx + _dy * _dy);

			if (_d > 0) {
				var _want_vx = _dx / _d;
				var _want_vy = _dy / _d;

				// Current direction
				var _have_vx = 0;
				var _have_vy = 0;
				if (_cur_spd > 0.1) {
					_have_vx = hawk_vx[_hi] / _cur_spd;
					_have_vy = hawk_vy[_hi] / _cur_spd;
				} else {
					_have_vx = _want_vx;
					_have_vy = _want_vy;
				}

				// How much are we turning? dot product of current vs desired direction
				var _dot = _have_vx * _want_vx + _have_vy * _want_vy;
				_dot = clamp(_dot, -1, 1);

				// Turn drag: turning hard kills speed (dot=1 means straight, dot=-1 means U-turn)
				var _turn_amount = 1 - _dot; // 0 = straight, 2 = U-turn
				var _drag = 1.0 - (_turn_amount * 0.5) * (1 - hawk_turn_drag);
				_drag = clamp(_drag, 0.5, 1.0);

				// Apply drag to current speed
				_cur_spd *= _drag;

				// Accelerate toward top speed
				_cur_spd += hawk_accel;
				if (_cur_spd > _max_spd) _cur_spd = _max_spd;

				// Steer: blend current direction toward desired
				var _steer = hawk_steer_rate + hawk_kills[_hi] * 0.003;
				_steer = min(_steer, 0.08);
				var _new_vx = _have_vx + (_want_vx - _have_vx) * _steer;
				var _new_vy = _have_vy + (_want_vy - _have_vy) * _steer;

				// Normalize direction
				var _nd = sqrt(_new_vx * _new_vx + _new_vy * _new_vy);
				if (_nd > 0) {
					_new_vx /= _nd;
					_new_vy /= _nd;
				}

				// Apply speed to direction
				hawk_vx[_hi] = _new_vx * _cur_spd;
				hawk_vy[_hi] = _new_vy * _cur_spd;
			}

			// Catch bird
			if (_d < hawk_catch_dist) {
				// Spawn kill effect at bird position
				kill_fx_x[kill_fx_next] = bird_x[_best_bird];
				kill_fx_y[kill_fx_next] = bird_y[_best_bird];
				kill_fx_age[kill_fx_next] = 0;
				kill_fx_next = (kill_fx_next + 1) mod max_kill_fx;

				bird_alive[_best_bird] = false;
				birds_lost++;
				hawk_kills[_hi]++;
				_cur_spd = min(_cur_spd + 1.0, _max_spd);
			}
		} else {
			// No birds — circle center, slow down
			_cur_spd *= 0.98;
			var _cx = _w * 0.5;
			var _cy = _h * 0.5;
			var _dx = _cx - hawk_x[_hi];
			var _dy = _cy - hawk_y[_hi];
			var _d = sqrt(_dx * _dx + _dy * _dy);
			if (_d > 1) {
				hawk_vx[_hi] += (_dx / _d) * 0.05;
				hawk_vy[_hi] += (_dy / _d) * 0.05;
			}
		}

		hawk_speed_cur[_hi] = _cur_spd;

		hawk_x[_hi] += hawk_vx[_hi];
		hawk_y[_hi] += hawk_vy[_hi];

		// Wrap to stay on screen
		if (hawk_x[_hi] < -60) hawk_x[_hi] = _w + 50;
		if (hawk_x[_hi] > _w + 60) hawk_x[_hi] = -50;
		if (hawk_y[_hi] < -60) hawk_y[_hi] = _h + 50;
		if (hawk_y[_hi] > _h + 60) hawk_y[_hi] = -50;
	}
	_hi++;
}

// === COUNT ALIVE BIRDS ===
var _alive = 0;
_i = 0;
repeat(num_birds) {
	if (bird_alive[_i]) _alive++;
	_i++;
}

if (_alive > best_flock) best_flock = _alive;

// Score = total birds in flock (updates continuously)
birds_collected = _alive;
score_display = _alive;

// Points = best flock size achieved this run
points = max(points, best_flock);

// === GAME OVER (flock wiped out) ===
if (_alive <= 0 && state_timer > 60 && game_state == 1) {
	game_state = 2;
	state_timer = 0;
	api_submit_score(points, undefined);
}
