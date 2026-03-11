
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

// --- BIG BANG STATE ---
if (game_state == 0) {
	big_bang_timer++;
	var _cx = _w * 0.5;
	var _cy = _h * 0.5;

	// Spawn burst of dust from center on first frame
	if (big_bang_timer == 1) {
		bang_flash = 1.0;
		var _bi = 0;
		repeat (200) {
			if (array_length(dust) >= max_dust) break;
			var _angle = random(360);
			var _spd = random_range(2, 8);
			array_push(dust, {
				x: _cx + random_range(-10, 10),
				y: _cy + random_range(-10, 10),
				vx: lengthdir_x(_spd, _angle),
				vy: lengthdir_y(_spd, _angle),
				alpha: random_range(0.5, 1.0),
				size: random_range(1.5, 4.0)
			});
			_bi++;
		}
		// Spawn visual particles too
		var _ni = 0;
		repeat (40) {
			var _angle = (_ni / 40) * 360 + random(9);
			var _spd = random_range(3, 10);
			array_push(nova_particles, {
				x: _cx, y: _cy,
				vx: lengthdir_x(_spd, _angle),
				vy: lengthdir_y(_spd, _angle),
				alpha: 1.0,
				size: random_range(3, 8),
				color: merge_colour(c_white, c_yellow, random(1))
			});
			_ni++;
		}
	}

	// Fade flash
	if (bang_flash > 0) bang_flash -= 0.03;

	// Update dust during big bang (let them fly outward)
	var _dlen = array_length(dust);
	var _di = 0;
	repeat (_dlen) {
		var _d = dust[_di];
		_d.x += _d.vx;
		_d.y += _d.vy;
		_d.vx *= 0.98; // slow down
		_d.vy *= 0.98;
		_di++;
	}

	// Update nova particles
	var _nova_to_remove = [];
	var _ni = 0;
	var _nova_len = array_length(nova_particles);
	repeat (_nova_len) {
		var _np = nova_particles[_ni];
		_np.x += _np.vx;
		_np.y += _np.vy;
		_np.alpha -= 0.02;
		if (_np.alpha <= 0) array_push(_nova_to_remove, _ni);
		_ni++;
	}
	var _ri = array_length(_nova_to_remove) - 1;
	while (_ri >= 0) {
		array_delete(nova_particles, _nova_to_remove[_ri], 1);
		_ri--;
	}

	if (big_bang_timer >= big_bang_duration) {
		game_state = 1;
	}
	exit;
}

// --- GAME OVER ---
if (game_state == 2) {
	if (device_mouse_check_button_pressed(0, mb_left)) {
		// Reset everything
		energy = 5;
		stars = [];
		rogues = [];
		dust = [];
		nova_particles = [];
		popups = [];
		game_time = 0;
		dust_speed = 0.8;
		dust_per_spawn = 2;
		points = 0;
		void_level = 0;
		void_speed = 0.00008;
		void_pushback_amount = 0;
		void_grace_period = 900;
		void_active = false;
		bang_flash = 0;
		// Go to big bang
		game_state = 0;
		big_bang_timer = 0;
	}
	exit;
}

if (game_state != 1) exit;

// Always fade bang flash
if (bang_flash > 0) bang_flash -= 0.03;

game_time++;

// --- DIFFICULTY ---
if (game_time mod 600 == 0) {
	dust_speed = min(dust_speed + 0.1, 2.5);
	dust_per_spawn = min(dust_per_spawn + 1, 5);
}

// --- THE VOID ---
if (!void_active) {
	void_grace_period--;
	if (void_grace_period <= 0) {
		void_active = true;
		// Immediate contraction — void jumps to 10% instantly
		void_level = 0.10;
	}
} else {
	// Void gets stronger over time — accelerates relentlessly
	void_speed += void_accel;

	// Calculate light power (slows but never stops)
	void_light_power = 0;
	var _vsi = 0;
	var _vslen = array_length(stars);
	repeat (_vslen) {
		var _vs = stars[_vsi];
		if (!_vs.supernova) {
			void_light_power += _vs.radius * 0.000012;
			void_light_power += array_length(_vs.planets) * 0.000008;
		}
		_vsi++;
	}
	var _vroi = 0;
	var _vrlen = array_length(rogues);
	repeat (_vrlen) {
		var _vrp = rogues[_vroi];
		void_light_power += (_vrp.life / _vrp.max_life) * 0.000004;
		_vroi++;
	}

	// Apply supernova pushback smoothly (never push below 0.03 so void is always visible)
	if (void_pushback_amount > 0) {
		var _push_step = min(void_pushback_amount, 0.002);
		void_level -= _push_step;
		void_pushback_amount -= _push_step;
		if (void_level < 0.03) {
			void_level = 0.03;
			void_pushback_amount = 0;
		}
	}

	// Void always advances — light reduces speed but minimum 40%
	var _net_advance = void_speed - void_light_power;
	if (_net_advance < void_speed * 0.4) _net_advance = void_speed * 0.4;
	void_level += _net_advance;
}

// Playable area bounds
var _void_px = void_level * _w;
var _void_py = void_level * _h;
var _play_left = _void_px;
var _play_top = _void_py;
var _play_right = _w - _void_px;
var _play_bottom = _h - _void_py;

// Game over if void consumed too much
if (void_level >= 0.45) {
	game_state = 2;
	api_submit_score(points, undefined);
	api_save_state(0, { points }, undefined);
	exit;
}

// --- SPAWN DUST ---
dust_spawn_timer++;
if (dust_spawn_timer >= dust_spawn_rate && array_length(dust) < max_dust) {
	dust_spawn_timer = 0;
	repeat (dust_per_spawn) {
		if (array_length(dust) >= max_dust) break;
		var _side = irandom(3);
		var _dx = 0;
		var _dy = 0;
		var _dvx = 0;
		var _dvy = 0;
		if (_side == 0) { _dx = random_range(_play_left, _play_right); _dy = _play_top; _dvx = random_range(-0.5, 0.5); _dvy = random_range(0.3, dust_speed); }
		else if (_side == 1) { _dx = random_range(_play_left, _play_right); _dy = _play_bottom; _dvx = random_range(-0.5, 0.5); _dvy = random_range(-dust_speed, -0.3); }
		else if (_side == 2) { _dx = _play_left; _dy = random_range(_play_top, _play_bottom); _dvx = random_range(0.3, dust_speed); _dvy = random_range(-0.5, 0.5); }
		else { _dx = _play_right; _dy = random_range(_play_top, _play_bottom); _dvx = random_range(-dust_speed, -0.3); _dvy = random_range(-0.5, 0.5); }

		array_push(dust, {
			x: _dx, y: _dy,
			vx: _dvx, vy: _dvy,
			alpha: random_range(0.4, 1.0),
			size: random_range(1.5, 3.5)
		});
	}
}

// --- TAP TO PLACE STAR ---
if (tap_cooldown > 0) tap_cooldown--;

if (device_mouse_check_button_pressed(0, mb_left) && tap_cooldown <= 0) {
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);

	if (_mx > _play_left + 10 && _mx < _play_right - 10 &&
		_my > _play_top + 10 && _my < _play_bottom - 10 &&
		energy > 0 && array_length(stars) < max_stars) {
		energy--;
		tap_cooldown = 10;

		array_push(stars, {
			x: _mx, y: _my,
			radius: 4,
			dust_count: 0,
			life: star_max_life,
			max_life: star_max_life,
			growing: true,
			color_lerp: 0,
			supernova: false,
			nova_timer: 0,
			nova_radius: 0,
			planets: [],
			mass: 10,
			planets_spawned: 0
		});
	}
}

// --- UPDATE DUST ---
var _dust_len = array_length(dust);
var _star_len = array_length(stars);
var _rogue_len = array_length(rogues);
var _dust_to_remove = [];

var _di = 0;
repeat (_dust_len) {
	var _d = dust[_di];

	var _best_dist = 9999;
	var _best_ax = 0;
	var _best_ay = 0;
	var _best_pull = star_pull_radius;
	var _best_type = -1;
	var _best_idx = -1;

	var _si = 0;
	repeat (_star_len) {
		var _s = stars[_si];
		if (!_s.supernova && _s.growing) {
			var _dist = point_distance(_d.x, _d.y, _s.x, _s.y);
			if (_dist < star_pull_radius && _dist < _best_dist) {
				_best_dist = _dist;
				_best_ax = _s.x;
				_best_ay = _s.y;
				_best_pull = star_pull_radius;
				_best_type = 0;
				_best_idx = _si;
			}
		}
		if (!_s.supernova) {
			var _plen = array_length(_s.planets);
			var _pi = 0;
			repeat (_plen) {
				var _p = _s.planets[_pi];
				var _pdist = point_distance(_d.x, _d.y, _p.px, _p.py);
				if (_pdist < planet_pull_radius && _pdist < _best_dist) {
					_best_dist = _pdist;
					_best_ax = _p.px;
					_best_ay = _p.py;
					_best_pull = planet_pull_radius;
					_best_type = 1;
					_best_idx = _si;
				}
				_pi++;
			}
		}
		_si++;
	}

	var _ri2 = 0;
	repeat (_rogue_len) {
		var _rp = rogues[_ri2];
		var _rdist = point_distance(_d.x, _d.y, _rp.px, _rp.py);
		if (_rdist < _rp.pull_radius && _rdist < _best_dist) {
			_best_dist = _rdist;
			_best_ax = _rp.px;
			_best_ay = _rp.py;
			_best_pull = _rp.pull_radius;
			_best_type = 2;
			_best_idx = _ri2;
		}
		_ri2++;
	}

	if (_best_type >= 0) {
		var _dir = point_direction(_d.x, _d.y, _best_ax, _best_ay);
		var _strength = 1.5 + (1.0 - _best_dist / _best_pull) * 3.0;
		_d.vx += lengthdir_x(_strength, _dir) * 0.1;
		_d.vy += lengthdir_y(_strength, _dir) * 0.1;

		var _absorb_dist = 8;
		if (_best_type == 0) _absorb_dist = stars[_best_idx].radius + 5;

		if (_best_dist < _absorb_dist) {
			if (_best_type == 0) {
				var _s = stars[_best_idx];
				_s.dust_count++;
				_s.radius = min(_s.radius + star_grow_rate, 35);
				_s.color_lerp = min(_s.dust_count / 20, 1.0);
				_s.mass += 0.3;
				points++;

				var _needed = planet_first_threshold + _s.planets_spawned * planet_every;
				if (_s.dust_count >= _needed && array_length(_s.planets) < max_planets_per_star) {
					_s.planets_spawned++;
					var _orbit_dist = 30 + array_length(_s.planets) * 18 + random(10);
					var _angle = random(360);
					var _npx = _s.x + lengthdir_x(_orbit_dist, _angle);
					var _npy = _s.y + lengthdir_y(_orbit_dist, _angle);
					var _circ_speed = sqrt(gravity_g * _s.mass / max(_orbit_dist, 15));
					_circ_speed *= random_range(0.8, 1.1);
					var _tang_dir = _angle + 90;
					if (irandom(1) == 0) _tang_dir = _angle - 90;
					var _ci = irandom(array_length(planet_colors) - 1);
					array_push(_s.planets, {
						px: _npx, py: _npy,
						pvx: lengthdir_x(_circ_speed, _tang_dir),
						pvy: lengthdir_y(_circ_speed, _tang_dir),
						psize: random_range(3, 7),
						color: planet_colors[_ci],
						trail: []
					});
					// planet formed (no popup)
				}
			} else if (_best_type == 1) {
				points += 1;
			} else if (_best_type == 2) {
				points += 2;
				rogues[_best_idx].life = min(rogues[_best_idx].life + 20, rogues[_best_idx].max_life);
			}
			array_push(_dust_to_remove, _di);
			_di++;
			continue;
		}
	}

	_d.vx *= 0.998;
	_d.vy *= 0.998;
	_d.x += _d.vx;
	_d.y += _d.vy;

	if (_d.x < _play_left - 20 || _d.x > _play_right + 20 ||
		_d.y < _play_top - 20 || _d.y > _play_bottom + 20) {
		array_push(_dust_to_remove, _di);
	}
	_di++;
}

var _ri = array_length(_dust_to_remove) - 1;
while (_ri >= 0) {
	array_delete(dust, _dust_to_remove[_ri], 1);
	_ri--;
}

// --- UPDATE STARS ---
var _stars_to_remove = [];
_si = 0;
_star_len = array_length(stars);
repeat (_star_len) {
	var _s = stars[_si];

	if (_s.supernova) {
		_s.nova_timer++;
		_s.nova_radius += 4;
		if (_s.nova_timer > 45) {
			array_push(_stars_to_remove, _si);
		}
	} else {
		// Update orbiting planets
		var _planets_to_remove = [];
		var _plen = array_length(_s.planets);
		var _pi = 0;
		repeat (_plen) {
			var _p = _s.planets[_pi];
			var _dxx = _s.x - _p.px;
			var _dyy = _s.y - _p.py;
			var _dist = sqrt(_dxx * _dxx + _dyy * _dyy);
			var _soft_dist = max(_dist, 15);

			if (_dist < _s.radius + 2) {
				array_push(_planets_to_remove, _pi);
				_s.mass += 2;
				points += 5;
				var _bi = 0;
				repeat (8) {
					var _ba = (_bi / 8) * 360;
					var _bs = random_range(1, 3);
					array_push(nova_particles, {
						x: _p.px, y: _p.py,
						vx: lengthdir_x(_bs, _ba), vy: lengthdir_y(_bs, _ba),
						alpha: 1.0, size: random_range(1.5, 3),
						color: _p.color
					});
					_bi++;
				}
				_pi++;
				continue;
			}

			var _force = gravity_g * _s.mass / (_soft_dist * _soft_dist);
			_p.pvx += _force * (_dxx / _dist);
			_p.pvy += _force * (_dyy / _dist);

			var _spd = sqrt(_p.pvx * _p.pvx + _p.pvy * _p.pvy);
			if (_spd > 5) {
				_p.pvx = (_p.pvx / _spd) * 5;
				_p.pvy = (_p.pvy / _spd) * 5;
			}

			_p.px += _p.pvx;
			_p.py += _p.pvy;

			if (game_time mod 3 == 0) {
				array_push(_p.trail, _p.px);
				array_push(_p.trail, _p.py);
				while (array_length(_p.trail) > 80) {
					array_delete(_p.trail, 0, 2);
				}
			}
			_pi++;
		}

		var _pri = array_length(_planets_to_remove) - 1;
		while (_pri >= 0) {
			array_delete(_s.planets, _planets_to_remove[_pri], 1);
			_pri--;
		}

		_s.life--;

		if (_s.life <= 0) {
			// SUPERNOVA!
			_s.supernova = true;
			_s.nova_timer = 0;
			_s.nova_radius = _s.radius;
			_s.growing = false;
			energy = min(energy + 2, max_energy);
			var _bonus = _s.dust_count * 3;
			points += _bonus;

			// Push back void slightly
			var _push = 0.003 + _s.dust_count * 0.0005 + array_length(_s.planets) * 0.001;
			void_pushback_amount += _push;

			// supernova (no popup)

			var _npi = 0;
			repeat (24) {
				var _angle = (_npi / 24) * 360 + random(15);
				var _nspd = random_range(2, 7);
				array_push(nova_particles, {
					x: _s.x, y: _s.y,
					vx: lengthdir_x(_nspd, _angle), vy: lengthdir_y(_nspd, _angle),
					alpha: 1.0, size: random_range(2, 6),
					color: merge_colour(c_yellow, c_red, random(1))
				});
				_npi++;
			}

			_npi = 0;
			repeat (_s.dust_count + 8) {
				if (array_length(dust) >= max_dust) break;
				var _angle = random(360);
				var _nspd = random_range(1.5, 4.0);
				array_push(dust, {
					x: _s.x + random_range(-5, 5),
					y: _s.y + random_range(-5, 5),
					vx: lengthdir_x(_nspd, _angle),
					vy: lengthdir_y(_nspd, _angle),
					alpha: random_range(0.6, 1.0),
					size: random_range(2.0, 4.0)
				});
				_npi++;
			}

			// Scatter planets → rogues
			_plen = array_length(_s.planets);
			_pi = 0;
			repeat (_plen) {
				if (array_length(rogues) >= max_rogues) break;
				var _p = _s.planets[_pi];
				var _blast_dir = point_direction(_s.x, _s.y, _p.px, _p.py);
				var _blast_spd = random_range(1.5, 3.0);
				var _rvx = _p.pvx + lengthdir_x(_blast_spd, _blast_dir);
				var _rvy = _p.pvy + lengthdir_y(_blast_spd, _blast_dir);
				var _rspd = sqrt(_rvx * _rvx + _rvy * _rvy);
				if (_rspd > 3) {
					_rvx = (_rvx / _rspd) * 3;
					_rvy = (_rvy / _rspd) * 3;
				}
				array_push(rogues, {
					px: _p.px, py: _p.py,
					pvx: _rvx, pvy: _rvy,
					psize: _p.psize,
					color: _p.color,
					pull_radius: planet_pull_radius,
					life: rogue_max_life,
					max_life: rogue_max_life,
					trail: []
				});
				_pi++;
			}
			_s.planets = [];
		}
	}
	_si++;
}

_ri = array_length(_stars_to_remove) - 1;
while (_ri >= 0) {
	array_delete(stars, _stars_to_remove[_ri], 1);
	_ri--;
}

// --- UPDATE ROGUES ---
var _rogues_to_remove = [];
_rogue_len = array_length(rogues);
var _roi = 0;
repeat (_rogue_len) {
	var _rp = rogues[_roi];
	_rp.life--;
	_rp.px += _rp.pvx;
	_rp.py += _rp.pvy;
	_rp.pvx *= 0.997;
	_rp.pvy *= 0.997;

	if (game_time mod 4 == 0) {
		array_push(_rp.trail, _rp.px);
		array_push(_rp.trail, _rp.py);
		while (array_length(_rp.trail) > 60) {
			array_delete(_rp.trail, 0, 2);
		}
	}

	if (_rp.life <= 0 || _rp.px < _play_left - 30 || _rp.px > _play_right + 30 ||
		_rp.py < _play_top - 30 || _rp.py > _play_bottom + 30) {
		array_push(_rogues_to_remove, _roi);
	}
	_roi++;
}
_ri = array_length(_rogues_to_remove) - 1;
while (_ri >= 0) {
	array_delete(rogues, _rogues_to_remove[_ri], 1);
	_ri--;
}

// --- UPDATE NOVA PARTICLES ---
var _nova_to_remove = [];
var _ni = 0;
var _nova_len = array_length(nova_particles);
repeat (_nova_len) {
	var _np = nova_particles[_ni];
	_np.x += _np.vx;
	_np.y += _np.vy;
	_np.alpha -= 0.025;
	if (_np.alpha <= 0) array_push(_nova_to_remove, _ni);
	_ni++;
}
_ri = array_length(_nova_to_remove) - 1;
while (_ri >= 0) {
	array_delete(nova_particles, _nova_to_remove[_ri], 1);
	_ri--;
}

// --- UPDATE POPUPS ---
var _pop_to_remove = [];
var _poi = 0;
var _pop_len = array_length(popups);
repeat (_pop_len) {
	var _pop = popups[_poi];
	_pop.y += _pop.vy;
	_pop.alpha -= 0.02;
	if (_pop.alpha <= 0) array_push(_pop_to_remove, _poi);
	_poi++;
}
_ri = array_length(_pop_to_remove) - 1;
while (_ri >= 0) {
	array_delete(popups, _pop_to_remove[_ri], 1);
	_ri--;
}

// --- GAME OVER CHECK (energy) ---
if (energy <= 0) {
	var _has_active = false;
	_si = 0;
	_star_len = array_length(stars);
	repeat (_star_len) {
		if (!stars[_si].supernova) { _has_active = true; break; }
		_si++;
	}
	if (!_has_active && array_length(rogues) == 0) {
		game_state = 2;
		api_submit_score(points, undefined);
		api_save_state(0, { points }, undefined);
	}
}
