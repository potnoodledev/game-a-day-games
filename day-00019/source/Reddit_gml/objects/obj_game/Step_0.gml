
// === TINY TOWN Step ===
if (game_state != 1) exit;

// --- COMBO ZONE COMPUTATION (bitmask — tiles can be in multiple zones) ---
combo_count = 0;
for (var _i = 0; _i < grid_total; _i++) {
    cell_combo_flags[_i] = 0;
    cell_combo[_i] = 1.0;
}
for (var _i = 0; _i < grid_total; _i++) {
    var _t = grid_type[_i];
    if (_t == EMPTY) continue;
    var _col = _i mod grid_cols;
    var _row = _i div grid_cols;
    var _flags = 0;

    // Check all 4 neighbors, accumulate ALL matching combo flags
    // Left
    if (_col > 0) {
        var _nt = grid_type[_i - 1];
        if ((_t == HOUSE && _nt == SHOP) || (_t == SHOP && _nt == HOUSE)) _flags = _flags | CFLAG_MARKET;
        if (_t == SHOP && _nt == SHOP) _flags = _flags | CFLAG_PLAZA;
        if (_t == TOWER && _nt == SHOP) _flags = _flags | CFLAG_BIZ;
        if (_t == HOUSE && _nt == PARK) _flags = _flags | CFLAG_SUBURB;
        if (_t == PARK && _nt == PARK) _flags = _flags | CFLAG_RESERVE;
    }
    // Right
    if (_col < grid_cols - 1) {
        var _nt2 = grid_type[_i + 1];
        if ((_t == HOUSE && _nt2 == SHOP) || (_t == SHOP && _nt2 == HOUSE)) _flags = _flags | CFLAG_MARKET;
        if (_t == SHOP && _nt2 == SHOP) _flags = _flags | CFLAG_PLAZA;
        if (_t == TOWER && _nt2 == SHOP) _flags = _flags | CFLAG_BIZ;
        if (_t == HOUSE && _nt2 == PARK) _flags = _flags | CFLAG_SUBURB;
        if (_t == PARK && _nt2 == PARK) _flags = _flags | CFLAG_RESERVE;
    }
    // Up
    if (_row > 0) {
        var _nt3 = grid_type[_i - grid_cols];
        if ((_t == HOUSE && _nt3 == SHOP) || (_t == SHOP && _nt3 == HOUSE)) _flags = _flags | CFLAG_MARKET;
        if (_t == SHOP && _nt3 == SHOP) _flags = _flags | CFLAG_PLAZA;
        if (_t == TOWER && _nt3 == SHOP) _flags = _flags | CFLAG_BIZ;
        if (_t == HOUSE && _nt3 == PARK) _flags = _flags | CFLAG_SUBURB;
        if (_t == PARK && _nt3 == PARK) _flags = _flags | CFLAG_RESERVE;
    }
    // Down
    if (_row < grid_rows - 1) {
        var _nt4 = grid_type[_i + grid_cols];
        if ((_t == HOUSE && _nt4 == SHOP) || (_t == SHOP && _nt4 == HOUSE)) _flags = _flags | CFLAG_MARKET;
        if (_t == SHOP && _nt4 == SHOP) _flags = _flags | CFLAG_PLAZA;
        if (_t == TOWER && _nt4 == SHOP) _flags = _flags | CFLAG_BIZ;
        if (_t == HOUSE && _nt4 == PARK) _flags = _flags | CFLAG_SUBURB;
        if (_t == PARK && _nt4 == PARK) _flags = _flags | CFLAG_RESERVE;
    }
    cell_combo_flags[_i] = _flags;

    // Each active combo flag adds +0.5x
    if (_flags != 0) {
        var _mult = 1.0;
        if ((_flags & CFLAG_MARKET) != 0)  _mult += 0.5;
        if ((_flags & CFLAG_PLAZA) != 0)   _mult += 0.5;
        if ((_flags & CFLAG_BIZ) != 0)     _mult += 0.5;
        if ((_flags & CFLAG_SUBURB) != 0)  _mult += 0.5;
        if ((_flags & CFLAG_RESERVE) != 0) _mult += 0.5;
        cell_combo[_i] = _mult;
        combo_count++;
    }
}

// --- STAR RATING ---
var _rp = 0;
for (var _i = 0; _i < grid_total; _i++) {
    if (grid_type[_i] != EMPTY) {
        _rp += 2;
        _rp += grid_level[_i] * 2;
        if (cell_combo[_i] > 1.0) _rp += 3;
    }
}
star_rating = 0;
if (_rp >= 5) star_rating = 1;
if (_rp >= 15) star_rating = 2;
if (_rp >= 30) star_rating = 3;
if (_rp >= 50) star_rating = 4;
if (_rp >= 75) star_rating = 5;

// Check star milestones
if (star_rating > stars_reached) {
    if (star_rating >= 1 && stars_reached < 1) {
        coins += 50; points += 50; total_earned += 50;
        star_flash = 150; star_flash_text = "1 STAR! +50c";
    }
    if (star_rating >= 2 && stars_reached < 2) {
        coins += 100; points += 100; total_earned += 100;
        star_flash = 150; star_flash_text = "2 STARS! Tower Unlocked! +100c";
    }
    if (star_rating >= 3 && stars_reached < 3) {
        coins += 200; points += 200; total_earned += 200;
        star_income_mult = 1.5;
        star_flash = 150; star_flash_text = "3 STARS! Income x1.5! +200c";
    }
    if (star_rating >= 4 && stars_reached < 4) {
        coins += 500; points += 500; total_earned += 500;
        star_flash = 150; star_flash_text = "4 STARS! +500c";
    }
    if (star_rating >= 5 && stars_reached < 5) {
        coins += 1000; points += 1000; total_earned += 1000;
        star_income_mult = 2.0;
        star_flash = 150; star_flash_text = "5 STARS! Income x2! +1000c";
    }
    stars_reached = star_rating;
}
if (star_flash > 0) star_flash--;

// --- INCOME TICK ---
income_timer++;
if (income_timer >= income_interval) {
    income_timer = 0;
    var _total_income = 0;

    for (var _i = 0; _i < grid_total; _i++) {
        var _type = grid_type[_i];
        if (_type == EMPTY || _type == PARK) continue;

        // Check if stormed
        if (evt_type == EVENT_STORM && evt_target == _i) continue;

        var _lvl = grid_level[_i];
        var _base = build_income[_type];
        // Level multiplier: +50% per level
        var _income = _base * (1 + _lvl * 0.5);

        // Park adjacency bonus
        var _col = _i mod grid_cols;
        var _row = _i div grid_cols;
        var _park_bonus = 0;
        if (_col > 0 && grid_type[_i - 1] == PARK) _park_bonus += 1 + grid_level[_i - 1];
        if (_col < grid_cols - 1 && grid_type[_i + 1] == PARK) _park_bonus += 1 + grid_level[_i + 1];
        if (_row > 0 && grid_type[_i - grid_cols] == PARK) _park_bonus += 1 + grid_level[_i - grid_cols];
        if (_row < grid_rows - 1 && grid_type[_i + grid_cols] == PARK) _park_bonus += 1 + grid_level[_i + grid_cols];
        _income += _park_bonus;

        // Combo zone multiplier
        if (cell_combo[_i] > 1.0) {
            _income *= cell_combo[_i];
        }

        // Star income multiplier
        _income *= star_income_mult;

        // Boom event multiplier
        if (evt_type == EVENT_BOOM && evt_target == _i) {
            _income *= 10;
        }

        _income = round(_income);
        if (_income > 0) {
            _total_income += _income;
            var _col2 = _i mod grid_cols;
            var _row2 = _i div grid_cols;
            var _fx = grid_ox + _col2 * cell_size + cell_size * 0.5;
            var _fy = grid_oy + _row2 * cell_size;
            for (var _f = 0; _f < max_floats; _f++) {
                if (ft_life[_f] <= 0) {
                    ft_x[_f] = _fx;
                    ft_y[_f] = _fy;
                    ft_text[_f] = "+" + string(_income);
                    if (evt_type == EVENT_BOOM && evt_target == _i) {
                        ft_r[_f] = 255; ft_g[_f] = 200; ft_b[_f] = 0;
                    } else if (cell_combo[_i] > 1.0) {
                        ft_r[_f] = 255; ft_g[_f] = 180; ft_b[_f] = 50;
                    } else {
                        ft_r[_f] = 100; ft_g[_f] = 255; ft_b[_f] = 100;
                    }
                    ft_life[_f] = 60;
                    break;
                }
            }
        }
    }

    coins += _total_income;
    points += _total_income;
    total_earned += _total_income;
}

// --- VISITOR SYSTEM ---
visitor_spawn_timer++;
if (visitor_spawn_timer >= 180) {
    visitor_spawn_timer = 0;
    var _house_count = 0;
    var _shop_cells = array_create(0);
    for (var _i = 0; _i < grid_total; _i++) {
        if (grid_type[_i] == HOUSE) _house_count++;
        if (grid_type[_i] == SHOP || grid_type[_i] == TOWER) {
            array_push(_shop_cells, _i);
        }
    }

    if (_house_count > 0 && array_length(_shop_cells) > 0) {
        var _spawned = 0;
        for (var _i = 0; _i < grid_total && _spawned < _house_count; _i++) {
            if (grid_type[_i] != HOUSE) continue;
            for (var _v = 0; _v < max_visitors; _v++) {
                if (!vis_active[_v]) {
                    var _hcol = _i mod grid_cols;
                    var _hrow = _i div grid_cols;
                    vis_x[_v] = grid_ox + _hcol * cell_size + cell_size * 0.5;
                    vis_y[_v] = grid_oy + _hrow * cell_size + cell_size * 0.5;
                    var _ti = _shop_cells[irandom(array_length(_shop_cells) - 1)];
                    var _tcol = _ti mod grid_cols;
                    var _trow = _ti div grid_cols;
                    vis_tx[_v] = grid_ox + _tcol * cell_size + cell_size * 0.5;
                    vis_ty[_v] = grid_oy + _trow * cell_size + cell_size * 0.5;
                    vis_active[_v] = true;
                    vis_vip[_v] = false;
                    vis_speed[_v] = 1 + random(1);
                    vis_timer[_v] = 0;
                    _spawned++;
                    break;
                }
            }
        }
    }
}

// Spawn VIP visitor from event
if (evt_type == EVENT_VIP && evt_duration > 0 && evt_duration mod 120 == 0) {
    var _shop_cells2 = array_create(0);
    for (var _i = 0; _i < grid_total; _i++) {
        if (grid_type[_i] == SHOP || grid_type[_i] == TOWER) {
            array_push(_shop_cells2, _i);
        }
    }
    if (array_length(_shop_cells2) > 0) {
        for (var _v = 0; _v < max_visitors; _v++) {
            if (!vis_active[_v]) {
                vis_x[_v] = grid_ox + irandom(grid_cols - 1) * cell_size + cell_size * 0.5;
                vis_y[_v] = grid_oy - cell_size;
                var _ti = _shop_cells2[irandom(array_length(_shop_cells2) - 1)];
                var _tcol = _ti mod grid_cols;
                var _trow = _ti div grid_cols;
                vis_tx[_v] = grid_ox + _tcol * cell_size + cell_size * 0.5;
                vis_ty[_v] = grid_oy + _trow * cell_size + cell_size * 0.5;
                vis_active[_v] = true;
                vis_vip[_v] = true;
                vis_speed[_v] = 2;
                vis_timer[_v] = 0;
                break;
            }
        }
    }
}

// Update visitors
for (var _v = 0; _v < max_visitors; _v++) {
    if (!vis_active[_v]) continue;

    var _dx = vis_tx[_v] - vis_x[_v];
    var _dy = vis_ty[_v] - vis_y[_v];
    var _dist = sqrt(_dx * _dx + _dy * _dy);

    if (_dist < 4) {
        var _bonus = 5;
        if (vis_vip[_v]) _bonus = 25;
        coins += _bonus;
        points += _bonus;
        total_earned += _bonus;
        for (var _f = 0; _f < max_floats; _f++) {
            if (ft_life[_f] <= 0) {
                ft_x[_f] = vis_x[_v];
                ft_y[_f] = vis_y[_v] - 10;
                ft_text[_f] = "+" + string(_bonus);
                if (vis_vip[_v]) {
                    ft_r[_f] = 255; ft_g[_f] = 215; ft_b[_f] = 0;
                } else {
                    ft_r[_f] = 0; ft_g[_f] = 200; ft_b[_f] = 255;
                }
                ft_life[_f] = 45;
                break;
            }
        }
        vis_active[_v] = false;
    } else {
        vis_x[_v] += (_dx / _dist) * vis_speed[_v];
        vis_y[_v] += (_dy / _dist) * vis_speed[_v];
        vis_timer[_v]++;
        if (vis_timer[_v] > 600) vis_active[_v] = false;
    }
}

// --- FLOAT TEXT UPDATE ---
for (var _f = 0; _f < max_floats; _f++) {
    if (ft_life[_f] > 0) {
        ft_y[_f] -= 0.8;
        ft_life[_f]--;
    }
}

// --- YEAR PROGRESSION ---
year_timer++;
if (year_timer >= year_duration) {
    year_timer = 0;
    year++;
    year_flash = 90;
    if (year > max_years) {
        game_state = 2;
        api_submit_score(points, function(_status, _ok, _result) {});
    }
}
if (year_flash > 0) year_flash--;

// --- EVENT SYSTEM ---
evt_timer++;
if (evt_type != EVENT_NONE) {
    evt_duration--;
    evt_flash++;
    if (evt_duration <= 0) {
        evt_type = EVENT_NONE;
        evt_target = -1;
        evt_text = "";
    }
}

if (evt_timer >= evt_interval && evt_type == EVENT_NONE) {
    evt_timer = 0;
    var _roll = irandom(2);

    var _buildings = array_create(0);
    for (var _i = 0; _i < grid_total; _i++) {
        if (grid_type[_i] != EMPTY && grid_type[_i] != PARK) {
            array_push(_buildings, _i);
        }
    }

    if (_roll == 0 && array_length(_buildings) > 0) {
        evt_type = EVENT_BOOM;
        evt_target = _buildings[irandom(array_length(_buildings) - 1)];
        evt_duration = 300;
        evt_flash = 0;
        evt_text = "BOOM! " + build_names[grid_type[evt_target]] + " x10!";
    } else if (_roll == 1 && array_length(_buildings) > 0) {
        evt_type = EVENT_STORM;
        evt_target = _buildings[irandom(array_length(_buildings) - 1)];
        evt_duration = 600;
        evt_flash = 0;
        evt_text = "STORM! " + build_names[grid_type[evt_target]] + " offline!";
    } else {
        evt_type = EVENT_VIP;
        evt_target = -1;
        evt_duration = 600;
        evt_flash = 0;
        evt_text = "VIP visitors incoming!";
    }
}

// --- TOUCH INPUT ---
if (device_mouse_check_button_pressed(0, mb_left)) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    tap_x = _mx;
    tap_y = _my;
    tap_timer = 10;

    if (menu_open) {
        var _handled = false;
        var _menu_w = cell_size * 4.5;
        var _menu_h = cell_size * 3;
        var _menu_x = (window_width - _menu_w) * 0.5;
        var _menu_y = (window_height - _menu_h) * 0.5;

        if (menu_mode == 0) {
            var _btn_h = _menu_h * 0.2;
            var _btn_margin = 4;
            var _btn_y_start = _menu_y + _menu_h * 0.25;

            for (var _b = 1; _b <= 4; _b++) {
                var _by = _btn_y_start + (_b - 1) * (_btn_h + _btn_margin);
                if (_mx >= _menu_x + 8 && _mx <= _menu_x + _menu_w - 8 &&
                    _my >= _by && _my <= _by + _btn_h) {
                    var _cost = build_cost[_b];
                    _cost = round(_cost * (1 + (year - 1) * 0.2));
                    var _locked = (_b == TOWER && stars_reached < 2);

                    if (coins >= _cost && !_locked) {
                        coins -= _cost;
                        grid_type[menu_cell] = _b;
                        grid_level[menu_cell] = 0;
                        var _col3 = menu_cell mod grid_cols;
                        var _row3 = menu_cell div grid_cols;
                        var _fx = grid_ox + _col3 * cell_size + cell_size * 0.5;
                        var _fy = grid_oy + _row3 * cell_size;
                        for (var _f = 0; _f < max_floats; _f++) {
                            if (ft_life[_f] <= 0) {
                                ft_x[_f] = _fx;
                                ft_y[_f] = _fy;
                                ft_text[_f] = build_names[_b] + "!";
                                ft_r[_f] = 255; ft_g[_f] = 255; ft_b[_f] = 255;
                                ft_life[_f] = 45;
                                break;
                            }
                        }
                    }
                    menu_open = false;
                    _handled = true;
                    break;
                }
            }
        } else {
            var _btn_w = _menu_w * 0.6;
            var _btn_h2 = _menu_h * 0.22;
            var _btn_x = _menu_x + (_menu_w - _btn_w) * 0.5;
            var _btn_y2 = _menu_y + _menu_h * 0.65;

            if (_mx >= _btn_x && _mx <= _btn_x + _btn_w &&
                _my >= _btn_y2 && _my <= _btn_y2 + _btn_h2) {
                var _type2 = grid_type[menu_cell];
                var _lvl2 = grid_level[menu_cell];
                if (_lvl2 < 3) {
                    var _ucost = round(build_cost[_type2] * power(2, _lvl2 + 1) * (1 + (year - 1) * 0.2));
                    if (coins >= _ucost) {
                        coins -= _ucost;
                        grid_level[menu_cell]++;
                        var _col4 = menu_cell mod grid_cols;
                        var _row4 = menu_cell div grid_cols;
                        var _fx2 = grid_ox + _col4 * cell_size + cell_size * 0.5;
                        var _fy2 = grid_oy + _row4 * cell_size;
                        for (var _f2 = 0; _f2 < max_floats; _f2++) {
                            if (ft_life[_f2] <= 0) {
                                ft_x[_f2] = _fx2;
                                ft_y[_f2] = _fy2;
                                ft_text[_f2] = "LV " + string(grid_level[menu_cell]) + "!";
                                ft_r[_f2] = 255; ft_g[_f2] = 220; ft_b[_f2] = 50;
                                ft_life[_f2] = 45;
                                break;
                            }
                        }
                    }
                }
                menu_open = false;
                _handled = true;
            }

            if (!_handled) {
                var _dem_y = _btn_y2 + _btn_h2 + 8;
                var _dem_w = _btn_w * 0.5;
                var _dem_x = _menu_x + (_menu_w - _dem_w) * 0.5;
                if (_mx >= _dem_x && _mx <= _dem_x + _dem_w &&
                    _my >= _dem_y && _my <= _dem_y + _btn_h2 * 0.7) {
                    grid_type[menu_cell] = EMPTY;
                    grid_level[menu_cell] = 0;
                    menu_open = false;
                    _handled = true;
                }
            }
        }

        if (!_handled) {
            menu_open = false;
        }
    } else {
        var _gcol = floor((_mx - grid_ox) / cell_size);
        var _grow = floor((_my - grid_oy) / cell_size);

        if (_gcol >= 0 && _gcol < grid_cols && _grow >= 0 && _grow < grid_rows) {
            var _ci = _grow * grid_cols + _gcol;
            menu_cell = _ci;
            menu_anim = 0;

            if (grid_type[_ci] == EMPTY) {
                menu_open = true;
                menu_mode = 0;
            } else {
                menu_open = true;
                menu_mode = 1;
            }
        }
    }
}

if (tap_timer > 0) tap_timer--;
