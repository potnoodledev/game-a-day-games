
var _gw = GRID_W;
var _gh = GRID_H;
var _bs = BOARD_SIZE;

// --- PULSE TIMER ---
pulse_timer += 0.05;
if (pulse_timer > 6.28) pulse_timer -= 6.28;

// --- NEW CARD HIGHLIGHT ---
if (new_card_timer > 0) new_card_timer--;
if (new_card_timer <= 0) new_card_idx = -1;

// --- MESSAGE TIMER ---
if (message_timer > 0) {
    message_timer--;
    if (message_timer <= 0) message = "";
}

// --- DAMAGE PARTICLES ---
var _pi = ds_list_size(dmg_particles) - 1;
while (_pi >= 0) {
    var _p = dmg_particles[| _pi];
    _p[3] -= 1;
    if (_p[3] <= 0) {
        ds_list_delete(dmg_particles, _pi);
    } else {
        _p[2] -= 0.5;
        dmg_particles[| _pi] = _p;
    }
    _pi--;
}

// --- SUMMON ANIMATION ---
if (summon_anim_active) {
    summon_anim_timer++;
    if (summon_anim_timer >= summon_anim_duration) {
        summon_anim_active = false;
        if (game_state == 5) game_state = 2;
    }
    exit;
}

// --- MOVE ANIMATION ---
if (move_anim_active) {
    move_anim_timer++;
    if (move_anim_timer >= move_anim_duration) {
        move_anim_active = false;
        if (game_state == 5) game_state = 2;
    }
    exit;
}

// --- COMBAT ANIMATION ---
if (combat_anim_active) {
    combat_anim_timer++;
    if (combat_anim_timer >= combat_anim_duration) {
        combat_anim_active = false;
        if (game_state == 5) game_state = 2; // resume AI
    }
    exit;
}

// =============================================
// PLAYER TURN
// =============================================
if (game_state == 1) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _pressed = device_mouse_check_button_pressed(0, mb_left);

    if (_pressed) {
        var _ww = window_get_width();
        var _wh = window_get_height();

        // Board geometry
        var _cell = min(floor((_ww - 20) / _gw), floor((_wh * 0.55) / _gh));
        var _board_w = _cell * _gw;
        var _board_h = _cell * _gh;
        var _bx = floor((_ww - _board_w) * 0.5);
        var _by = floor(_wh * 0.06);

        // Card hand geometry
        var _card_w = min(72, (_ww - 40) / MAX_HAND);
        var _card_h = _card_w * 1.4;
        var _hand_total_w = player_hand_count * (_card_w + 6);
        var _hand_x = floor((_ww - _hand_total_w) * 0.5);
        var _hand_y = _wh - _card_h - 10;

        // --- END TURN button (above cards, right side) ---
        var _info_y = _by + _board_h + 4;
        var _btn_w = max(90, _ww * 0.2);
        var _btn_h = max(32, _wh * 0.045);
        var _btn_x = _ww - _btn_w - 10;
        var _btn_y = _info_y + 2;

        if (_mx >= _btn_x && _mx <= _btn_x + _btn_w && _my >= _btn_y && _my <= _btn_y + _btn_h) {
            selected_row = -1; selected_col = -1; selected_card = -1;
            selected_spell = -1; input_mode = "none";
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; valid_summons[_vi] = false; _vi++; }

            game_state = 2;
            ai_max_mana = min(turn_number, 7);
            ai_mana = ai_max_mana;
            ai_hero_power_used = false;
            ai_thinking_timer = 25;
            if (ds_list_size(ai_deck) > 0 && ai_hand_count < MAX_HAND) {
                ai_hand[ai_hand_count] = ai_deck[| 0];
                ds_list_delete(ai_deck, 0);
                ai_hand_count++;
            }
            var _ri = 0; while (_ri < _bs) { board_has_acted[_ri] = false; _ri++; }
            message = "AI's turn...";
            message_timer = 40;
        }
        // --- HERO POWER button (below End Turn) ---
        else if (input_mode != "hero_power") {
            var _hp_btn_w = max(80, _ww * 0.18);
            var _hp_btn_h = max(30, _wh * 0.04);
            var _hp_btn_x = _ww - _hp_btn_w - 10;
            var _hp_btn_y = _btn_y + _btn_h + 4;

            if (_mx >= _hp_btn_x && _mx <= _hp_btn_x + _hp_btn_w && _my >= _hp_btn_y && _my <= _hp_btn_y + _hp_btn_h) {
                input_mode = "hero_power";
                selected_card = -1; selected_row = -1; selected_col = -1; selected_spell = -1;
                var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; valid_summons[_vi] = false; _vi++; }
                // Only highlight targets if usable
                if (!hero_power_used && player_mana >= 2) {
                    _vi = 0;
                    while (_vi < _bs) {
                        if (board_type[_vi] != PIECE_NONE && board_owner[_vi] == 1) valid_moves[_vi] = true;
                        _vi++;
                    }
                }
            }
        }

        // Board cell
        var _col = floor((_mx - _bx) / _cell);
        var _row = floor((_my - _by) / _cell);
        var _on_board = (_col >= 0 && _col < _gw && _row >= 0 && _row < _gh);
        var _idx = _on_board ? (_row * _gw + _col) : -1;

        // Card tap
        var _tapped_card = -1;
        var _ci = 0;
        while (_ci < player_hand_count) {
            var _cx = _hand_x + _ci * (_card_w + 6);
            if (_mx >= _cx && _mx <= _cx + _card_w && _my >= _hand_y && _my <= _hand_y + _card_h) {
                _tapped_card = _ci;
            }
            _ci++;
        }

        // --- HERO POWER TARGET ---
        if (input_mode == "hero_power" && _on_board && valid_moves[_idx]) {
            player_mana -= 2;
            hero_power_used = true;
            board_hp[_idx] -= 1;
            total_damage_dealt += 1;
            points += 1;
            ds_list_add(dmg_particles, [_col, _row, 0, 35, 1, #FFAA00]);
            if (board_hp[_idx] <= 0) {
                if ((board_keyword[_idx] & KW_DEATHRATTLE) != 0) {
                    var _dr = floor(_idx / _gw); var _dc = _idx mod _gw;
                    var _adj = [[-1,0],[1,0],[0,-1],[0,1]]; var _ai3 = 0;
                    while (_ai3 < 4) {
                        var _ar = _dr + _adj[_ai3][0]; var _ac = _dc + _adj[_ai3][1];
                        if (_ar >= 0 && _ar < _gh && _ac >= 0 && _ac < _gw) {
                            var _aidx = _ar * _gw + _ac;
                            if (board_type[_aidx] != PIECE_NONE && board_owner[_aidx] == board_owner[_idx]) {
                                board_hp[_aidx] = min(board_hp[_aidx] + 2, board_max_hp[_aidx]);
                                ds_list_add(dmg_particles, [_ac, _ar, 0, 35, 2, #44FF44]);
                            }
                        }
                        _ai3++;
                    }
                }
                if (board_type[_idx] == PIECE_KING && board_owner[_idx] == 1) {
                    message = "Victory! Enemy King destroyed!"; message_timer = 300;
                    points += 25; game_state = 4;
                }
                board_type[_idx] = PIECE_NONE; board_owner[_idx] = -1;
                board_hp[_idx] = 0; board_max_hp[_idx] = 0; board_atk[_idx] = 0; board_keyword[_idx] = 0;
            }
            input_mode = "none";
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; _vi++; }
        }
        // --- SPELL TARGET ---
        else if (input_mode == "spell_target" && _on_board && valid_moves[_idx]) {
            var _spell = selected_spell;
            var _cost = ds_map_find_value(spell_costs, _spell);
            player_mana -= _cost;

            if (_spell == SPELL_FIREBALL) {
                board_hp[_idx] -= 3;
                total_damage_dealt += 3; points += 3;
                ds_list_add(dmg_particles, [_col, _row, 0, 40, 3, #FF6600]);
                if (board_hp[_idx] <= 0) {
                    if ((board_keyword[_idx] & KW_DEATHRATTLE) != 0) {
                        var _dr = floor(_idx / _gw); var _dc = _idx mod _gw;
                        var _adj = [[-1,0],[1,0],[0,-1],[0,1]]; var _ai3 = 0;
                        while (_ai3 < 4) {
                            var _ar = _dr + _adj[_ai3][0]; var _ac = _dc + _adj[_ai3][1];
                            if (_ar >= 0 && _ar < _gh && _ac >= 0 && _ac < _gw) {
                                var _aidx = _ar * _gw + _ac;
                                if (board_type[_aidx] != PIECE_NONE && board_owner[_aidx] == board_owner[_idx])
                                    board_hp[_aidx] = min(board_hp[_aidx] + 2, board_max_hp[_aidx]);
                            }
                            _ai3++;
                        }
                    }
                    if (board_type[_idx] == PIECE_KING && board_owner[_idx] == 1) {
                        message = "Victory!"; message_timer = 300; points += 25; game_state = 4;
                    }
                    board_type[_idx] = PIECE_NONE; board_owner[_idx] = -1;
                    board_hp[_idx] = 0; board_max_hp[_idx] = 0; board_atk[_idx] = 0; board_keyword[_idx] = 0;
                }
            }
            else if (_spell == SPELL_HEAL) {
                var _heal = min(3, board_max_hp[_idx] - board_hp[_idx]);
                board_hp[_idx] += _heal;
                ds_list_add(dmg_particles, [_col, _row, 0, 35, _heal, #44FF44]);
            }
            else if (_spell == SPELL_SHIELD) {
                board_max_hp[_idx] += 2; board_hp[_idx] += 2;
                ds_list_add(dmg_particles, [_col, _row, 0, 35, 2, #4488FF]);
            }
            else if (_spell == SPELL_RAGE) {
                board_atk[_idx] += 2;
                ds_list_add(dmg_particles, [_col, _row, 0, 35, 2, #FF4444]);
            }

            var _hi = selected_card;
            while (_hi < player_hand_count - 1) { player_hand[_hi] = player_hand[_hi + 1]; _hi++; }
            player_hand[player_hand_count - 1] = 0; player_hand_count--;
            if (new_card_idx == selected_card) { new_card_idx = -1; }
            else if (new_card_idx > selected_card) { new_card_idx--; }

            input_mode = "none"; selected_card = -1; selected_spell = -1;
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; _vi++; }
        }
        // --- CARD SUMMON TARGET ---
        else if (input_mode == "card" && _on_board && valid_summons[_idx]) {
            var _card_type = player_hand[selected_card];
            var _cost = piece_mana_cost[_card_type];
            if (player_mana >= _cost) {
                player_mana -= _cost;
                board_type[_idx] = _card_type; board_owner[_idx] = 0;
                board_hp[_idx] = piece_base_hp[_card_type]; board_max_hp[_idx] = piece_base_hp[_card_type];
                board_atk[_idx] = piece_base_atk[_card_type]; board_keyword[_idx] = piece_base_kw[_card_type];
                board_has_acted[_idx] = true; board_can_act[_idx] = false;

                // Battlecry
                if ((board_keyword[_idx] & KW_BATTLECRY) != 0) {
                    var _br = floor(_idx / _gw); var _bc = _idx mod _gw;
                    var _adj = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]];
                    var _bi = 0;
                    while (_bi < 8) {
                        var _ar = _br + _adj[_bi][0]; var _ac = _bc + _adj[_bi][1];
                        if (_ar >= 0 && _ar < _gh && _ac >= 0 && _ac < _gw) {
                            var _aidx = _ar * _gw + _ac;
                            if (board_type[_aidx] != PIECE_NONE && board_owner[_aidx] == 1) {
                                board_hp[_aidx] -= 1;
                                ds_list_add(dmg_particles, [_ac, _ar, 0, 35, 1, #FFAA00]);
                                if (board_hp[_aidx] <= 0) {
                                    if (board_type[_aidx] == PIECE_KING) { message = "Victory!"; message_timer = 300; points += 25; game_state = 4; }
                                    board_type[_aidx] = PIECE_NONE; board_owner[_aidx] = -1;
                                    board_hp[_aidx] = 0; board_max_hp[_aidx] = 0; board_atk[_aidx] = 0; board_keyword[_aidx] = 0;
                                }
                                break;
                            }
                        }
                        _bi++;
                    }
                }

                var _hi = selected_card;
                while (_hi < player_hand_count - 1) { player_hand[_hi] = player_hand[_hi + 1]; _hi++; }
                player_hand[player_hand_count - 1] = 0; player_hand_count--;
                if (new_card_idx == selected_card) { new_card_idx = -1; }
                else if (new_card_idx > selected_card) { new_card_idx--; }
                points += 1;

                // Trigger summon animation
                summon_anim_active = true;
                summon_anim_timer = 0;
                summon_anim_idx = _idx;
            }
            input_mode = "none"; selected_card = -1;
            var _vi = 0; while (_vi < _bs) { valid_summons[_vi] = false; valid_moves[_vi] = false; _vi++; }
        }
        // --- PIECE MOVE/ATTACK ---
        else if (input_mode == "piece" && _on_board && valid_moves[_idx]) {
            var _from = selected_row * _gw + selected_col;

            if (board_type[_idx] != PIECE_NONE && board_owner[_idx] == 1) {
                // COMBAT — start lunge animation
                combat_anim_active = true;
                combat_anim_timer = 0;
                combat_anim_from_idx = _from;
                combat_anim_to_idx = _idx;
                combat_anim_type = board_type[_from];
                combat_anim_owner = 0;
                combat_anim_phase = 0;

                var _atk_dmg = board_atk[_from];
                var _def_dmg = board_atk[_idx];
                board_hp[_idx] -= _atk_dmg;
                board_hp[_from] -= _def_dmg;
                total_damage_dealt += _atk_dmg; points += _atk_dmg;
                board_has_acted[_from] = true;

                ds_list_add(dmg_particles, [_col, _row, 0, 40, _atk_dmg, #FF4444]);
                ds_list_add(dmg_particles, [selected_col, selected_row, 0, 40, _def_dmg, #FFAA00]);

                var _def_dead = (board_hp[_idx] <= 0);
                var _atk_dead = (board_hp[_from] <= 0);

                // Deathrattle
                if (_def_dead && (board_keyword[_idx] & KW_DEATHRATTLE) != 0) {
                    var _dr2 = floor(_idx / _gw); var _dc2 = _idx mod _gw;
                    var _adj = [[-1,0],[1,0],[0,-1],[0,1]]; var _ai3 = 0;
                    while (_ai3 < 4) {
                        var _ar = _dr2 + _adj[_ai3][0]; var _ac = _dc2 + _adj[_ai3][1];
                        if (_ar >= 0 && _ar < _gh && _ac >= 0 && _ac < _gw) {
                            var _aidx = _ar * _gw + _ac;
                            if (board_type[_aidx] != PIECE_NONE && board_owner[_aidx] == board_owner[_idx])
                                board_hp[_aidx] = min(board_hp[_aidx] + 2, board_max_hp[_aidx]);
                        }
                        _ai3++;
                    }
                }
                if (_atk_dead && (board_keyword[_from] & KW_DEATHRATTLE) != 0) {
                    var _dr2 = floor(_from / _gw); var _dc2 = _from mod _gw;
                    var _adj = [[-1,0],[1,0],[0,-1],[0,1]]; var _ai3 = 0;
                    while (_ai3 < 4) {
                        var _ar = _dr2 + _adj[_ai3][0]; var _ac = _dc2 + _adj[_ai3][1];
                        if (_ar >= 0 && _ar < _gh && _ac >= 0 && _ac < _gw) {
                            var _aidx = _ar * _gw + _ac;
                            if (board_type[_aidx] != PIECE_NONE && board_owner[_aidx] == board_owner[_from])
                                board_hp[_aidx] = min(board_hp[_aidx] + 2, board_max_hp[_aidx]);
                        }
                        _ai3++;
                    }
                }

                if (_def_dead && board_type[_idx] == PIECE_KING && board_owner[_idx] == 1) {
                    message = "Victory! Enemy King destroyed!"; message_timer = 300; points += 25; game_state = 4;
                }
                if (_atk_dead && board_type[_from] == PIECE_KING && board_owner[_from] == 0) {
                    message = "Defeat! Your King fell!"; message_timer = 300; game_state = 4;
                }

                if (_def_dead) {
                    if (!_atk_dead) {
                        board_type[_idx] = board_type[_from]; board_owner[_idx] = board_owner[_from];
                        board_hp[_idx] = board_hp[_from]; board_max_hp[_idx] = board_max_hp[_from];
                        board_atk[_idx] = board_atk[_from]; board_keyword[_idx] = board_keyword[_from];
                        board_has_acted[_idx] = true; board_can_act[_idx] = board_can_act[_from];
                    } else {
                        board_type[_idx] = PIECE_NONE; board_owner[_idx] = -1;
                        board_hp[_idx] = 0; board_max_hp[_idx] = 0; board_atk[_idx] = 0; board_keyword[_idx] = 0;
                    }
                    board_type[_from] = PIECE_NONE; board_owner[_from] = -1;
                    board_hp[_from] = 0; board_max_hp[_from] = 0; board_atk[_from] = 0; board_keyword[_from] = 0;
                } else if (_atk_dead) {
                    board_type[_from] = PIECE_NONE; board_owner[_from] = -1;
                    board_hp[_from] = 0; board_max_hp[_from] = 0; board_atk[_from] = 0; board_keyword[_from] = 0;
                }
            } else {
                // MOVE — start slide animation
                move_anim_active = true;
                move_anim_timer = 0;
                move_anim_from_idx = _from;
                move_anim_to_idx = _idx;
                move_anim_type = board_type[_from];
                move_anim_owner = 0;

                board_type[_idx] = board_type[_from]; board_owner[_idx] = board_owner[_from];
                board_hp[_idx] = board_hp[_from]; board_max_hp[_idx] = board_max_hp[_from];
                board_atk[_idx] = board_atk[_from]; board_keyword[_idx] = board_keyword[_from];
                board_has_acted[_idx] = true; board_can_act[_idx] = board_can_act[_from];
                board_type[_from] = PIECE_NONE; board_owner[_from] = -1;
                board_hp[_from] = 0; board_max_hp[_from] = 0; board_atk[_from] = 0; board_keyword[_from] = 0;
            }

            input_mode = "none"; selected_row = -1; selected_col = -1;
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; _vi++; }
        }
        // --- TAP CARD ---
        else if (_tapped_card >= 0) {
            var _card = player_hand[_tapped_card];
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; valid_summons[_vi] = false; _vi++; }
            selected_row = -1; selected_col = -1;
            selected_card = _tapped_card;

            if (_card >= 10) {
                var _cost = ds_map_find_value(spell_costs, _card);
                if (player_mana >= _cost) {
                    selected_spell = _card;
                    input_mode = "spell_target";
                    if (_card == SPELL_FIREBALL) {
                        _vi = 0; while (_vi < _bs) { if (board_type[_vi] != PIECE_NONE && board_owner[_vi] == 1) valid_moves[_vi] = true; _vi++; }
                    } else if (_card == SPELL_HEAL) {
                        _vi = 0; while (_vi < _bs) { if (board_type[_vi] != PIECE_NONE && board_owner[_vi] == 0 && board_hp[_vi] < board_max_hp[_vi]) valid_moves[_vi] = true; _vi++; }
                    } else if (_card == SPELL_SHIELD) {
                        _vi = 0; while (_vi < _bs) { if (board_type[_vi] != PIECE_NONE && board_owner[_vi] == 0) valid_moves[_vi] = true; _vi++; }
                    } else if (_card == SPELL_RAGE) {
                        _vi = 0; while (_vi < _bs) { if (board_type[_vi] != PIECE_NONE && board_owner[_vi] == 0) valid_moves[_vi] = true; _vi++; }
                    }
                } else {
                    // Not enough mana — select for info only
                    input_mode = "card";
                    selected_spell = -1;
                }
            } else {
                var _cost = piece_mana_cost[_card];
                input_mode = "card";
                if (player_mana >= _cost) {
                    // Valid summon: empty cells in back 2 rows (rows 4-5 for player)
                    _vi = 0;
                    while (_vi < _bs) {
                        var _sr = floor(_vi / _gw);
                        if (board_type[_vi] == PIECE_NONE && _sr >= _gh - 2) {
                            valid_summons[_vi] = true;
                        }
                        _vi++;
                    }
                }
                // else: card selected for info display, no valid summons
            }
        }
        // --- TAP OWN PIECE ---
        else if (_on_board && board_type[_idx] != PIECE_NONE && board_owner[_idx] == 0
                 && !board_has_acted[_idx] && board_can_act[_idx]) {
            selected_row = _row; selected_col = _col;
            selected_card = -1; selected_spell = -1; input_mode = "piece";
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; valid_summons[_vi] = false; _vi++; }

            // Taunt check
            var _enemy_has_taunt = false;
            _vi = 0;
            while (_vi < _bs) {
                if (board_type[_vi] != PIECE_NONE && board_owner[_vi] == 1 && (board_keyword[_vi] & KW_TAUNT) != 0) { _enemy_has_taunt = true; break; }
                _vi++;
            }

            var _ptype = board_type[_idx];

            // === MOVEMENT RULES PER PIECE TYPE ===

            if (_ptype == PIECE_PAWN) {
                // Forward 1 (toward enemy = row-1 for player)
                if (_row - 1 >= 0) {
                    var _fwd = (_row - 1) * _gw + _col;
                    if (board_type[_fwd] == PIECE_NONE) valid_moves[_fwd] = true;
                }
                // Attack diagonally forward
                if (_row - 1 >= 0 && _col - 1 >= 0) {
                    var _dl = (_row - 1) * _gw + (_col - 1);
                    if (board_type[_dl] != PIECE_NONE && board_owner[_dl] == 1) {
                        if (!_enemy_has_taunt || (board_keyword[_dl] & KW_TAUNT) != 0) valid_moves[_dl] = true;
                    }
                }
                if (_row - 1 >= 0 && _col + 1 < _gw) {
                    var _dr = (_row - 1) * _gw + (_col + 1);
                    if (board_type[_dr] != PIECE_NONE && board_owner[_dr] == 1) {
                        if (!_enemy_has_taunt || (board_keyword[_dr] & KW_TAUNT) != 0) valid_moves[_dr] = true;
                    }
                }
            }
            else if (_ptype == PIECE_KNIGHT) {
                // L-shaped jumps
                var _km = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]];
                var _ki = 0;
                while (_ki < 8) {
                    var _nr = _row + _km[_ki][0]; var _nc = _col + _km[_ki][1];
                    if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                        var _ni = _nr * _gw + _nc;
                        if (board_type[_ni] == PIECE_NONE) valid_moves[_ni] = true;
                        else if (board_owner[_ni] == 1) {
                            if (!_enemy_has_taunt || (board_keyword[_ni] & KW_TAUNT) != 0) valid_moves[_ni] = true;
                        }
                    }
                    _ki++;
                }
            }
            else if (_ptype == PIECE_BISHOP) {
                // Diagonal movement (up to 2 steps)
                var _dirs = [[-1,-1],[-1,1],[1,-1],[1,1]];
                var _di = 0;
                while (_di < 4) {
                    var _dr2 = _dirs[_di][0]; var _dc2 = _dirs[_di][1];
                    var _step = 1;
                    while (_step <= 2) {
                        var _nr = _row + _dr2 * _step; var _nc = _col + _dc2 * _step;
                        if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                            var _ni = _nr * _gw + _nc;
                            if (board_type[_ni] == PIECE_NONE) { valid_moves[_ni] = true; }
                            else {
                                if (board_owner[_ni] == 1 && (!_enemy_has_taunt || (board_keyword[_ni] & KW_TAUNT) != 0))
                                    valid_moves[_ni] = true;
                                break;
                            }
                        }
                        _step++;
                    }
                    _di++;
                }
            }
            else if (_ptype == PIECE_ROOK) {
                // Orthogonal movement (up to 2 steps)
                var _dirs = [[-1,0],[1,0],[0,-1],[0,1]];
                var _di = 0;
                while (_di < 4) {
                    var _dr2 = _dirs[_di][0]; var _dc2 = _dirs[_di][1];
                    var _step = 1;
                    while (_step <= 2) {
                        var _nr = _row + _dr2 * _step; var _nc = _col + _dc2 * _step;
                        if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                            var _ni = _nr * _gw + _nc;
                            if (board_type[_ni] == PIECE_NONE) { valid_moves[_ni] = true; }
                            else {
                                if (board_owner[_ni] == 1 && (!_enemy_has_taunt || (board_keyword[_ni] & KW_TAUNT) != 0))
                                    valid_moves[_ni] = true;
                                break;
                            }
                        }
                        _step++;
                    }
                    _di++;
                }
            }
            else if (_ptype == PIECE_KING) {
                // 1 step any direction
                var _dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]];
                var _di = 0;
                while (_di < 8) {
                    var _nr = _row + _dirs[_di][0]; var _nc = _col + _dirs[_di][1];
                    if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                        var _ni = _nr * _gw + _nc;
                        if (board_type[_ni] == PIECE_NONE) valid_moves[_ni] = true;
                        else if (board_owner[_ni] == 1) {
                            if (!_enemy_has_taunt || (board_keyword[_ni] & KW_TAUNT) != 0) valid_moves[_ni] = true;
                        }
                    }
                    _di++;
                }
            }
        }
        // --- DESELECT ---
        else {
            // Show "not enough mana" if tapping board with an unaffordable card/hero power
            if (_on_board) {
                if (input_mode == "card" && selected_card >= 0) {
                    var _card2 = player_hand[selected_card];
                    var _cost2 = (_card2 >= 10) ? ds_map_find_value(spell_costs, _card2) : piece_mana_cost[_card2];
                    if (player_mana < _cost2) {
                        message = "Not enough mana! (need " + string(_cost2) + ")";
                        message_timer = 60;
                    }
                }
                else if (input_mode == "hero_power") {
                    if (hero_power_used) { message = "Hero Power already used!"; message_timer = 60; }
                    else if (player_mana < 2) { message = "Not enough mana! (need 2)"; message_timer = 60; }
                }
            }
            input_mode = "none"; selected_row = -1; selected_col = -1; selected_card = -1; selected_spell = -1;
            var _vi = 0; while (_vi < _bs) { valid_moves[_vi] = false; valid_summons[_vi] = false; _vi++; }
        }
    }
}

// =============================================
// AI TURN
// =============================================
if (game_state == 2) {
    ai_thinking_timer--;
    if (ai_thinking_timer <= 0) {
        var _did_something = false;

        // 1. Play minion cards
        if (!_did_something && ai_hand_count > 0) {
            var _best_card = -1; var _best_card_idx = -1;
            var _ci = 0;
            while (_ci < ai_hand_count) {
                var _card = ai_hand[_ci];
                if (_card < 10) {
                    var _cost = piece_mana_cost[_card];
                    if (_cost <= ai_mana && _card > (_best_card < 10 ? _best_card : 0)) { _best_card = _card; _best_card_idx = _ci; }
                }
                _ci++;
            }
            if (_best_card_idx >= 0) {
                // AI summons in back 2 rows (rows 0-1)
                var _best_spot = -1; var _best_spot_score = -999;
                var _si = 0;
                while (_si < _bs) {
                    var _sr = floor(_si / _gw);
                    if (board_type[_si] == PIECE_NONE && _sr <= 1) {
                        var _sc = _si mod _gw;
                        var _score = (2 - abs(_sc - 2)) + _sr; // prefer center, then front
                        if (_score > _best_spot_score) { _best_spot_score = _score; _best_spot = _si; }
                    }
                    _si++;
                }
                if (_best_spot >= 0) {
                    var _cost = piece_mana_cost[_best_card]; ai_mana -= _cost;
                    board_type[_best_spot] = _best_card; board_owner[_best_spot] = 1;
                    board_hp[_best_spot] = piece_base_hp[_best_card]; board_max_hp[_best_spot] = piece_base_hp[_best_card];
                    board_atk[_best_spot] = piece_base_atk[_best_card]; board_keyword[_best_spot] = piece_base_kw[_best_card];
                    board_has_acted[_best_spot] = true; board_can_act[_best_spot] = false;
                    // Battlecry
                    if ((board_keyword[_best_spot] & KW_BATTLECRY) != 0) {
                        var _br = floor(_best_spot / _gw); var _bc = _best_spot mod _gw;
                        var _adj = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[-1,1],[1,-1],[1,1]]; var _bi = 0;
                        while (_bi < 8) {
                            var _ar = _br + _adj[_bi][0]; var _ac = _bc + _adj[_bi][1];
                            if (_ar >= 0 && _ar < _gh && _ac >= 0 && _ac < _gw) {
                                var _aidx = _ar * _gw + _ac;
                                if (board_type[_aidx] != PIECE_NONE && board_owner[_aidx] == 0) {
                                    board_hp[_aidx] -= 1;
                                    ds_list_add(dmg_particles, [_ac, _ar, 0, 35, 1, #FFAA00]);
                                    if (board_hp[_aidx] <= 0) {
                                        if (board_type[_aidx] == PIECE_KING) { message = "Defeat!"; message_timer = 300; game_state = 4; }
                                        board_type[_aidx] = PIECE_NONE; board_owner[_aidx] = -1;
                                        board_hp[_aidx] = 0; board_max_hp[_aidx] = 0; board_atk[_aidx] = 0;
                                    }
                                    break;
                                }
                            }
                            _bi++;
                        }
                    }
                    // Summon animation
                    summon_anim_active = true;
                    summon_anim_timer = 0;
                    summon_anim_idx = _best_spot;
                    game_state = 5; // pause for animation
                    var _hi = _best_card_idx;
                    while (_hi < ai_hand_count - 1) { ai_hand[_hi] = ai_hand[_hi + 1]; _hi++; }
                    ai_hand[ai_hand_count - 1] = 0; ai_hand_count--;
                    _did_something = true; ai_thinking_timer = 20;
                }
            }
        }

        // 2. Attack/move with pieces
        if (!_did_something) {
            var _best_score = -999; var _best_from = -1; var _best_to = -1;
            var _player_has_taunt = false;
            var _ti = 0;
            while (_ti < _bs) {
                if (board_type[_ti] != PIECE_NONE && board_owner[_ti] == 0 && (board_keyword[_ti] & KW_TAUNT) != 0) { _player_has_taunt = true; break; }
                _ti++;
            }
            var _fi = 0;
            while (_fi < _bs) {
                if (board_type[_fi] != PIECE_NONE && board_owner[_fi] == 1
                    && !board_has_acted[_fi] && board_can_act[_fi] && board_type[_fi] != PIECE_KING) {
                    var _fr = floor(_fi / _gw); var _fc = _fi mod _gw;
                    var _ptype = board_type[_fi];
                    var _moves_list = ds_list_create();

                    // AI movement rules (mirrored: pawns go DOWN)
                    if (_ptype == PIECE_PAWN) {
                        if (_fr + 1 < _gh) {
                            var _fwd = (_fr + 1) * _gw + _fc;
                            if (board_type[_fwd] == PIECE_NONE) ds_list_add(_moves_list, _fwd);
                        }
                        if (_fr + 1 < _gh && _fc - 1 >= 0) {
                            var _dl = (_fr + 1) * _gw + (_fc - 1);
                            if (board_type[_dl] != PIECE_NONE && board_owner[_dl] == 0) ds_list_add(_moves_list, _dl);
                        }
                        if (_fr + 1 < _gh && _fc + 1 < _gw) {
                            var _dr3 = (_fr + 1) * _gw + (_fc + 1);
                            if (board_type[_dr3] != PIECE_NONE && board_owner[_dr3] == 0) ds_list_add(_moves_list, _dr3);
                        }
                    }
                    else if (_ptype == PIECE_KNIGHT) {
                        var _km = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]; var _ki = 0;
                        while (_ki < 8) {
                            var _nr = _fr + _km[_ki][0]; var _nc = _fc + _km[_ki][1];
                            if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                                var _ni2 = _nr * _gw + _nc;
                                if (board_type[_ni2] == PIECE_NONE || board_owner[_ni2] == 0) ds_list_add(_moves_list, _ni2);
                            }
                            _ki++;
                        }
                    }
                    else if (_ptype == PIECE_BISHOP) {
                        var _dirs = [[-1,-1],[-1,1],[1,-1],[1,1]]; var _di2 = 0;
                        while (_di2 < 4) {
                            var _step = 1;
                            while (_step <= 2) {
                                var _nr = _fr + _dirs[_di2][0] * _step; var _nc = _fc + _dirs[_di2][1] * _step;
                                if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                                    var _ni2 = _nr * _gw + _nc;
                                    if (board_type[_ni2] == PIECE_NONE) ds_list_add(_moves_list, _ni2);
                                    else { if (board_owner[_ni2] == 0) ds_list_add(_moves_list, _ni2); break; }
                                }
                                _step++;
                            }
                            _di2++;
                        }
                    }
                    else if (_ptype == PIECE_ROOK) {
                        var _dirs = [[-1,0],[1,0],[0,-1],[0,1]]; var _di2 = 0;
                        while (_di2 < 4) {
                            var _step = 1;
                            while (_step <= 2) {
                                var _nr = _fr + _dirs[_di2][0] * _step; var _nc = _fc + _dirs[_di2][1] * _step;
                                if (_nr >= 0 && _nr < _gh && _nc >= 0 && _nc < _gw) {
                                    var _ni2 = _nr * _gw + _nc;
                                    if (board_type[_ni2] == PIECE_NONE) ds_list_add(_moves_list, _ni2);
                                    else { if (board_owner[_ni2] == 0) ds_list_add(_moves_list, _ni2); break; }
                                }
                                _step++;
                            }
                            _di2++;
                        }
                    }

                    var _mi = 0;
                    while (_mi < ds_list_size(_moves_list)) {
                        var _ti2 = _moves_list[| _mi]; var _score = 0;
                        if (board_type[_ti2] != PIECE_NONE && board_owner[_ti2] == 0) {
                            if (_player_has_taunt && (board_keyword[_ti2] & KW_TAUNT) == 0) { _mi++; continue; }
                            _score += board_atk[_fi] * 3;
                            if (board_hp[_ti2] <= board_atk[_fi]) _score += 10;
                            if (board_type[_ti2] == PIECE_KING) _score += 100;
                            if (board_hp[_fi] <= board_atk[_ti2]) _score -= 8;
                        } else if (board_type[_ti2] == PIECE_NONE) {
                            _score = floor(_ti2 / _gw) + (2 - abs((_ti2 mod _gw) - 2)) * 0.3;
                        } else { _mi++; continue; }
                        if (_score > _best_score) { _best_score = _score; _best_from = _fi; _best_to = _ti2; }
                        _mi++;
                    }
                    ds_list_destroy(_moves_list);
                }
                _fi++;
            }
            if (_best_from >= 0 && _best_to >= 0) {
                board_has_acted[_best_from] = true;
                if (board_type[_best_to] != PIECE_NONE && board_owner[_best_to] == 0) {
                    // AI combat with animation
                    combat_anim_active = true; combat_anim_timer = 0;
                    combat_anim_from_idx = _best_from; combat_anim_to_idx = _best_to;
                    combat_anim_type = board_type[_best_from]; combat_anim_owner = 1;
                    game_state = 5; // paused for animation

                    var _atk_dmg = board_atk[_best_from]; var _def_dmg = board_atk[_best_to];
                    board_hp[_best_to] -= _atk_dmg; board_hp[_best_from] -= _def_dmg;
                    var _tc = _best_to mod _gw; var _tr = floor(_best_to / _gw);
                    var _fc2 = _best_from mod _gw; var _fr2 = floor(_best_from / _gw);
                    ds_list_add(dmg_particles, [_tc, _tr, 0, 40, _atk_dmg, #FF4444]);
                    ds_list_add(dmg_particles, [_fc2, _fr2, 0, 40, _def_dmg, #FFAA00]);
                    var _def_dead = (board_hp[_best_to] <= 0); var _atk_dead = (board_hp[_best_from] <= 0);
                    if (_def_dead && board_type[_best_to] == PIECE_KING) { message = "Defeat!"; message_timer = 300; game_state = 4; }
                    if (_def_dead) {
                        if (!_atk_dead) {
                            board_type[_best_to] = board_type[_best_from]; board_owner[_best_to] = board_owner[_best_from];
                            board_hp[_best_to] = board_hp[_best_from]; board_max_hp[_best_to] = board_max_hp[_best_from];
                            board_atk[_best_to] = board_atk[_best_from]; board_keyword[_best_to] = board_keyword[_best_from];
                            board_has_acted[_best_to] = true; board_can_act[_best_to] = board_can_act[_best_from];
                        } else {
                            board_type[_best_to] = PIECE_NONE; board_owner[_best_to] = -1;
                            board_hp[_best_to] = 0; board_max_hp[_best_to] = 0; board_atk[_best_to] = 0;
                        }
                        board_type[_best_from] = PIECE_NONE; board_owner[_best_from] = -1;
                        board_hp[_best_from] = 0; board_max_hp[_best_from] = 0; board_atk[_best_from] = 0;
                    } else if (_atk_dead) {
                        board_type[_best_from] = PIECE_NONE; board_owner[_best_from] = -1;
                        board_hp[_best_from] = 0; board_max_hp[_best_from] = 0; board_atk[_best_from] = 0;
                    }
                } else {
                    // AI move with animation
                    move_anim_active = true; move_anim_timer = 0;
                    move_anim_from_idx = _best_from; move_anim_to_idx = _best_to;
                    move_anim_type = board_type[_best_from]; move_anim_owner = 1;
                    game_state = 5;

                    board_type[_best_to] = board_type[_best_from]; board_owner[_best_to] = board_owner[_best_from];
                    board_hp[_best_to] = board_hp[_best_from]; board_max_hp[_best_to] = board_max_hp[_best_from];
                    board_atk[_best_to] = board_atk[_best_from]; board_keyword[_best_to] = board_keyword[_best_from];
                    board_has_acted[_best_to] = true; board_can_act[_best_to] = board_can_act[_best_from];
                    board_type[_best_from] = PIECE_NONE; board_owner[_best_from] = -1;
                    board_hp[_best_from] = 0; board_max_hp[_best_from] = 0; board_atk[_best_from] = 0;
                }
                _did_something = true; ai_thinking_timer = 18;
            }
        }

        // 3. Hero power
        if (!_did_something && !ai_hero_power_used && ai_mana >= 2) {
            var _best_target = -1; var _best_hp = 999;
            var _ti = 0;
            while (_ti < _bs) {
                if (board_type[_ti] != PIECE_NONE && board_owner[_ti] == 0 && board_hp[_ti] < _best_hp) { _best_hp = board_hp[_ti]; _best_target = _ti; }
                _ti++;
            }
            if (_best_target >= 0) {
                ai_mana -= 2; ai_hero_power_used = true;
                board_hp[_best_target] -= 1;
                var _tc = _best_target mod _gw; var _tr = floor(_best_target / _gw);
                ds_list_add(dmg_particles, [_tc, _tr, 0, 35, 1, #FF6600]);
                if (board_hp[_best_target] <= 0) {
                    if (board_type[_best_target] == PIECE_KING && board_owner[_best_target] == 0) { message = "Defeat!"; message_timer = 300; game_state = 4; }
                    board_type[_best_target] = PIECE_NONE; board_owner[_best_target] = -1;
                    board_hp[_best_target] = 0; board_max_hp[_best_target] = 0; board_atk[_best_target] = 0;
                }
                _did_something = true; ai_thinking_timer = 15;
            }
        }

        // 4. Spells
        if (!_did_something && ai_hand_count > 0) {
            var _ci = 0;
            while (_ci < ai_hand_count) {
                var _card = ai_hand[_ci];
                if (_card >= 10) {
                    var _cost = ds_map_find_value(spell_costs, _card);
                    if (_cost <= ai_mana) {
                        var _target = -1;
                        if (_card == SPELL_FIREBALL) {
                            var _best_hp2 = 999; var _ti = 0;
                            while (_ti < _bs) { if (board_type[_ti] != PIECE_NONE && board_owner[_ti] == 0 && board_hp[_ti] < _best_hp2) { _best_hp2 = board_hp[_ti]; _target = _ti; } _ti++; }
                            if (_target >= 0) { ai_mana -= _cost; board_hp[_target] -= 3;
                                var _tc = _target mod _gw; var _tr = floor(_target / _gw);
                                ds_list_add(dmg_particles, [_tc, _tr, 0, 40, 3, #FF6600]);
                                if (board_hp[_target] <= 0) { if (board_type[_target] == PIECE_KING) { message = "Defeat!"; message_timer = 300; game_state = 4; } board_type[_target] = PIECE_NONE; board_owner[_target] = -1; board_hp[_target] = 0; board_max_hp[_target] = 0; board_atk[_target] = 0; }
                            }
                        } else if (_card == SPELL_HEAL) {
                            var _ti = 0; while (_ti < _bs) { if (board_type[_ti] != PIECE_NONE && board_owner[_ti] == 1 && board_hp[_ti] < board_max_hp[_ti]) { _target = _ti; break; } _ti++; }
                            if (_target >= 0) { ai_mana -= _cost; board_hp[_target] = min(board_hp[_target] + 3, board_max_hp[_target]); }
                        } else if (_card == SPELL_SHIELD) {
                            var _ti = 0; while (_ti < _bs) { if (board_type[_ti] != PIECE_NONE && board_owner[_ti] == 1) { _target = _ti; break; } _ti++; }
                            if (_target >= 0) { ai_mana -= _cost; board_max_hp[_target] += 2; board_hp[_target] += 2; }
                        } else if (_card == SPELL_RAGE) {
                            var _ti = 0; while (_ti < _bs) { if (board_type[_ti] != PIECE_NONE && board_owner[_ti] == 1 && board_type[_ti] != PIECE_KING) { _target = _ti; break; } _ti++; }
                            if (_target >= 0) { ai_mana -= _cost; board_atk[_target] += 2; }
                        }
                        if (_target >= 0) {
                            var _hi = _ci; while (_hi < ai_hand_count - 1) { ai_hand[_hi] = ai_hand[_hi + 1]; _hi++; }
                            ai_hand[ai_hand_count - 1] = 0; ai_hand_count--;
                            _did_something = true; ai_thinking_timer = 15; break;
                        }
                    }
                }
                _ci++;
            }
        }

        // 5. End AI turn
        if (!_did_something && game_state == 2) {
            turn_number++;
            player_max_mana = min(turn_number, 7); player_mana = player_max_mana;
            hero_power_used = false;
            if (ds_list_size(player_deck) > 0 && player_hand_count < MAX_HAND) {
                player_hand[player_hand_count] = player_deck[| 0];
                ds_list_delete(player_deck, 0);
                new_card_idx = player_hand_count;
                new_card_timer = 90;
                player_hand_count++;
            }
            var _ri = 0;
            while (_ri < _bs) { board_has_acted[_ri] = false; if (board_type[_ri] != PIECE_NONE) board_can_act[_ri] = true; _ri++; }
            game_state = 1; input_mode = "none";
            message = "Turn " + string(turn_number) + " - Mana: " + string(player_mana);
            message_timer = 60;
        }
    }
}

// =============================================
// GAME OVER
// =============================================
if (game_state == 4 && !game_over_submitted) {
    game_over_submitted = true;
    api_submit_score(points, function(_status, _ok, _result, _payload) {});
}

if (game_state == 4 && message_timer <= 0) {
    if (device_mouse_check_button_pressed(0, mb_left)) game_restart();
}
