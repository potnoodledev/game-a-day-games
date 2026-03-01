
// ============================================================
// STEP 0 — Tile-to-tile movement model
// ============================================================
// pac_gx/gy = cell we're at (progress=0) or departing from (progress>0)
// pac_progress = 0..1 how far toward the NEXT cell in pac_dir
// Rendering: screen_x = (gx + dx*progress + 0.5) * cell_size + offset
// At progress=0: we're at cell center → direction decisions + dot eating
// At progress>=1: arrive at next cell → advance gx/gy, reset progress=0

var _w = window_get_width();
var _h = window_get_height();
if (_w < 1 || _h < 1) exit;

var _margin_top = 60;
var _margin_bottom = 20;
cell_size = min((_w - 20) / MAZE_W, (_h - _margin_top - _margin_bottom) / MAZE_H);
cell_size = floor(cell_size);
if (cell_size < 4) cell_size = 4;
maze_offset_x = floor((_w - MAZE_W * cell_size) * 0.5);
maze_offset_y = _margin_top;

// ============================================================
// STATE: LOADING (0) — Generate maze
// ============================================================
if (game_state == 0) {
	var _mw = MAZE_W;
	var _mh = MAZE_H;

	for (var _i = 0; _i < _mw * _mh; _i++) { maze[_i] = 0; dots[_i] = 0; }

	// Cells at odd positions
	var _cw = _mw div 2; // 5
	var _ch = _mh div 2; // 7
	var _tc = _cw * _ch;

	for (var _cy = 0; _cy < _ch; _cy++) {
		for (var _cx = 0; _cx < _cw; _cx++) {
			maze[(_cy * 2 + 1) * _mw + (_cx * 2 + 1)] = 1;
		}
	}

	// Recursive backtracker
	var _sx = array_create(_tc, 0);
	var _sy = array_create(_tc, 0);
	var _st = 0;
	var _vis = array_create(_tc, false);
	var _scx = _cw div 2;
	var _scy = _ch - 1;
	_vis[_scy * _cw + _scx] = true;
	_sx[0] = _scx; _sy[0] = _scy; _st = 1;
	var _vc = 1;

	while (_vc < _tc && _st > 0) {
		var _cx = _sx[_st - 1];
		var _cy = _sy[_st - 1];
		var _nx = array_create(4, 0);
		var _ny = array_create(4, 0);
		var _nc = 0;
		if (_cx + 1 < _cw && !_vis[_cy * _cw + (_cx + 1)]) { _nx[_nc] = _cx + 1; _ny[_nc] = _cy; _nc++; }
		if (_cx - 1 >= 0 && !_vis[_cy * _cw + (_cx - 1)]) { _nx[_nc] = _cx - 1; _ny[_nc] = _cy; _nc++; }
		if (_cy + 1 < _ch && !_vis[(_cy + 1) * _cw + _cx]) { _nx[_nc] = _cx; _ny[_nc] = _cy + 1; _nc++; }
		if (_cy - 1 >= 0 && !_vis[(_cy - 1) * _cw + _cx]) { _nx[_nc] = _cx; _ny[_nc] = _cy - 1; _nc++; }
		if (_nc > 0) {
			var _p = irandom(_nc - 1);
			var _nnx = _nx[_p];
			var _nny = _ny[_p];
			maze[(_cy * 2 + 1 + (_nny - _cy)) * _mw + (_cx * 2 + 1 + (_nnx - _cx))] = 1;
			_vis[_nny * _cw + _nnx] = true;
			_vc++;
			_sx[_st] = _nnx; _sy[_st] = _nny; _st++;
		} else {
			_st--;
		}
	}

	// Break extra walls
	for (var _extra = 0; _extra < 15; _extra++) {
		var _rx = irandom_range(1, _mw - 2);
		var _ry = irandom_range(1, _mh - 2);
		if (maze[_ry * _mw + _rx] == 0) {
			var _adj = 0;
			if (_rx > 0 && maze[_ry * _mw + (_rx - 1)] == 1) _adj++;
			if (_rx < _mw - 1 && maze[_ry * _mw + (_rx + 1)] == 1) _adj++;
			if (_ry > 0 && maze[(_ry - 1) * _mw + _rx] == 1) _adj++;
			if (_ry < _mh - 1 && maze[(_ry + 1) * _mw + _rx] == 1) _adj++;
			if (_adj >= 2) maze[_ry * _mw + _rx] = 1;
		}
	}

	// Force-open player start + ghost pen
	pac_gx = _mw div 2;
	pac_gy = _mh - 2;
	maze[pac_gy * _mw + pac_gx] = 1;
	if (pac_gx > 0) maze[pac_gy * _mw + (pac_gx - 1)] = 1;
	if (pac_gx < _mw - 1) maze[pac_gy * _mw + (pac_gx + 1)] = 1;
	if (pac_gy > 0) maze[(pac_gy - 1) * _mw + pac_gx] = 1;

	var _pen_x = _mw div 2;
	var _pen_y = 1;
	maze[_pen_y * _mw + _pen_x] = 1;
	if (_pen_x > 0) maze[_pen_y * _mw + (_pen_x - 1)] = 1;
	if (_pen_x < _mw - 1) maze[_pen_y * _mw + (_pen_x + 1)] = 1;
	if (_pen_y + 1 < _mh) maze[(_pen_y + 1) * _mw + _pen_x] = 1;

	// Place dots
	total_dots = 0; dots_eaten = 0;
	for (var _i = 0; _i < _mw * _mh; _i++) {
		dots[_i] = 0;
		if (maze[_i] == 1) {
			var _ddx = _i mod _mw;
			var _ddy = _i div _mw;
			if (_ddx == pac_gx && _ddy == pac_gy) continue;
			if (_ddx == _pen_x && _ddy >= _pen_y && _ddy <= _pen_y + 1) continue;
			dots[_i] = 1; total_dots++;
		}
	}

	// Power pellets
	var _num_pp = max(2, 4 - (round_num div 3));
	var _placed = 0; var _att = 0;
	while (_placed < _num_pp && _att < 100) {
		var _pi = irandom_range(0, _mw * _mh - 1);
		if (dots[_pi] == 1) {
			var _ppx = _pi mod _mw; var _ppy = _pi div _mw;
			if (_ppx <= 2 || _ppx >= _mw - 3 || _ppy <= 2 || _ppy >= _mh - 3 || _att > 50) {
				dots[_pi] = 2; _placed++;
			}
		}
		_att++;
	}
	_placed = 0; _att = 0;
	while (_placed < 1 && _att < 100) { var _si = irandom(_mw * _mh - 1); if (dots[_si] == 1) { dots[_si] = 3; _placed++; } _att++; }
	_placed = 0; _att = 0;
	while (_placed < 1 && _att < 100) { var _fi = irandom(_mw * _mh - 1); if (dots[_fi] == 1) { dots[_fi] = 4; _placed++; } _att++; }

	// Init player
	pac_progress = 0;
	pac_dir = 0;
	pac_next_dir = -1;
	pac_moving = false;

	// Init ghosts
	num_ghosts = min(MAX_GHOSTS, 1 + round_num);
	for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
		ghost_active[_gi] = (_gi < num_ghosts);
		ghost_type[_gi] = _gi;
		ghost_state[_gi] = 1;
		ghost_gx[_gi] = _pen_x;
		ghost_gy[_gi] = _pen_y;
		ghost_progress[_gi] = 0;
		ghost_dir[_gi] = 3; // start moving down out of pen
		ghost_spawn_timer[_gi] = _gi * 120;
	}

	chase_phase_index = 0; chase_phase = 0;
	chase_timer = chase_durations[0];
	fright_timer = 0; speed_boost_timer = 0; freeze_timer = 0;
	ghost_eat_combo = 0; wall_phase_count = wall_phase_max;
	ghost_speed_mult = max(0.5, 1.0 + (round_num - 1) * 0.05 - ghost_slow_bonus);

	game_state = 1;
	exit;
}

// ============================================================
// STATE: PLAYING (1)
// ============================================================
if (game_state == 1) {

	// --- INPUT ---
	if (mouse_check_button_pressed(mb_left)) {
		touch_start_x = device_mouse_x_to_gui(0);
		touch_start_y = device_mouse_y_to_gui(0);
		touch_active = true;
	}
	if (mouse_check_button_released(mb_left) && touch_active) {
		var _ex = device_mouse_x_to_gui(0);
		var _ey = device_mouse_y_to_gui(0);
		var _sdx = _ex - touch_start_x;
		var _sdy = _ey - touch_start_y;
		if (abs(_sdx) > SWIPE_THRESHOLD || abs(_sdy) > SWIPE_THRESHOLD) {
			if (abs(_sdx) > abs(_sdy)) pac_next_dir = (_sdx > 0) ? 0 : 2;
			else pac_next_dir = (_sdy > 0) ? 3 : 1;
		}
		touch_active = false;
	}
	if (keyboard_check_pressed(vk_right)) pac_next_dir = 0;
	if (keyboard_check_pressed(vk_up)) pac_next_dir = 1;
	if (keyboard_check_pressed(vk_left)) pac_next_dir = 2;
	if (keyboard_check_pressed(vk_down)) pac_next_dir = 3;

	// --- PLAYER MOVEMENT (tile-to-tile) ---
	var _pspeed = 0.08 * pac_speed_mult;
	if (speed_boost_timer > 0) _pspeed *= 1.5;

	// At cell center (progress == 0): decide direction, eat dot
	if (pac_progress == 0) {
		// Eat dot at current cell
		var _dot_idx = pac_gy * MAZE_W + pac_gx;
		if (dots[_dot_idx] > 0) {
			var _dt = dots[_dot_idx];
			dots[_dot_idx] = 0;
			if (_dt == 1) { points += 10; dots_eaten++; }
			else if (_dt == 2) {
				points += 50; dots_eaten++;
				fright_timer = fright_duration_base + fright_duration_bonus;
				ghost_eat_combo = 0;
				for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
					if (ghost_active[_gi] && ghost_state[_gi] != 3) {
						ghost_state[_gi] = 2;
						ghost_dir[_gi] = (ghost_dir[_gi] + 2) mod 4;
						ghost_progress[_gi] = 0; // snap frightened ghosts to cell
					}
				}
			}
			else if (_dt == 3) { points += 30; dots_eaten++; speed_boost_timer = 240; }
			else if (_dt == 4) { points += 30; dots_eaten++; freeze_timer = 180; }
		}

		// Magnet
		if (magnet_range > 0) {
			for (var _mdx = -magnet_range; _mdx <= magnet_range; _mdx++) {
				for (var _mdy = -magnet_range; _mdy <= magnet_range; _mdy++) {
					if (_mdx == 0 && _mdy == 0) continue;
					var _mgx = pac_gx + _mdx;
					var _mgy = pac_gy + _mdy;
					if (_mgx >= 0 && _mgx < MAZE_W && _mgy >= 0 && _mgy < MAZE_H) {
						var _mi = _mgy * MAZE_W + _mgx;
						if (dots[_mi] == 1) { dots[_mi] = 0; points += 10; dots_eaten++; }
					}
				}
			}
		}

		// Try buffered direction first
		if (pac_next_dir >= 0) {
			var _try_gx = pac_gx + dir_dx[pac_next_dir];
			var _try_gy = pac_gy + dir_dy[pac_next_dir];
			if (_try_gx >= 0 && _try_gx < MAZE_W && _try_gy >= 0 && _try_gy < MAZE_H && maze[_try_gy * MAZE_W + _try_gx] == 1) {
				pac_dir = pac_next_dir;
				pac_next_dir = -1;
				pac_moving = true;
			}
		}

		// Check if can continue in current direction
		if (pac_moving) {
			var _fwd_gx = pac_gx + dir_dx[pac_dir];
			var _fwd_gy = pac_gy + dir_dy[pac_dir];
			if (_fwd_gx < 0 || _fwd_gx >= MAZE_W || _fwd_gy < 0 || _fwd_gy >= MAZE_H || maze[_fwd_gy * MAZE_W + _fwd_gx] != 1) {
				pac_moving = false;
			}
		}
	}

	// Advance progress
	if (pac_moving) {
		pac_progress += _pspeed;

		// Arrived at next cell?
		if (pac_progress >= 1.0) {
			pac_gx += dir_dx[pac_dir];
			pac_gy += dir_dy[pac_dir];
			pac_progress = 0; // exactly at new cell center
			// Direction logic + dot eating will happen next frame (or this frame via the check above)
			// Actually, we already moved gx/gy. Let's handle the new cell immediately:
			// We'll loop back to progress==0 logic next frame. That's fine — one frame delay is imperceptible.
		}
	}

	// Mouth animation
	pac_mouth_angle += pac_mouth_dir * 3;
	if (pac_mouth_angle > 35) { pac_mouth_angle = 35; pac_mouth_dir = -1; }
	if (pac_mouth_angle < 5) { pac_mouth_angle = 5; pac_mouth_dir = 1; }

	// --- POWER-UP TIMERS ---
	if (fright_timer > 0) {
		fright_timer--;
		if (fright_timer <= 0) {
			for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
				if (ghost_active[_gi] && ghost_state[_gi] == 2) ghost_state[_gi] = chase_phase;
			}
			ghost_eat_combo = 0;
		}
	}
	if (speed_boost_timer > 0) speed_boost_timer--;
	if (freeze_timer > 0) freeze_timer--;

	// --- CHASE/SCATTER ---
	if (fright_timer <= 0) {
		chase_timer--;
		if (chase_timer <= 0) {
			chase_phase_index = min(chase_phase_index + 1, array_length(chase_durations) - 1);
			chase_phase = chase_phase_index mod 2;
			chase_timer = chase_durations[chase_phase_index];
			for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
				if (ghost_active[_gi] && ghost_state[_gi] < 2) {
					ghost_state[_gi] = chase_phase;
					ghost_dir[_gi] = (ghost_dir[_gi] + 2) mod 4;
					ghost_progress[_gi] = 0;
				}
			}
		}
	}

	// --- GHOST AI (tile-to-tile) ---
	for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
		if (!ghost_active[_gi]) continue;
		if (ghost_spawn_timer[_gi] > 0) { ghost_spawn_timer[_gi]--; continue; }

		var _gspeed = 0.06 * ghost_speed_mult;
		if (ghost_state[_gi] == 2) _gspeed *= 0.6;
		if (ghost_state[_gi] == 3) _gspeed *= 1.5;

		var _can_move = (freeze_timer <= 0 || ghost_state[_gi] == 3);

		if (_can_move) {
			// At cell center: choose direction
			if (ghost_progress[_gi] == 0) {
				var _tx = pac_gx;
				var _ty = pac_gy;

				if (ghost_state[_gi] == 0) {
					if (ghost_type[_gi] == 0) { _tx = pac_gx; _ty = pac_gy; }
					else if (ghost_type[_gi] == 1) { _tx = pac_gx + dir_dx[pac_dir] * 4; _ty = pac_gy + dir_dy[pac_dir] * 4; }
					else if (ghost_type[_gi] == 2 && ghost_active[0]) {
						var _ax = pac_gx + dir_dx[pac_dir] * 2;
						var _ay = pac_gy + dir_dy[pac_dir] * 2;
						_tx = _ax * 2 - ghost_gx[0]; _ty = _ay * 2 - ghost_gy[0];
					} else {
						var _dp = abs(ghost_gx[_gi] - pac_gx) + abs(ghost_gy[_gi] - pac_gy);
						if (_dp < 5) { _tx = pac_gx; _ty = pac_gy; }
						else { _tx = scatter_targets_x[ghost_type[_gi]]; _ty = scatter_targets_y[ghost_type[_gi]]; }
					}
				}
				else if (ghost_state[_gi] == 1) {
					_tx = scatter_targets_x[ghost_type[_gi]]; _ty = scatter_targets_y[ghost_type[_gi]];
				}
				else if (ghost_state[_gi] == 2) {
					_tx = irandom(MAZE_W - 1); _ty = irandom(MAZE_H - 1);
				}
				else if (ghost_state[_gi] == 3) {
					_tx = MAZE_W div 2; _ty = 1;
					if (ghost_gx[_gi] == _tx && ghost_gy[_gi] == _ty) ghost_state[_gi] = chase_phase;
				}

				// Pick best direction (no reversing unless stuck)
				var _best_d = -1;
				var _best_dd = 999999;
				var _rev = (ghost_dir[_gi] + 2) mod 4;

				for (var _d = 0; _d < 4; _d++) {
					if (_d == _rev) continue;
					var _cgx = ghost_gx[_gi] + dir_dx[_d];
					var _cgy = ghost_gy[_gi] + dir_dy[_d];
					if (_cgx < 0 || _cgx >= MAZE_W || _cgy < 0 || _cgy >= MAZE_H) continue;
					if (maze[_cgy * MAZE_W + _cgx] != 1) continue;
					var _dd = abs(_cgx - _tx) + abs(_cgy - _ty);
					if (_dd < _best_dd) { _best_dd = _dd; _best_d = _d; }
				}

				// Allow reverse as last resort
				if (_best_d < 0) {
					var _rgx = ghost_gx[_gi] + dir_dx[_rev];
					var _rgy = ghost_gy[_gi] + dir_dy[_rev];
					if (_rgx >= 0 && _rgx < MAZE_W && _rgy >= 0 && _rgy < MAZE_H && maze[_rgy * MAZE_W + _rgx] == 1) {
						_best_d = _rev;
					}
				}

				if (_best_d >= 0) {
					ghost_dir[_gi] = _best_d;
				}

				// Check if chosen direction is actually open
				var _next_gx = ghost_gx[_gi] + dir_dx[ghost_dir[_gi]];
				var _next_gy = ghost_gy[_gi] + dir_dy[ghost_dir[_gi]];
				if (_next_gx < 0 || _next_gx >= MAZE_W || _next_gy < 0 || _next_gy >= MAZE_H || maze[_next_gy * MAZE_W + _next_gx] != 1) {
					// Stuck — don't move
					_gspeed = 0;
				}
			}

			// Advance ghost progress
			if (_gspeed > 0) {
				ghost_progress[_gi] += _gspeed;
				if (ghost_progress[_gi] >= 1.0) {
					ghost_gx[_gi] += dir_dx[ghost_dir[_gi]];
					ghost_gy[_gi] += dir_dy[ghost_dir[_gi]];
					ghost_progress[_gi] = 0;
				}
			}
		}

		// --- COLLISION (always, even if frozen) ---
		if (game_state != 1) break;
		if (invincible_timer > 0 || ghost_state[_gi] == 3) continue;

		// Compute world positions for collision
		var _pfx = pac_gx + dir_dx[pac_dir] * pac_progress + 0.5;
		var _pfy = pac_gy + dir_dy[pac_dir] * pac_progress + 0.5;
		var _gfx = ghost_gx[_gi] + dir_dx[ghost_dir[_gi]] * ghost_progress[_gi] + 0.5;
		var _gfy = ghost_gy[_gi] + dir_dy[ghost_dir[_gi]] * ghost_progress[_gi] + 0.5;

		var _cdist = point_distance(_pfx, _pfy, _gfx, _gfy);
		if (_cdist < 0.8) {
			if (ghost_state[_gi] == 2) {
				ghost_state[_gi] = 3;
				ghost_eat_combo++;
				var _es = 200;
				var _cm = ghost_eat_combo;
				while (_cm > 1) { _es *= 2; _cm--; }
				points += _es;
			} else {
				lives--;
				if (lives <= 0) {
					game_state = 5;
					game_over_timer = 180;
					api_submit_score(points, undefined);
					api_save_state(round_num, { points: points }, undefined);
				} else {
					game_state = 2;
					dead_timer = 90;
				}
				break;
			}
		}
	}

	if (invincible_timer > 0) invincible_timer--;

	if (dots_eaten >= floor(total_dots * 0.75) && total_dots > 0) {
		points += 500 * round_num;
		game_state = 3;
		round_clear_timer = 120;
	}
}

// ============================================================
// STATE: DEAD (2)
// ============================================================
if (game_state == 2) {
	dead_timer--;
	if (dead_timer <= 0) {
		pac_gx = MAZE_W div 2;
		pac_gy = MAZE_H - 2;
		pac_progress = 0;
		pac_dir = 0;
		pac_next_dir = -1;
		pac_moving = false;
		invincible_timer = 120;

		for (var _gi = 0; _gi < MAX_GHOSTS; _gi++) {
			ghost_gx[_gi] = MAZE_W div 2;
			ghost_gy[_gi] = 1;
			ghost_progress[_gi] = 0;
			ghost_state[_gi] = 1;
			ghost_dir[_gi] = 3;
			ghost_spawn_timer[_gi] = _gi * 90;
		}
		fright_timer = 0; speed_boost_timer = 0; freeze_timer = 0;
		game_state = 1;
	}
}

// ============================================================
// STATE: ROUND CLEAR (3)
// ============================================================
if (game_state == 3) {
	round_clear_timer--;
	if (round_clear_timer <= 0) {
		round_num++; level = round_num;
		var _p1 = irandom(5);
		upgrade_choices[0] = _p1;
		var _p2 = _p1;
		while (_p2 == _p1) { _p2 = irandom(5); }
		upgrade_choices[1] = _p2;
		upgrade_selected = -1;
		game_state = 4;
	}
}

// ============================================================
// STATE: UPGRADE SELECT (4)
// ============================================================
if (game_state == 4) {
	if (mouse_check_button_pressed(mb_left)) {
		var _mx = device_mouse_x_to_gui(0);
		var _my = device_mouse_y_to_gui(0);
		var _box_w = _w * 0.35;
		var _box_h = _h * 0.18;
		var _gap = _w * 0.05;
		var _total_w = _box_w * 2 + _gap;
		var _start_x = (_w - _total_w) * 0.5;
		var _box_y = _h * 0.5;

		for (var _ui = 0; _ui < 2; _ui++) {
			var _bx = _start_x + _ui * (_box_w + _gap);
			if (_mx >= _bx && _mx <= _bx + _box_w && _my >= _box_y && _my <= _box_y + _box_h) {
				upgrade_selected = _ui;
			}
		}
		if (upgrade_selected >= 0) {
			var _ch2 = upgrade_choices[upgrade_selected];
			if (_ch2 == 0) pac_speed_mult += 0.10;
			else if (_ch2 == 1) fright_duration_bonus += 120;
			else if (_ch2 == 2) ghost_slow_bonus += 0.10;
			else if (_ch2 == 3) magnet_range = min(magnet_range + 2, 4);
			else if (_ch2 == 4) lives++;
			else if (_ch2 == 5) wall_phase_max++;
			api_save_state(round_num, { points: points }, undefined);
			game_state = 0;
		}
	}
}

// ============================================================
// STATE: GAME OVER (5)
// ============================================================
if (game_state == 5) {
	game_over_timer--;
	if (game_over_timer <= 0 && mouse_check_button_pressed(mb_left)) {
		points = 0; lives = 3; round_num = 1; level = 0;
		pac_speed_mult = 1.0; ghost_speed_mult = 1.0; ghost_slow_bonus = 0;
		fright_duration_bonus = 0; magnet_range = 0;
		wall_phase_max = 0; wall_phase_count = 0;
		game_state = 0;
	}
}
