/// Step_0 — Game logic

if (game_state != 1) exit;

var _w = window_get_width();
var _h = window_get_height();
scr_w = _w;
scr_h = _h;

// --- Perspective helpers (stored for draw) ---
var _vp_x = _w * 0.5;
var _vp_y = _h * 0.28;
var _base_y = _h * 0.92;

// --- Wave system ---
if (!wave_active && wave_enemies_alive <= 0) {
    wave_timer += 1;
    if (wave_timer >= wave_delay) {
        wave += 1;
        wave_active = true;
        wave_timer = 0;
        spawn_timer = 0;
        enemies_to_spawn = 4 + wave * 2;
        if (enemies_to_spawn > 30) enemies_to_spawn = 30;

        // Spawn float text for wave
        for (var fi = 0; fi < float_max; fi++) {
            if (!float_active[fi]) {
                float_active[fi] = true;
                float_x[fi] = _w * 0.5;
                float_y[fi] = _h * 0.15;
                float_text[fi] = "WAVE " + string(wave);
                float_life[fi] = 90;
                float_col[fi] = c_yellow;
                break;
            }
        }
    }
}

// --- Spawn enemies ---
if (wave_active && enemies_to_spawn > 0) {
    spawn_timer += 1;
    // Faster spawns at higher waves
    var _interval = spawn_interval - wave * 2;
    if (_interval < 12) _interval = 12;

    if (spawn_timer >= _interval) {
        spawn_timer = 0;

        // Find free slot
        for (var i = 0; i < enemy_max; i++) {
            if (!enemy_active[i]) {
                enemy_active[i] = true;
                // Pick lane: -1, 0, or 1
                var _lane_roll = irandom(2);
                if (_lane_roll == 0) enemy_lane[i] = -1;
                else if (_lane_roll == 1) enemy_lane[i] = 0;
                else enemy_lane[i] = 1;

                enemy_depth[i] = 0.0;
                enemy_x_off[i] = random_range(-10, 10);
                enemy_hit[i] = 0;

                // Type based on wave
                var _type = 0;
                if (wave >= 3) {
                    var _roll = irandom(100);
                    if (_roll < 20) _type = 1; // fast
                    if (wave >= 5 && _roll >= 80) _type = 2; // tank
                }
                enemy_type[i] = _type;

                if (_type == 0) { // basic
                    enemy_hp[i] = 2 + floor(wave * 0.5);
                    enemy_hp_max[i] = enemy_hp[i];
                    enemy_speed[i] = 0.0025 + wave * 0.0002;
                } else if (_type == 1) { // fast
                    enemy_hp[i] = 1 + floor(wave * 0.3);
                    enemy_hp_max[i] = enemy_hp[i];
                    enemy_speed[i] = 0.005 + wave * 0.0003;
                } else { // tank
                    enemy_hp[i] = 5 + wave;
                    enemy_hp_max[i] = enemy_hp[i];
                    enemy_speed[i] = 0.0015 + wave * 0.0001;
                }

                enemies_to_spawn -= 1;
                wave_enemies_alive += 1;
                break;
            }
        }
    }
    if (enemies_to_spawn <= 0) wave_active = false;
}

// --- Update enemies ---
for (var i = 0; i < enemy_max; i++) {
    if (!enemy_active[i]) continue;

    enemy_depth[i] += enemy_speed[i];
    if (enemy_hit[i] > 0) enemy_hit[i] -= 1;

    // Reached player
    if (enemy_depth[i] >= 1.0) {
        enemy_active[i] = false;
        wave_enemies_alive -= 1;
        player_hp -= 1;
        damage_flash = 10;

        if (player_hp <= 0) {
            game_state = 2;
            // Submit final score
            api_submit_score(points, undefined);
        }
    }
}

// --- Tower shooting ---
for (var ti = 0; ti < tower_count; ti++) {
    if (!tower_has[ti]) continue;

    tower_timer[ti] += 1;
    if (tower_timer[ti] < tower_fire_rate[ti]) continue;

    // Find nearest enemy in range
    var _t_depth = tower_slot_depth[ti];
    var _t_range = tower_range[ti];
    var _best = -1;
    var _best_depth = -1;

    for (var ei = 0; ei < enemy_max; ei++) {
        if (!enemy_active[ei]) continue;
        var _ed = enemy_depth[ei];
        if (abs(_ed - _t_depth) <= _t_range) {
            if (_ed > _best_depth) {
                _best_depth = _ed;
                _best = ei;
            }
        }
    }

    if (_best >= 0) {
        tower_timer[ti] = 0;

        // Damage enemy
        enemy_hp[_best] -= tower_damage[ti];
        enemy_hit[_best] = 6;

        // Spawn projectile visual
        for (var _pi = 0; _pi < proj_max; _pi++) {
            if (!proj_active[_pi]) {
                proj_active[_pi] = true;
                // Tower screen position (must match Draw_64)
                var _td = tower_slot_depth[ti];
                var _tscale = 0.1 + _td * 0.9;
                var _road_hw = lerp(15, _w * 0.38, _td);
                proj_sx[_pi] = _vp_x + tower_side[ti] * (_road_hw + 20 * _tscale);
                proj_sy[_pi] = lerp(_vp_y, _base_y, _td);
                // Enemy screen position
                var _escale = 0.1 + _best_depth * 0.9;
                var _eroad_hw = lerp(15, _w * 0.38, _best_depth);
                proj_tx[_pi] = _vp_x + enemy_lane[_best] * _eroad_hw * 0.5 + enemy_x_off[_best] * _escale;
                proj_ty[_pi] = lerp(_vp_y, _base_y, _best_depth);
                proj_life[_pi] = proj_life_max[_pi];
                break;
            }
        }

        // Check kill
        if (enemy_hp[_best] <= 0) {
            enemy_active[_best] = false;
            wave_enemies_alive -= 1;
            total_kills += 1;

            var _reward = 10;
            if (enemy_type[_best] == 1) _reward = 8;
            if (enemy_type[_best] == 2) _reward = 25;
            gold += _reward;
            points += _reward;

            // Float text
            var _ek_sx = proj_tx[0]; // approximate
            var _ek_sy = proj_ty[0];
            for (var fi = 0; fi < float_max; fi++) {
                if (!float_active[fi]) {
                    float_active[fi] = true;
                    float_x[fi] = _vp_x + enemy_lane[_best] * 40;
                    float_y[fi] = lerp(_vp_y, _base_y, enemy_depth[_best]);
                    float_text[fi] = "+" + string(_reward);
                    float_life[fi] = 45;
                    float_col[fi] = c_lime;
                    break;
                }
            }
        }
    }
}

// --- Update projectiles ---
for (var i = 0; i < proj_max; i++) {
    if (!proj_active[i]) continue;
    proj_life[i] -= 1;
    if (proj_life[i] <= 0) proj_active[i] = false;
}

// --- Update float text ---
for (var i = 0; i < float_max; i++) {
    if (!float_active[i]) continue;
    float_y[i] -= 1;
    float_life[i] -= 1;
    if (float_life[i] <= 0) float_active[i] = false;
}

// --- Update tap effects ---
for (var i = 0; i < tap_fx_max; i++) {
    if (!tap_fx_active[i]) continue;
    tap_fx_life[i] -= 1;
    if (tap_fx_life[i] <= 0) tap_fx_active[i] = false;
}

// --- Damage flash ---
if (damage_flash > 0) damage_flash -= 1;

// --- Shoot cooldown ---
if (shoot_cooldown > 0) shoot_cooldown -= 1;

// --- Touch input ---
if (device_mouse_check_button_pressed(0, mb_left)) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    // Game over? Tap to restart
    if (game_state == 2) {
        // Reset
        player_hp = player_hp_max;
        gold = 75;
        wave = 0;
        wave_active = false;
        wave_timer = 0;
        wave_enemies_alive = 0;
        enemies_to_spawn = 0;
        total_kills = 0;
        points = 0;
        damage_flash = 0;
        show_tower_menu = false;

        for (var i = 0; i < enemy_max; i++) enemy_active[i] = false;
        for (var i = 0; i < tower_count; i++) {
            tower_has[i] = false;
            tower_level[i] = 0;
            tower_timer[i] = 0;
        }
        for (var i = 0; i < proj_max; i++) proj_active[i] = false;
        for (var i = 0; i < float_max; i++) float_active[i] = false;

        game_state = 1;
        exit;
    }

    // Tower menu tap
    if (show_tower_menu) {
        // Check buy button area (drawn at bottom center)
        var _btn_x = _w * 0.5;
        var _btn_y = _h * 0.82;
        var _btn_hw = 80;
        var _btn_hh = 25;

        if (_mx >= _btn_x - _btn_hw && _mx <= _btn_x + _btn_hw &&
            _my >= _btn_y - _btn_hh && _my <= _btn_y + _btn_hh) {

            var _si = selected_tower_slot;
            if (_si >= 0 && _si < tower_count) {
                if (!tower_has[_si] && gold >= tower_cost) {
                    tower_has[_si] = true;
                    tower_level[_si] = 1;
                    tower_timer[_si] = 0;
                    gold -= tower_cost;
                } else if (tower_has[_si]) {
                    // Upgrade
                    var _ucost = tower_cost + tower_level[_si] * 30;
                    if (gold >= _ucost) {
                        tower_level[_si] += 1;
                        tower_damage[_si] += 1;
                        tower_fire_rate[_si] = max(15, tower_fire_rate[_si] - 5);
                        tower_range[_si] = min(0.6, tower_range[_si] + 0.05);
                        gold -= _ucost;
                    }
                }
            }
            show_tower_menu = false;
            exit;
        }

        // Check close / tap elsewhere
        show_tower_menu = false;
        exit;
    }

    // Check tower slot taps (must match Draw_64 positioning)
    var _road_hw_far = 15;
    var _road_hw_near = _w * 0.38;
    for (var ti = 0; ti < tower_count; ti++) {
        var _td = tower_slot_depth[ti];
        var _tscale = 0.1 + _td * 0.9;
        var _road_hw = lerp(_road_hw_far, _road_hw_near, _td);
        var _tsx = _vp_x + tower_side[ti] * (_road_hw + 20 * _tscale);
        var _tsy = lerp(_vp_y, _base_y, _td);
        var _slot_size = 30 * _tscale + 25;

        if (abs(_mx - _tsx) < _slot_size && abs(_my - _tsy) < _slot_size) {
            selected_tower_slot = ti;
            show_tower_menu = true;
            exit;
        }
    }

    // Try shooting an enemy
    if (shoot_cooldown <= 0) {
        var _hit_any = false;
        // Find closest enemy to tap
        var _best_ei = -1;
        var _best_dist = 99999;

        for (var ei = 0; ei < enemy_max; ei++) {
            if (!enemy_active[ei]) continue;
            var _ed = enemy_depth[ei];
            var _escale = 0.1 + _ed * 0.9;
            var _eroad_hw = lerp(15, _w * 0.38, _escale);
            var _esx = _vp_x + enemy_lane[ei] * _eroad_hw * 0.5 + enemy_x_off[ei] * _escale;
            var _esy = lerp(_vp_y, _base_y, _ed);
            var _esize = 12 + 28 * _escale;

            var _dist = point_distance(_mx, _my, _esx, _esy);
            if (_dist < _esize + 15 && _dist < _best_dist) {
                _best_dist = _dist;
                _best_ei = ei;
            }
        }

        if (_best_ei >= 0) {
            // Hit enemy
            var _dmg = 2;
            enemy_hp[_best_ei] -= _dmg;
            enemy_hit[_best_ei] = 8;
            shoot_cooldown = shoot_cd_max;
            _hit_any = true;

            // Tap effect
            for (var fi = 0; fi < tap_fx_max; fi++) {
                if (!tap_fx_active[fi]) {
                    tap_fx_active[fi] = true;
                    tap_fx_x[fi] = _mx;
                    tap_fx_y[fi] = _my;
                    tap_fx_life[fi] = 10;
                    break;
                }
            }

            // Check kill
            if (enemy_hp[_best_ei] <= 0) {
                enemy_active[_best_ei] = false;
                wave_enemies_alive -= 1;
                total_kills += 1;

                var _reward = 15;
                if (enemy_type[_best_ei] == 1) _reward = 12;
                if (enemy_type[_best_ei] == 2) _reward = 35;
                gold += _reward;
                points += _reward;

                for (var fi = 0; fi < float_max; fi++) {
                    if (!float_active[fi]) {
                        float_active[fi] = true;
                        float_x[fi] = _mx;
                        float_y[fi] = _my;
                        float_text[fi] = "+" + string(_reward);
                        float_life[fi] = 45;
                        float_col[fi] = c_lime;
                        break;
                    }
                }
            }
        }

        if (!_hit_any) {
            // Missed shot - still show tap
            for (var fi = 0; fi < tap_fx_max; fi++) {
                if (!tap_fx_active[fi]) {
                    tap_fx_active[fi] = true;
                    tap_fx_x[fi] = _mx;
                    tap_fx_y[fi] = _my;
                    tap_fx_life[fi] = 8;
                    break;
                }
            }
        }
    }
}
