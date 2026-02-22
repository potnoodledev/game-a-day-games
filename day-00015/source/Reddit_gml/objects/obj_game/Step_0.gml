
// ============================================================
// AUTO CHESS — Step_0 (Game Logic)
// ============================================================

// --- Helper: create a unit struct ---
#macro UNIT_COST 0
#macro UNIT_HP 1
#macro UNIT_ATK 2
#macro UNIT_RANGE 3
#macro UNIT_SPD 4

// ============================================================
// STATE 1: SHOP PHASE
// ============================================================
if (game_state == 1) {
	// --- Spawn enemy wave preview at start of shop ---
	if (spawn_wave) {
		spawn_wave = false;
		enemy_units = [];

		// --- Wave scaling ---
		// Enemy count: 2 at round 1, ramps up, caps at 12 (fills 2 rows)
		var _num_enemies = min(2 + floor(current_round * 0.8), grid_cols * 2);
		// Stat multiplier: exponential growth (1.0, 1.15, 1.32, 1.52, ...)
		var _stat_mult = power(1.15, current_round - 1);
		// Star upgrade chance: 0% at round 1, increases by 8% per round
		var _star2_chance = min((current_round - 1) * 8, 70); // max 70%
		var _star3_chance = min(max(current_round - 6, 0) * 5, 30); // starts round 7, max 30%
		// Boss every 5 rounds: one star-3 with 3x stats + full support wave
		var _is_boss = (current_round mod 5 == 0);
		// All unit types available from the start (random composition)
		// Track occupied cells to prevent overlap
		var _occupied = array_create(grid_cols * 2, false); // 6 cols x 2 rows = 12 slots

		if (_is_boss) {
			// Boss: random type (not healer), star 3, boosted stats
			var _boss_type = irandom(NUM_UNIT_TYPES - 2);
			var _bhp = floor(unit_stats[_boss_type][UNIT_HP] * 3.5 * _stat_mult);
			var _batk = floor(unit_stats[_boss_type][UNIT_ATK] * 3.5 * _stat_mult);
			// Random position in enemy area
			var _bcol = irandom(grid_cols - 1);
			var _brow = irandom(1);
			var _bslot = _brow * grid_cols + _bcol;
			_occupied[_bslot] = true;
			array_push(enemy_units, {
				unit_type: _boss_type, star: 3,
				hp: _bhp, max_hp: _bhp, atk: _batk,
				base_range: unit_stats[_boss_type][UNIT_RANGE],
				spd: unit_stats[_boss_type][UNIT_SPD],
				grid_col: _bcol, grid_row: _brow,
				draw_x: 0, draw_y: 0,
				atk_cooldown: 0, alive: true,
				has_crit: false, dmg_reduction: 0, splash_mult: 1, heal_bonus: 0
			});
			// Fill remaining slots with support enemies
			_num_enemies = min(_num_enemies, grid_cols * 2);
		}

		// Spawn remaining enemies
		var _spawned = array_length(enemy_units);
		while (_spawned < _num_enemies) {
			// Random type
			var _et = irandom(NUM_UNIT_TYPES - 1);
			// Random star based on round scaling
			var _star = 1;
			var _roll = irandom(99);
			if (_roll < _star3_chance) {
				_star = 3;
			} else if (_roll < _star3_chance + _star2_chance) {
				_star = 2;
			}
			// Stats scale with star AND round multiplier
			var _ehp = floor(unit_stats[_et][UNIT_HP] * _star * _stat_mult);
			var _eatk = floor(unit_stats[_et][UNIT_ATK] * _star * _stat_mult);
			// Find an unoccupied random cell in enemy rows
			var _ecol = irandom(grid_cols - 1);
			var _erow = irandom(1);
			var _eslot = _erow * grid_cols + _ecol;
			var _attempts = 0;
			while (_occupied[_eslot] && _attempts < 20) {
				_ecol = irandom(grid_cols - 1);
				_erow = irandom(1);
				_eslot = _erow * grid_cols + _ecol;
				_attempts++;
			}
			if (_occupied[_eslot]) {
				// All slots full, stop spawning
				break;
			}
			_occupied[_eslot] = true;
			array_push(enemy_units, {
				unit_type: _et, star: _star,
				hp: _ehp, max_hp: _ehp, atk: _eatk,
				base_range: unit_stats[_et][UNIT_RANGE],
				spd: unit_stats[_et][UNIT_SPD],
				grid_col: _ecol, grid_row: _erow,
				draw_x: 0, draw_y: 0,
				atk_cooldown: 0, alive: true,
				has_crit: false, dmg_reduction: 0, splash_mult: 1, heal_bonus: 0
			});
			_spawned++;
		}
	}

	shop_timer--;

	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);
	var _pressed = device_mouse_check_button_pressed(0, mb_left);
	var _released = device_mouse_check_button_released(0, mb_left);
	var _held = device_mouse_check_button(0, mb_left);

	// --- Dragging existing board units ---
	if (dragging && drag_unit_idx >= 0) {
		if (_held) {
			// Update drag position
			drag_ox = _mx;
			drag_oy = _my;
		}
		if (_released) {
			// Check sell zone FIRST
			if (_mx >= sell_btn.x1 && _mx <= sell_btn.x2 && _my >= sell_btn.y1 && _my <= sell_btn.y2) {
				if (drag_unit_idx >= 0 && drag_unit_idx < array_length(board_units)) {
					var _su = board_units[drag_unit_idx];
					var _sell_price = max(1, floor(unit_stats[_su.unit_type][UNIT_COST] * _su.star * 0.5));
					gold += _sell_price;
					array_delete(board_units, drag_unit_idx, 1);
				}
			} else {
				// Drop unit — snap to grid
				var _col = floor((_mx - grid_x) / cell_size);
				var _row = floor((_my - grid_y) / cell_size);

				// Clamp to player rows
				if (_col >= 0 && _col < grid_cols && _row >= player_rows_start && _row < grid_rows) {
					// Check if slot is occupied by another unit
					var _occupied = -1;
					var _bi = 0;
					while (_bi < array_length(board_units)) {
						if (_bi != drag_unit_idx && board_units[_bi].grid_col == _col && board_units[_bi].grid_row == _row) {
							_occupied = _bi;
							break;
						}
						_bi++;
					}
					if (_occupied >= 0) {
						// Swap positions
						var _drag_u = board_units[drag_unit_idx];
						var _occ_u = board_units[_occupied];
						var _tmp_col = _drag_u.grid_col;
						var _tmp_row = _drag_u.grid_row;
						_drag_u.grid_col = _occ_u.grid_col;
						_drag_u.grid_row = _occ_u.grid_row;
						_occ_u.grid_col = _tmp_col;
						_occ_u.grid_row = _tmp_row;
					} else {
						board_units[drag_unit_idx].grid_col = _col;
						board_units[drag_unit_idx].grid_row = _row;
					}
				}
			}
			// Reset drag state
			dragging = false;
			drag_unit_idx = -1;
		}
	}
	else if (_pressed) {
		// --- Check: tap on board unit (start drag or sell) ---
		var _tapped_unit = -1;
		var _bi = 0;
		while (_bi < array_length(board_units)) {
			var _u = board_units[_bi];
			var _ux = grid_x + _u.grid_col * cell_size + cell_size * 0.5;
			var _uy = grid_y + _u.grid_row * cell_size + cell_size * 0.5;
			var _r = cell_size * 0.4;
			if (point_distance(_mx, _my, _ux, _uy) < _r) {
				_tapped_unit = _bi;
				break;
			}
			_bi++;
		}

		if (_tapped_unit >= 0) {
			// Start dragging
			dragging = true;
			drag_unit_idx = _tapped_unit;
			drag_ox = _mx;
			drag_oy = _my;
		} else {
			// --- Check: tap on sell area ---
			if (_mx >= sell_btn.x1 && _mx <= sell_btn.x2 && _my >= sell_btn.y1 && _my <= sell_btn.y2) {
				// Sell is handled via drag-to-sell, skip here
			}

			// --- Check: tap on shop item ---
			var _si = 0;
			while (_si < array_length(shop_btns)) {
				var _btn = shop_btns[_si];
				if (_mx >= _btn.x1 && _mx <= _btn.x2 && _my >= _btn.y1 && _my <= _btn.y2) {
					if (_si < array_length(shop_items) && shop_items[_si] >= 0) {
						var _type = shop_items[_si];
						var _cost = unit_stats[_type][UNIT_COST];
						if (gold >= _cost && array_length(board_units) < max_board_units) {
							// Buy unit
							gold -= _cost;

							// Find first open slot in player rows
							var _placed = false;
							var _pr = player_rows_start;
							while (_pr < grid_rows && !_placed) {
								var _pc = 0;
								while (_pc < grid_cols && !_placed) {
									var _slot_free = true;
									var _ci = 0;
									while (_ci < array_length(board_units)) {
										if (board_units[_ci].grid_col == _pc && board_units[_ci].grid_row == _pr) {
											_slot_free = false;
											break;
										}
										_ci++;
									}
									if (_slot_free) {
										var _new_unit = {
											unit_type: _type,
											star: 1,
											hp: unit_stats[_type][UNIT_HP],
											max_hp: unit_stats[_type][UNIT_HP],
											atk: unit_stats[_type][UNIT_ATK],
											base_range: unit_stats[_type][UNIT_RANGE],
											spd: unit_stats[_type][UNIT_SPD],
											grid_col: _pc,
											grid_row: _pr,
											draw_x: 0,
											draw_y: 0,
											atk_cooldown: 0,
											alive: true,
											has_crit: false,
											dmg_reduction: 0,
											splash_mult: 1,
											heal_bonus: 0
										};
										array_push(board_units, _new_unit);
										_placed = true;

										// Remove from shop
										shop_items[_si] = -1;

										// Check for merge (3 of same type + same star)
										var _match_type = _type;
										var _match_star = 1;
										var _match_refs = [];
										var _mi = 0;
										while (_mi < array_length(board_units)) {
											if (board_units[_mi].unit_type == _match_type && board_units[_mi].star == _match_star) {
												array_push(_match_refs, board_units[_mi]);
											}
											_mi++;
										}
										if (array_length(_match_refs) >= 3) {
											// Keep the last one (newest), remove the other 2
											var _kept = _match_refs[array_length(_match_refs) - 1];
											var _rem_a = _match_refs[0];
											var _rem_b = _match_refs[1];

											// Upgrade the kept unit
											var _base_hp = unit_stats[_match_type][UNIT_HP];
											var _base_atk = unit_stats[_match_type][UNIT_ATK];
											_kept.star = 2;
											_kept.max_hp = _base_hp * 2;
											_kept.hp = _kept.max_hp;
											_kept.atk = _base_atk * 2;

											// Remove the other two by filtering
											var _new_board = [];
											var _fi = 0;
											while (_fi < array_length(board_units)) {
												if (board_units[_fi] != _rem_a && board_units[_fi] != _rem_b) {
													array_push(_new_board, board_units[_fi]);
												}
												_fi++;
											}
											board_units = _new_board;

											// Merge visual
											array_push(damage_numbers, {
												x: grid_x + _kept.grid_col * cell_size + cell_size * 0.5,
												y: grid_y + _kept.grid_row * cell_size,
												text: "MERGE!",
												timer: 60,
												col: make_colour_rgb(255, 215, 0)
											});

											// Check for star 3 merge (3x star-2 of same type)
											var _match_refs2 = [];
											var _mi2 = 0;
											while (_mi2 < array_length(board_units)) {
												if (board_units[_mi2].unit_type == _match_type && board_units[_mi2].star == 2) {
													array_push(_match_refs2, board_units[_mi2]);
												}
												_mi2++;
											}
											if (array_length(_match_refs2) >= 3) {
												var _kept2 = _match_refs2[array_length(_match_refs2) - 1];
												var _rem2_a = _match_refs2[0];
												var _rem2_b = _match_refs2[1];
												_kept2.star = 3;
												_kept2.max_hp = _base_hp * 3;
												_kept2.hp = _kept2.max_hp;
												_kept2.atk = _base_atk * 3;
												var _new_board2 = [];
												var _fi2 = 0;
												while (_fi2 < array_length(board_units)) {
													if (board_units[_fi2] != _rem2_a && board_units[_fi2] != _rem2_b) {
														array_push(_new_board2, board_units[_fi2]);
													}
													_fi2++;
												}
												board_units = _new_board2;

												array_push(damage_numbers, {
													x: grid_x + _kept2.grid_col * cell_size + cell_size * 0.5,
													y: grid_y + _kept2.grid_row * cell_size,
													text: "MAX!",
													timer: 90,
													col: make_colour_rgb(255, 100, 255)
												});
											}
										}
									}
									_pc++;
								}
								_pr++;
							}
						}
					}
					break;
				}
				_si++;
			}

			// --- Check: tap GO button ---
			if (_mx >= go_btn.x1 && _mx <= go_btn.x2 && _my >= go_btn.y1 && _my <= go_btn.y2) {
				shop_timer = 0; // Force battle start
			}
		}
	}

	// --- Timer expired: start battle ---
	if (shop_timer <= 0) {
		game_state = 2;
		battle_tick = 0;
		battle_over = false;
		round_won = false;
		enemies_killed = 0;

		// Enemies already spawned during shop phase (preview)
		// Reset enemy cooldowns for battle
		var _ei2 = 0;
		while (_ei2 < array_length(enemy_units)) {
			enemy_units[_ei2].atk_cooldown = 0;
			_ei2++;
		}

		// --- Calculate synergies for player units ---
		var _ti = 0;
		while (_ti < NUM_TAGS) {
			active_synergies[_ti] = false;
			_ti++;
		}

		// Count units per tag
		var _tag_counts = array_create(NUM_TAGS, 0);
		var _has_type = array_create(NUM_UNIT_TYPES, false);
		var _bi = 0;
		while (_bi < array_length(board_units)) {
			var _u = board_units[_bi];
			_has_type[_u.unit_type] = true;
			var _tagi = 0;
			while (_tagi < array_length(unit_tags[_u.unit_type])) {
				_tag_counts[unit_tags[_u.unit_type][_tagi]]++;
				_tagi++;
			}
			_bi++;
		}

		// Frontline: 2+ Frontline units
		if (_tag_counts[TAG_FRONTLINE] >= 2) active_synergies[TAG_FRONTLINE] = true;
		// Ranged: 2+ Ranged units
		if (_tag_counts[TAG_RANGED] >= 2) active_synergies[TAG_RANGED] = true;
		// Mystic: need both Mage AND Healer
		if (_has_type[UNIT_MAGE] && _has_type[UNIT_HEALER]) active_synergies[TAG_MYSTIC] = true;
		// Armored: Knight + another Frontline
		if (_has_type[UNIT_KNIGHT] && _tag_counts[TAG_FRONTLINE] >= 2) active_synergies[TAG_ARMORED] = true;
		// Assassin: Rogue + any Ranged
		if (_has_type[UNIT_ROGUE] && _tag_counts[TAG_RANGED] >= 1) active_synergies[TAG_ASSASSIN] = true;

		// Apply synergy bonuses to player units
		_bi = 0;
		while (_bi < array_length(board_units)) {
			var _u = board_units[_bi];
			// Reset synergy bonuses
			_u.dmg_reduction = 0;
			_u.has_crit = false;
			_u.splash_mult = 1;
			_u.heal_bonus = 0;

			// Heal units to full at battle start
			_u.hp = _u.max_hp;
			_u.atk_cooldown = 0;

			// Frontline: +30% HP
			if (active_synergies[TAG_FRONTLINE]) {
				var _has_fl = false;
				var _fi = 0;
				while (_fi < array_length(unit_tags[_u.unit_type])) {
					if (unit_tags[_u.unit_type][_fi] == TAG_FRONTLINE) _has_fl = true;
					_fi++;
				}
				if (_has_fl) {
					var _bonus_hp = floor(_u.max_hp * SYNERGY_FRONTLINE_HP_BONUS);
					_u.max_hp += _bonus_hp;
					_u.hp = _u.max_hp;
				}
			}

			// Ranged: +25% ATK
			if (active_synergies[TAG_RANGED]) {
				var _has_rng = false;
				var _ri = 0;
				while (_ri < array_length(unit_tags[_u.unit_type])) {
					if (unit_tags[_u.unit_type][_ri] == TAG_RANGED) _has_rng = true;
					_ri++;
				}
				if (_has_rng) {
					_u.atk += floor(_u.atk * SYNERGY_RANGED_ATK_BONUS);
				}
			}

			// Mystic: splash x2 for Mage, heal +50% for Healer
			if (active_synergies[TAG_MYSTIC]) {
				if (_u.unit_type == UNIT_MAGE) _u.splash_mult = SYNERGY_MYSTIC_SPLASH_MULT;
				if (_u.unit_type == UNIT_HEALER) _u.heal_bonus = SYNERGY_MYSTIC_HEAL_BONUS;
			}

			// Armored: Knight gets -30% damage
			if (active_synergies[TAG_ARMORED] && _u.unit_type == UNIT_KNIGHT) {
				_u.dmg_reduction = SYNERGY_ARMORED_DR;
			}

			// Assassin: Rogue gets crit
			if (active_synergies[TAG_ASSASSIN] && _u.unit_type == UNIT_ROGUE) {
				_u.has_crit = true;
			}

			_bi++;
		}

		// Reset enemy atk cooldowns and init draw positions
		var _ei2 = 0;
		while (_ei2 < array_length(enemy_units)) {
			enemy_units[_ei2].atk_cooldown = 0;
			enemy_units[_ei2].draw_x = grid_x + enemy_units[_ei2].grid_col * cell_size + cell_size * 0.5;
			enemy_units[_ei2].draw_y = grid_y + enemy_units[_ei2].grid_row * cell_size + cell_size * 0.5;
			_ei2++;
		}

		// Init player unit draw positions
		var _bi2 = 0;
		while (_bi2 < array_length(board_units)) {
			board_units[_bi2].draw_x = grid_x + board_units[_bi2].grid_col * cell_size + cell_size * 0.5;
			board_units[_bi2].draw_y = grid_y + board_units[_bi2].grid_row * cell_size + cell_size * 0.5;
			_bi2++;
		}

		// Clear old anims
		attack_anims = [];
		death_anims = [];
	}
}

// ============================================================
// STATE 2: BATTLE PHASE
// ============================================================
if (game_state == 2) {
	battle_tick++;

	// --- Animate all units every frame: lerp draw positions toward grid target ---
	var _ai = 0;
	while (_ai < array_length(board_units)) {
		var _au = board_units[_ai];
		var _target_x = grid_x + _au.grid_col * cell_size + cell_size * 0.5;
		var _target_y = grid_y + _au.grid_row * cell_size + cell_size * 0.5;
		_au.draw_x += (_target_x - _au.draw_x) * anim_lerp_speed;
		_au.draw_y += (_target_y - _au.draw_y) * anim_lerp_speed;
		_ai++;
	}
	_ai = 0;
	while (_ai < array_length(enemy_units)) {
		var _au = enemy_units[_ai];
		var _target_x = grid_x + _au.grid_col * cell_size + cell_size * 0.5;
		var _target_y = grid_y + _au.grid_row * cell_size + cell_size * 0.5;
		_au.draw_x += (_target_x - _au.draw_x) * anim_lerp_speed;
		_au.draw_y += (_target_y - _au.draw_y) * anim_lerp_speed;
		_ai++;
	}

	// --- Update attack animations ---
	var _aai = array_length(attack_anims) - 1;
	while (_aai >= 0) {
		var _aa = attack_anims[_aai];
		_aa.timer--;
		if (_aa.timer <= 0) {
			array_delete(attack_anims, _aai, 1);
		} else {
			// Lunge: first half move toward target, second half return
			var _progress = 1.0 - (_aa.timer / _aa.max_timer);
			var _lunge = 0;
			if (_progress < 0.4) {
				_lunge = _progress / 0.4; // 0 to 1
			} else {
				_lunge = (1.0 - _progress) / 0.6; // 1 back to 0
			}
			var _lunge_dist = cell_size * 0.3;
			var _dx = _aa.tx - _aa.ox;
			var _dy = _aa.ty - _aa.oy;
			var _dist = max(1, sqrt(_dx * _dx + _dy * _dy));
			_aa.unit_ref.draw_x = _aa.ox + (_dx / _dist) * _lunge * _lunge_dist;
			_aa.unit_ref.draw_y = _aa.oy + (_dy / _dist) * _lunge * _lunge_dist;
		}
		_aai--;
	}

	// --- Update death animations ---
	var _dai = array_length(death_anims) - 1;
	while (_dai >= 0) {
		death_anims[_dai].timer--;
		if (death_anims[_dai].timer <= 0) {
			array_delete(death_anims, _dai, 1);
		}
		_dai--;
	}

	// --- Update projectiles ---
	var _pri = array_length(projectiles) - 1;
	while (_pri >= 0) {
		var _pr = projectiles[_pri];
		_pr.timer--;
		if (_pr.timer <= 0) {
			array_delete(projectiles, _pri, 1);
		} else {
			// Lerp from start to target
			var _progress = 1.0 - (_pr.timer / _pr.max_timer);
			_pr.cx = _pr.x + (_pr.tx - _pr.x) * _progress;
			_pr.cy = _pr.y + (_pr.ty - _pr.y) * _progress;
		}
		_pri--;
	}

	// Process battle every N frames
	if (battle_tick mod max(1, floor(battle_speed * 0.5)) == 0) {

		// --- Process each player unit ---
		var _bi = 0;
		while (_bi < array_length(board_units)) {
			var _u = board_units[_bi];
			if (!_u.alive) { _bi++; continue; }

			_u.atk_cooldown--;

			if (_u.atk_cooldown <= 0) {
				// Healer: heal lowest HP ally
				if (_u.unit_type == UNIT_HEALER) {
					var _lowest_hp_idx = -1;
					var _lowest_hp_pct = 1.0;
					var _hi = 0;
					while (_hi < array_length(board_units)) {
						var _ally = board_units[_hi];
						if (_ally.alive && _ally.hp < _ally.max_hp) {
							var _pct = _ally.hp / _ally.max_hp;
							if (_pct < _lowest_hp_pct) {
								_lowest_hp_pct = _pct;
								_lowest_hp_idx = _hi;
							}
						}
						_hi++;
					}
					if (_lowest_hp_idx >= 0) {
						var _heal_target = board_units[_lowest_hp_idx];
						var _heal_amt = floor(_u.atk * (1 + _u.heal_bonus));
						_heal_target.hp = min(_heal_target.max_hp, _heal_target.hp + _heal_amt);
						_u.atk_cooldown = 3;
						// Heal projectile
						array_push(projectiles, {
							x: _u.draw_x, y: _u.draw_y,
							tx: _heal_target.draw_x, ty: _heal_target.draw_y,
							color: make_colour_rgb(100, 255, 100),
							timer: 15, max_timer: 15, size: cell_size * 0.12
						});
						array_push(damage_numbers, {
							x: _heal_target.draw_x, y: _heal_target.draw_y - cell_size * 0.4,
							text: "+" + string(_heal_amt), timer: 40,
							col: make_colour_rgb(100, 255, 100)
						});
					}
				}
				// Rogue: leap to lowest HP enemy
				else if (_u.unit_type == UNIT_ROGUE) {
					var _lowest_idx = -1;
					var _lowest_hp2 = 999999;
					var _ei = 0;
					while (_ei < array_length(enemy_units)) {
						if (enemy_units[_ei].alive && enemy_units[_ei].hp < _lowest_hp2) {
							_lowest_hp2 = enemy_units[_ei].hp;
							_lowest_idx = _ei;
						}
						_ei++;
					}
					if (_lowest_idx >= 0) {
						var _target = enemy_units[_lowest_idx];
						var _dmg = _u.atk;
						if (_u.has_crit) {
							_dmg = _dmg * SYNERGY_ASSASSIN_CRIT_MULT;
							_u.has_crit = false;
						}
						_target.hp -= _dmg;
						_u.atk_cooldown = 3;
						array_push(attack_anims, {
							unit_ref: _u, ox: _u.draw_x, oy: _u.draw_y,
							tx: _target.draw_x, ty: _target.draw_y,
							timer: 12, max_timer: 12
						});
						array_push(damage_numbers, {
							x: _target.draw_x, y: _target.draw_y - cell_size * 0.4,
							text: string(_dmg), timer: 40,
							col: make_colour_rgb(255, 100, 100)
						});
						if (_target.hp <= 0) {
							_target.alive = false;
							array_push(death_anims, {
								x: _target.draw_x, y: _target.draw_y,
								r: cell_size * 0.35, color: unit_colors[_target.unit_type],
								letter: unit_letters[_target.unit_type],
								timer: 20, max_timer: 20
							});
							enemies_killed++;
							total_enemies_killed++;
						}
					}
				}
				// Mage: AoE splash
				else if (_u.unit_type == UNIT_MAGE) {
					var _nearest_idx = -1;
					var _nearest_dist = 9999;
					var _ei = 0;
					while (_ei < array_length(enemy_units)) {
						if (enemy_units[_ei].alive) {
							var _d = abs(enemy_units[_ei].grid_col - _u.grid_col) + abs(enemy_units[_ei].grid_row - _u.grid_row);
							if (_d <= _u.base_range && _d < _nearest_dist) {
								_nearest_dist = _d;
								_nearest_idx = _ei;
							}
						}
						_ei++;
					}
					if (_nearest_idx >= 0) {
						var _main_target = enemy_units[_nearest_idx];
						var _dmg = _u.atk;
						_main_target.hp -= _dmg;
						_u.atk_cooldown = 4;
						// Mage projectile (blue orb)
						array_push(projectiles, {
							x: _u.draw_x, y: _u.draw_y,
							tx: _main_target.draw_x, ty: _main_target.draw_y,
							color: make_colour_rgb(100, 150, 255),
							timer: 12, max_timer: 12, size: cell_size * 0.15
						});
						array_push(damage_numbers, {
							x: _main_target.draw_x, y: _main_target.draw_y - cell_size * 0.4,
							text: string(_dmg), timer: 40,
							col: make_colour_rgb(100, 150, 255)
						});
						if (_main_target.hp <= 0) {
							_main_target.alive = false;
							array_push(death_anims, {
								x: _main_target.draw_x, y: _main_target.draw_y,
								r: cell_size * 0.35, color: unit_colors[_main_target.unit_type],
								letter: unit_letters[_main_target.unit_type],
								timer: 20, max_timer: 20
							});
							enemies_killed++; total_enemies_killed++;
						}

						// Splash to adjacent enemies
						var _splash_range = _u.splash_mult;
						var _si = 0;
						while (_si < array_length(enemy_units)) {
							if (_si != _nearest_idx && enemy_units[_si].alive) {
								var _sd = abs(enemy_units[_si].grid_col - _main_target.grid_col) + abs(enemy_units[_si].grid_row - _main_target.grid_row);
								if (_sd <= _splash_range) {
									var _splash_dmg = floor(_dmg * 0.5);
									enemy_units[_si].hp -= _splash_dmg;
									array_push(damage_numbers, {
										x: enemy_units[_si].draw_x, y: enemy_units[_si].draw_y - cell_size * 0.4,
										text: string(_splash_dmg), timer: 40,
										col: make_colour_rgb(100, 150, 255)
									});
									if (enemy_units[_si].hp <= 0) {
										enemy_units[_si].alive = false;
										array_push(death_anims, {
											x: enemy_units[_si].draw_x, y: enemy_units[_si].draw_y,
											r: cell_size * 0.35, color: unit_colors[enemy_units[_si].unit_type],
											letter: unit_letters[enemy_units[_si].unit_type],
											timer: 20, max_timer: 20
										});
										enemies_killed++; total_enemies_killed++;
									}
								}
							}
							_si++;
						}
					}
				}
				// Warrior, Knight, Archer: standard attack
				else {
					var _nearest_idx = -1;
					var _nearest_dist = 9999;
					var _ei = 0;
					while (_ei < array_length(enemy_units)) {
						if (enemy_units[_ei].alive) {
							var _d = abs(enemy_units[_ei].grid_col - _u.grid_col) + abs(enemy_units[_ei].grid_row - _u.grid_row);
							if (_d <= _u.base_range && _d < _nearest_dist) {
								_nearest_dist = _d;
								_nearest_idx = _ei;
							}
						}
						_ei++;
					}
					if (_nearest_idx >= 0) {
						var _target = enemy_units[_nearest_idx];
						var _dmg = _u.atk;
						_target.hp -= _dmg;
						_u.atk_cooldown = 3;
						// Ranged units get projectile, melee get lunge
						if (_u.base_range > 1) {
							array_push(projectiles, {
								x: _u.draw_x, y: _u.draw_y,
								tx: _target.draw_x, ty: _target.draw_y,
								color: unit_colors[_u.unit_type],
								timer: 12, max_timer: 12, size: cell_size * 0.1
							});
						} else {
							array_push(attack_anims, {
								unit_ref: _u, ox: _u.draw_x, oy: _u.draw_y,
								tx: _target.draw_x, ty: _target.draw_y,
								timer: 12, max_timer: 12
							});
						}
						array_push(damage_numbers, {
							x: _target.draw_x, y: _target.draw_y - cell_size * 0.4,
							text: string(_dmg), timer: 40,
							col: make_colour_rgb(255, 200, 100)
						});
						if (_target.hp <= 0) {
							_target.alive = false;
							array_push(death_anims, {
								x: _target.draw_x, y: _target.draw_y,
								r: cell_size * 0.35, color: unit_colors[_target.unit_type],
								letter: unit_letters[_target.unit_type],
								timer: 20, max_timer: 20
							});
							enemies_killed++; total_enemies_killed++;
						}
					}
					// If no enemy in range, move toward nearest enemy
					else {
						var _move_idx = -1;
						var _move_dist = 9999;
						_ei = 0;
						while (_ei < array_length(enemy_units)) {
							if (enemy_units[_ei].alive) {
								var _d = abs(enemy_units[_ei].grid_col - _u.grid_col) + abs(enemy_units[_ei].grid_row - _u.grid_row);
								if (_d < _move_dist) { _move_dist = _d; _move_idx = _ei; }
							}
							_ei++;
						}
						if (_move_idx >= 0) {
							var _te = enemy_units[_move_idx];
							var _dx = sign(_te.grid_col - _u.grid_col);
							var _dy = sign(_te.grid_row - _u.grid_row);
							var _new_col = _u.grid_col;
							var _new_row = _u.grid_row;
							if (abs(_te.grid_col - _u.grid_col) >= abs(_te.grid_row - _u.grid_row)) {
								_new_col = _u.grid_col + _dx;
							} else {
								_new_row = _u.grid_row + _dy;
							}
							var _can_move = true;
							if (_new_col < 0 || _new_col >= grid_cols || _new_row < 0 || _new_row >= grid_rows) _can_move = false;
							var _ci = 0;
							while (_ci < array_length(board_units) && _can_move) {
								if (_ci != _bi && board_units[_ci].alive && board_units[_ci].grid_col == _new_col && board_units[_ci].grid_row == _new_row) {
									_can_move = false;
								}
								_ci++;
							}
							_ci = 0;
							while (_ci < array_length(enemy_units) && _can_move) {
								if (enemy_units[_ci].alive && enemy_units[_ci].grid_col == _new_col && enemy_units[_ci].grid_row == _new_row) {
									_can_move = false;
								}
								_ci++;
							}
							if (_can_move) {
								_u.grid_col = _new_col;
								_u.grid_row = _new_row;
							}
							_u.atk_cooldown = 2;
						}
					}
				}
			}
			_bi++;
		}

		// --- Process each enemy unit ---
		var _ei = 0;
		while (_ei < array_length(enemy_units)) {
			var _e = enemy_units[_ei];
			if (!_e.alive) { _ei++; continue; }

			_e.atk_cooldown--;

			if (_e.atk_cooldown <= 0) {
				var _nearest_idx = -1;
				var _nearest_dist = 9999;
				var _pi = 0;
				while (_pi < array_length(board_units)) {
					if (board_units[_pi].alive) {
						var _d = abs(board_units[_pi].grid_col - _e.grid_col) + abs(board_units[_pi].grid_row - _e.grid_row);
						if (_d <= _e.base_range && _d < _nearest_dist) {
							_nearest_dist = _d;
							_nearest_idx = _pi;
						}
					}
					_pi++;
				}
				if (_nearest_idx >= 0) {
					var _target = board_units[_nearest_idx];
					var _dmg = _e.atk;
					if (_target.dmg_reduction > 0) {
						_dmg = floor(_dmg * (1 - _target.dmg_reduction));
					}
					_target.hp -= _dmg;
					_e.atk_cooldown = 3;
					if (_e.base_range > 1) {
						array_push(projectiles, {
							x: _e.draw_x, y: _e.draw_y,
							tx: _target.draw_x, ty: _target.draw_y,
							color: unit_colors[_e.unit_type],
							timer: 12, max_timer: 12, size: cell_size * 0.1
						});
					} else {
						array_push(attack_anims, {
							unit_ref: _e, ox: _e.draw_x, oy: _e.draw_y,
							tx: _target.draw_x, ty: _target.draw_y,
							timer: 12, max_timer: 12
						});
					}
					array_push(damage_numbers, {
						x: _target.draw_x, y: _target.draw_y - cell_size * 0.4,
						text: string(_dmg), timer: 40,
						col: make_colour_rgb(255, 50, 50)
					});
					if (_target.hp <= 0) {
						_target.alive = false;
						array_push(death_anims, {
							x: _target.draw_x, y: _target.draw_y,
							r: cell_size * 0.38, color: unit_colors[_target.unit_type],
							letter: unit_letters[_target.unit_type],
							timer: 20, max_timer: 20
						});
					}
				}
				else {
					var _move_idx = -1;
					var _move_dist = 9999;
					_pi = 0;
					while (_pi < array_length(board_units)) {
						if (board_units[_pi].alive) {
							var _d = abs(board_units[_pi].grid_col - _e.grid_col) + abs(board_units[_pi].grid_row - _e.grid_row);
							if (_d < _move_dist) { _move_dist = _d; _move_idx = _pi; }
						}
						_pi++;
					}
					if (_move_idx >= 0) {
						var _tp = board_units[_move_idx];
						var _dx = sign(_tp.grid_col - _e.grid_col);
						var _dy = sign(_tp.grid_row - _e.grid_row);
						var _new_col = _e.grid_col;
						var _new_row = _e.grid_row;
						if (abs(_tp.grid_col - _e.grid_col) >= abs(_tp.grid_row - _e.grid_row)) {
							_new_col = _e.grid_col + _dx;
						} else {
							_new_row = _e.grid_row + _dy;
						}
						var _can_move = true;
						if (_new_col < 0 || _new_col >= grid_cols || _new_row < 0 || _new_row >= grid_rows) _can_move = false;
						var _ci = 0;
						while (_ci < array_length(enemy_units) && _can_move) {
							if (_ci != _ei && enemy_units[_ci].alive && enemy_units[_ci].grid_col == _new_col && enemy_units[_ci].grid_row == _new_row) {
								_can_move = false;
							}
							_ci++;
						}
						_ci = 0;
						while (_ci < array_length(board_units) && _can_move) {
							if (board_units[_ci].alive && board_units[_ci].grid_col == _new_col && board_units[_ci].grid_row == _new_row) {
								_can_move = false;
							}
							_ci++;
						}
						if (_can_move) {
							_e.grid_col = _new_col;
							_e.grid_row = _new_row;
						}
						_e.atk_cooldown = 2;
					}
				}
			}
			_ei++;
		}
	}

	// --- Check battle end ---
	var _player_alive = 0;
	var _bi = 0;
	while (_bi < array_length(board_units)) {
		if (board_units[_bi].alive) _player_alive++;
		_bi++;
	}
	var _enemy_alive = 0;
	var _ei = 0;
	while (_ei < array_length(enemy_units)) {
		if (enemy_units[_ei].alive) _enemy_alive++;
		_ei++;
	}

	if (_enemy_alive == 0 || _player_alive == 0) {
		round_won = (_enemy_alive == 0);
		game_state = 3;
		result_timer = result_timer_max;

		if (round_won) {
			// Win rewards
			gold += 3 + 1; // base + win bonus
			points += current_round * 10 + enemies_killed;
			current_round++;
		} else {
			// Lose — game over
			points += enemies_killed;
			pending_game_over = true;
		}

		// Restore surviving player units (remove dead ones, reset HP for survivors)
		var _new_board = [];
		_bi = 0;
		while (_bi < array_length(board_units)) {
			if (board_units[_bi].alive) {
				// Recalculate base stats from star level (strip synergy bonuses)
				var _u = board_units[_bi];
				var _base_hp = unit_stats[_u.unit_type][UNIT_HP] * _u.star;
				var _base_atk = unit_stats[_u.unit_type][UNIT_ATK] * _u.star;
				_u.max_hp = _base_hp;
				_u.hp = _base_hp;
				_u.atk = _base_atk;
				_u.atk_cooldown = 0;
				_u.dmg_reduction = 0;
				_u.has_crit = false;
				_u.splash_mult = 1;
				_u.heal_bonus = 0;
				// Move units back to player rows if they moved
				if (_u.grid_row < player_rows_start) {
					_u.grid_row = player_rows_start;
					// Find an open column
					var _found = false;
					var _cc = 0;
					while (_cc < grid_cols && !_found) {
						var _slot_free = true;
						var _ni = 0;
						while (_ni < array_length(_new_board)) {
							if (_new_board[_ni].grid_col == _cc && _new_board[_ni].grid_row == _u.grid_row) {
								_slot_free = false;
								break;
							}
							_ni++;
						}
						if (_slot_free) {
							_u.grid_col = _cc;
							_found = true;
						}
						_cc++;
					}
					if (!_found) {
						_u.grid_row = player_rows_start + 1;
						_cc = 0;
						while (_cc < grid_cols) {
							var _slot_free2 = true;
							var _ni2 = 0;
							while (_ni2 < array_length(_new_board)) {
								if (_new_board[_ni2].grid_col == _cc && _new_board[_ni2].grid_row == _u.grid_row) {
									_slot_free2 = false;
									break;
								}
								_ni2++;
							}
							if (_slot_free2) { _u.grid_col = _cc; break; }
							_cc++;
						}
					}
				}
				array_push(_new_board, _u);
			}
			_bi++;
		}
		board_units = _new_board;
	}

	// --- Update damage number timers ---
	var _di = array_length(damage_numbers) - 1;
	while (_di >= 0) {
		damage_numbers[_di].timer--;
		damage_numbers[_di].y -= 0.5;
		if (damage_numbers[_di].timer <= 0) {
			array_delete(damage_numbers, _di, 1);
		}
		_di--;
	}
}

// ============================================================
// STATE 3: ROUND RESULT
// ============================================================
if (game_state == 3) {
	result_timer--;

	if (result_timer <= 0) {
		if (pending_game_over) {
			// Transition to game over
			game_state = 4;
			final_score = points;
			pending_game_over = false;
			if (!score_submitted) {
				score_submitted = true;
				api_submit_score(points, undefined);
			}
		} else {
			// Continue to next shop phase
			game_state = 1;
			spawn_wave = true; // Spawn next wave for preview
			shop_items = [];
			var _si = 0;
			while (_si < shop_slots) {
				array_push(shop_items, irandom(NUM_UNIT_TYPES - 1));
				_si++;
			}
			shop_timer = shop_timer_max;
		}
	}

	if (device_mouse_check_button_pressed(0, mb_left)) {
		result_timer = 0;
	}
}

// ============================================================
// STATE 4: GAME OVER
// ============================================================
if (game_state == 4) {
	if (!score_submitted) {
		score_submitted = true;
		final_score = points;
		api_submit_score(points, undefined);
	}

	// Tap to restart
	if (device_mouse_check_button_pressed(0, mb_left)) {
		// Reset everything
		gold = 5;
		current_round = 1;
		points = 0;
		total_enemies_killed = 0;
		board_units = [];
		enemy_units = [];
		score_submitted = false;
		pending_game_over = false;
		damage_numbers = [];

		game_state = 1;
		spawn_wave = true;
		shop_items = [];
		var _si = 0;
		while (_si < shop_slots) {
			array_push(shop_items, irandom(NUM_UNIT_TYPES - 1));
			_si++;
		}
		shop_timer = shop_timer_max;
	}
}

// --- Update damage numbers in all states ---
if (game_state != 2) {
	var _di = array_length(damage_numbers) - 1;
	while (_di >= 0) {
		damage_numbers[_di].timer--;
		damage_numbers[_di].y -= 0.5;
		if (damage_numbers[_di].timer <= 0) {
			array_delete(damage_numbers, _di, 1);
		}
		_di--;
	}
}
