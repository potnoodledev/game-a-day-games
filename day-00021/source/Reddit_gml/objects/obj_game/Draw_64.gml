
var _ww = window_get_width();
var _wh = window_get_height();
var _gw = GRID_W;
var _gh = GRID_H;

// === BOARD SIZING ===
var _cell = min(floor((_ww - 20) / _gw), floor((_wh * 0.55) / _gh));
var _board_w = _cell * _gw;
var _board_h = _cell * _gh;
var _bx = floor((_ww - _board_w) * 0.5);
var _by = floor(_wh * 0.06);
var _ui_scale = min(_ww, _wh) / 420;

// Pulse value (0 to 1 oscillating)
var _pulse = (sin(pulse_timer) + 1) * 0.5;

// === BACKGROUND ===
draw_set_colour(#1a1a2e);
draw_rectangle(0, 0, _ww, _wh, false);

// === DRAW BOARD TILES ===
var _r = 0;
while (_r < _gh) {
    var _c = 0;
    while (_c < _gw) {
        var _x1 = _bx + _c * _cell;
        var _y1 = _by + _r * _cell;
        var _x2 = _x1 + _cell;
        var _y2 = _y1 + _cell;
        var _idx = _r * _gw + _c;

        if ((_r + _c) mod 2 == 0) draw_set_colour(#2d2d44);
        else draw_set_colour(#3d3d55);
        draw_rectangle(_x1, _y1, _x2, _y2, false);

        // Valid summon highlight (cyan glow)
        if (valid_summons[_idx]) {
            draw_set_alpha(0.2 + _pulse * 0.15);
            draw_set_colour(#44CCFF);
            draw_rectangle(_x1, _y1, _x2, _y2, false);
            draw_set_alpha(1.0);
        }

        // Valid move/attack highlight
        if (valid_moves[_idx]) {
            draw_set_alpha(0.25 + _pulse * 0.1);
            if (board_type[_idx] != PIECE_NONE) draw_set_colour(#FF4444);
            else draw_set_colour(#44FF44);
            draw_rectangle(_x1, _y1, _x2, _y2, false);
            draw_set_alpha(1.0);
        }

        // Selected piece highlight
        if (_r == selected_row && _c == selected_col) {
            draw_set_alpha(0.4);
            draw_set_colour(#FFFF00);
            draw_rectangle(_x1, _y1, _x2, _y2, false);
            draw_set_alpha(1.0);
        }

        _c++;
    }
    _r++;
}

// === DRAW PIECES (separate pass so animations layer on top) ===
_r = 0;
while (_r < _gh) {
    var _c = 0;
    while (_c < _gw) {
        var _idx = _r * _gw + _c;

        // Skip piece being animated (drawn separately)
        if (move_anim_active && _idx == move_anim_to_idx) { _c++; continue; }
        if (combat_anim_active && _idx == combat_anim_from_idx) { _c++; continue; }
        // Skip piece being summon-animated (drawn separately)
        if (summon_anim_active && _idx == summon_anim_idx) { _c++; continue; }

        if (board_type[_idx] != PIECE_NONE) {
            var _x1 = _bx + _c * _cell;
            var _y1 = _by + _r * _cell;
            var _pcx = _x1 + _cell * 0.5;
            var _pcy = _y1 + _cell * 0.5;
            var _pr = _cell * 0.36;
            var _ptype = board_type[_idx];
            var _powner = board_owner[_idx];

            // Actionable piece pulse glow
            var _can_act_now = (_powner == 0 && !board_has_acted[_idx] && board_can_act[_idx] && game_state == 1);
            if (_can_act_now) {
                draw_set_alpha(0.15 + _pulse * 0.15);
                draw_set_colour(#88CCFF);
                draw_circle(_pcx, _pcy, _pr + 4 + _pulse * 3, false);
                draw_set_alpha(1.0);
            }

            // Determine piece color
            var _fill_col = #4488FF;
            var _border_col = #2266CC;
            if (_powner == 1) { _fill_col = #CC3333; _border_col = #AA2222; }
            if (!board_can_act[_idx] || board_has_acted[_idx]) {
                if (_powner == 0) _fill_col = #335588;
                else _fill_col = #883333;
            }

            // Draw piece shape based on type
            draw_set_colour(_fill_col);
            if (_ptype == PIECE_PAWN) {
                // Pawn: small circle on a base (like a pawn)
                draw_circle(_pcx, _pcy - _pr * 0.2, _pr * 0.5, false);
                draw_rectangle(_pcx - _pr * 0.6, _pcy + _pr * 0.15, _pcx + _pr * 0.6, _pcy + _pr * 0.55, false);
                draw_triangle(_pcx - _pr * 0.35, _pcy + _pr * 0.15, _pcx + _pr * 0.35, _pcy + _pr * 0.15, _pcx, _pcy - _pr * 0.55, false);
            } else if (_ptype == PIECE_KNIGHT) {
                // Knight: L-shaped / horse-head-ish
                draw_triangle(_pcx - _pr * 0.6, _pcy + _pr * 0.6, _pcx + _pr * 0.6, _pcy + _pr * 0.6, _pcx + _pr * 0.1, _pcy - _pr * 0.7, false);
                draw_rectangle(_pcx - _pr * 0.15, _pcy - _pr * 0.7, _pcx + _pr * 0.5, _pcy - _pr * 0.2, false);
            } else if (_ptype == PIECE_BISHOP) {
                // Bishop: tall diamond / mitre shape
                draw_triangle(_pcx - _pr * 0.5, _pcy + _pr * 0.5, _pcx + _pr * 0.5, _pcy + _pr * 0.5, _pcx, _pcy - _pr * 0.75, false);
                draw_circle(_pcx, _pcy - _pr * 0.6, _pr * 0.2, false);
                draw_rectangle(_pcx - _pr * 0.6, _pcy + _pr * 0.5, _pcx + _pr * 0.6, _pcy + _pr * 0.7, false);
            } else if (_ptype == PIECE_ROOK) {
                // Rook: castle/tower shape
                draw_rectangle(_pcx - _pr * 0.55, _pcy - _pr * 0.3, _pcx + _pr * 0.55, _pcy + _pr * 0.6, false);
                draw_rectangle(_pcx - _pr * 0.65, _pcy + _pr * 0.4, _pcx + _pr * 0.65, _pcy + _pr * 0.7, false);
                // Battlements
                draw_rectangle(_pcx - _pr * 0.6, _pcy - _pr * 0.6, _pcx - _pr * 0.3, _pcy - _pr * 0.3, false);
                draw_rectangle(_pcx - _pr * 0.1, _pcy - _pr * 0.6, _pcx + _pr * 0.1, _pcy - _pr * 0.3, false);
                draw_rectangle(_pcx + _pr * 0.3, _pcy - _pr * 0.6, _pcx + _pr * 0.6, _pcy - _pr * 0.3, false);
            } else if (_ptype == PIECE_KING) {
                // King: circle with crown points
                draw_circle(_pcx, _pcy + _pr * 0.1, _pr * 0.6, false);
                draw_rectangle(_pcx - _pr * 0.6, _pcy + _pr * 0.45, _pcx + _pr * 0.6, _pcy + _pr * 0.7, false);
                // Crown
                draw_triangle(_pcx - _pr * 0.55, _pcy - _pr * 0.1, _pcx - _pr * 0.25, _pcy - _pr * 0.1, _pcx - _pr * 0.4, _pcy - _pr * 0.65, false);
                draw_triangle(_pcx - _pr * 0.15, _pcy - _pr * 0.1, _pcx + _pr * 0.15, _pcy - _pr * 0.1, _pcx, _pcy - _pr * 0.8, false);
                draw_triangle(_pcx + _pr * 0.25, _pcy - _pr * 0.1, _pcx + _pr * 0.55, _pcy - _pr * 0.1, _pcx + _pr * 0.4, _pcy - _pr * 0.65, false);
            }

            // Border outline
            draw_set_colour(_border_col);
            if (_ptype == PIECE_PAWN) {
                draw_circle(_pcx, _pcy - _pr * 0.2, _pr * 0.5, true);
                draw_rectangle(_pcx - _pr * 0.6, _pcy + _pr * 0.15, _pcx + _pr * 0.6, _pcy + _pr * 0.55, true);
            } else if (_ptype == PIECE_KNIGHT) {
                draw_triangle(_pcx - _pr * 0.6, _pcy + _pr * 0.6, _pcx + _pr * 0.6, _pcy + _pr * 0.6, _pcx + _pr * 0.1, _pcy - _pr * 0.7, true);
            } else if (_ptype == PIECE_BISHOP) {
                draw_triangle(_pcx - _pr * 0.5, _pcy + _pr * 0.5, _pcx + _pr * 0.5, _pcy + _pr * 0.5, _pcx, _pcy - _pr * 0.75, true);
            } else if (_ptype == PIECE_ROOK) {
                draw_rectangle(_pcx - _pr * 0.65, _pcy - _pr * 0.6, _pcx + _pr * 0.65, _pcy + _pr * 0.7, true);
            } else if (_ptype == PIECE_KING) {
                draw_circle(_pcx, _pcy + _pr * 0.1, _pr * 0.6, true);
            }

            // Taunt (thick gold border)
            if ((board_keyword[_idx] & KW_TAUNT) != 0) {
                draw_set_colour(#FFCC00);
                if (_ptype == PIECE_ROOK) {
                    draw_rectangle(_pcx - _pr * 0.65 - 2, _pcy - _pr * 0.6 - 2, _pcx + _pr * 0.65 + 2, _pcy + _pr * 0.7 + 2, true);
                    draw_rectangle(_pcx - _pr * 0.65 - 3, _pcy - _pr * 0.6 - 3, _pcx + _pr * 0.65 + 3, _pcy + _pr * 0.7 + 3, true);
                } else {
                    draw_circle(_pcx, _pcy, _pr + 2, true);
                    draw_circle(_pcx, _pcy, _pr + 3, true);
                }
            }

            // Piece letter
            draw_set_colour(#FFFFFF);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            var _fs = _cell / 65;
            draw_text_transformed(_pcx, _pcy - _pr * 0.1, piece_symbols[_ptype], _fs * 1.4, _fs * 1.4, 0);

            // HP bar
            var _bw = _cell * 0.65; var _bh = max(3, _cell * 0.06);
            var _bar_x = _pcx - _bw * 0.5; var _bar_y = _by + _r * _cell + _cell * 0.84;
            draw_set_colour(#333333);
            draw_rectangle(_bar_x, _bar_y, _bar_x + _bw, _bar_y + _bh, false);
            var _hp_pct = clamp(board_hp[_idx] / board_max_hp[_idx], 0, 1);
            if (_hp_pct > 0.5) draw_set_colour(#44CC44);
            else if (_hp_pct > 0.25) draw_set_colour(#CCCC44);
            else draw_set_colour(#CC4444);
            draw_rectangle(_bar_x, _bar_y, _bar_x + _bw * _hp_pct, _bar_y + _bh, false);

            // ATK/HP numbers
            var _ss = _cell / 85;
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_set_colour(#FFDD44);
            draw_text_transformed(_bx + _c * _cell + 2, _by + _r * _cell + 2, string(board_atk[_idx]), _ss, _ss, 0);
            draw_set_halign(fa_right);
            draw_set_colour(#44FF44);
            draw_text_transformed(_bx + _c * _cell + _cell - 2, _by + _r * _cell + 2, string(board_hp[_idx]), _ss, _ss, 0);

            // Keyword badge
            if ((board_keyword[_idx] & KW_TAUNT) != 0) {
                draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                draw_set_colour(#FFCC00);
                draw_text_transformed(_pcx, _by + _r * _cell + _cell * 0.98, "T", _ss * 0.7, _ss * 0.7, 0);
            }
            if ((board_keyword[_idx] & KW_DEATHRATTLE) != 0) {
                draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                draw_set_colour(#88FF88);
                draw_text_transformed(_pcx, _by + _r * _cell + _cell * 0.98, "D", _ss * 0.7, _ss * 0.7, 0);
            }
        }
        _c++;
    }
    _r++;
}

// === HELPER: Draw piece shape at position ===
// Inlined for each animation since GML HTML5 can't use closures

// === SUMMON ANIMATION (scale up from 0) ===
if (summon_anim_active) {
    var _t = clamp(summon_anim_timer / summon_anim_duration, 0, 1);
    // Elastic ease-out: overshoot then settle
    var _scale;
    if (_t < 0.6) _scale = (_t / 0.6) * 1.15;
    else _scale = 1.15 - 0.15 * ((_t - 0.6) / 0.4);

    var _sa_r = floor(summon_anim_idx / _gw);
    var _sa_c = summon_anim_idx mod _gw;
    var _ax = _bx + _sa_c * _cell + _cell * 0.5;
    var _ay = _by + _sa_r * _cell + _cell * 0.5;
    var _pr = _cell * 0.36 * _scale;
    var _ptype = board_type[summon_anim_idx];
    var _powner = board_owner[summon_anim_idx];

    // Flash glow
    if (_t < 0.4) {
        draw_set_alpha(0.5 * (1 - _t / 0.4));
        draw_set_colour(#FFFFFF);
        draw_circle(_ax, _ay, _pr + 8, false);
        draw_set_alpha(1.0);
    }

    var _fill_col = (_powner == 0) ? #4488FF : #CC3333;
    var _border_col = (_powner == 0) ? #2266CC : #AA2222;
    draw_set_colour(_fill_col);
    if (_ptype == PIECE_PAWN) {
        draw_circle(_ax, _ay - _pr * 0.2, _pr * 0.5, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.15, _ax + _pr * 0.6, _ay + _pr * 0.55, false);
        draw_triangle(_ax - _pr * 0.35, _ay + _pr * 0.15, _ax + _pr * 0.35, _ay + _pr * 0.15, _ax, _ay - _pr * 0.55, false);
    } else if (_ptype == PIECE_KNIGHT) {
        draw_triangle(_ax - _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.7, false);
        draw_rectangle(_ax - _pr * 0.15, _ay - _pr * 0.7, _ax + _pr * 0.5, _ay - _pr * 0.2, false);
    } else if (_ptype == PIECE_BISHOP) {
        draw_triangle(_ax - _pr * 0.5, _ay + _pr * 0.5, _ax + _pr * 0.5, _ay + _pr * 0.5, _ax, _ay - _pr * 0.75, false);
        draw_circle(_ax, _ay - _pr * 0.6, _pr * 0.2, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.5, _ax + _pr * 0.6, _ay + _pr * 0.7, false);
    } else if (_ptype == PIECE_ROOK) {
        draw_rectangle(_ax - _pr * 0.55, _ay - _pr * 0.3, _ax + _pr * 0.55, _ay + _pr * 0.6, false);
        draw_rectangle(_ax - _pr * 0.65, _ay + _pr * 0.4, _ax + _pr * 0.65, _ay + _pr * 0.7, false);
        draw_rectangle(_ax - _pr * 0.6, _ay - _pr * 0.6, _ax - _pr * 0.3, _ay - _pr * 0.3, false);
        draw_rectangle(_ax - _pr * 0.1, _ay - _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.3, false);
        draw_rectangle(_ax + _pr * 0.3, _ay - _pr * 0.6, _ax + _pr * 0.6, _ay - _pr * 0.3, false);
    } else if (_ptype == PIECE_KING) {
        draw_circle(_ax, _ay + _pr * 0.1, _pr * 0.6, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.45, _ax + _pr * 0.6, _ay + _pr * 0.7, false);
        draw_triangle(_ax - _pr * 0.55, _ay - _pr * 0.1, _ax - _pr * 0.25, _ay - _pr * 0.1, _ax - _pr * 0.4, _ay - _pr * 0.65, false);
        draw_triangle(_ax - _pr * 0.15, _ay - _pr * 0.1, _ax + _pr * 0.15, _ay - _pr * 0.1, _ax, _ay - _pr * 0.8, false);
        draw_triangle(_ax + _pr * 0.25, _ay - _pr * 0.1, _ax + _pr * 0.55, _ay - _pr * 0.1, _ax + _pr * 0.4, _ay - _pr * 0.65, false);
    }
    draw_set_colour(_border_col);
    if (_ptype == PIECE_PAWN) { draw_circle(_ax, _ay - _pr * 0.2, _pr * 0.5, true); }
    else if (_ptype == PIECE_KNIGHT) { draw_triangle(_ax - _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.7, true); }
    else if (_ptype == PIECE_BISHOP) { draw_triangle(_ax - _pr * 0.5, _ay + _pr * 0.5, _ax + _pr * 0.5, _ay + _pr * 0.5, _ax, _ay - _pr * 0.75, true); }
    else if (_ptype == PIECE_ROOK) { draw_rectangle(_ax - _pr * 0.65, _ay - _pr * 0.6, _ax + _pr * 0.65, _ay + _pr * 0.7, true); }
    else if (_ptype == PIECE_KING) { draw_circle(_ax, _ay + _pr * 0.1, _pr * 0.6, true); }

    draw_set_colour(#FFFFFF);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _fs = _cell / 65;
    draw_text_transformed(_ax, _ay - _pr * 0.1, piece_symbols[_ptype], _fs * 1.4 * _scale, _fs * 1.4 * _scale, 0);
}

// === MOVE ANIMATION (sliding piece) ===
if (move_anim_active) {
    var _t = clamp(move_anim_timer / move_anim_duration, 0, 1);
    // Ease-out
    _t = 1 - (1 - _t) * (1 - _t);

    var _from_r = floor(move_anim_from_idx / _gw);
    var _from_c = move_anim_from_idx mod _gw;
    var _to_r = floor(move_anim_to_idx / _gw);
    var _to_c = move_anim_to_idx mod _gw;

    var _ax = lerp(_bx + _from_c * _cell + _cell * 0.5, _bx + _to_c * _cell + _cell * 0.5, _t);
    var _ay = lerp(_by + _from_r * _cell + _cell * 0.5, _by + _to_r * _cell + _cell * 0.5, _t);
    var _pr = _cell * 0.36;
    var _ptype = move_anim_type;
    var _powner = move_anim_owner;

    var _fill_col = (_powner == 0) ? #4488FF : #CC3333;
    var _border_col = (_powner == 0) ? #2266CC : #AA2222;
    draw_set_colour(_fill_col);
    if (_ptype == PIECE_PAWN) {
        draw_circle(_ax, _ay - _pr * 0.2, _pr * 0.5, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.15, _ax + _pr * 0.6, _ay + _pr * 0.55, false);
        draw_triangle(_ax - _pr * 0.35, _ay + _pr * 0.15, _ax + _pr * 0.35, _ay + _pr * 0.15, _ax, _ay - _pr * 0.55, false);
    } else if (_ptype == PIECE_KNIGHT) {
        draw_triangle(_ax - _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.7, false);
        draw_rectangle(_ax - _pr * 0.15, _ay - _pr * 0.7, _ax + _pr * 0.5, _ay - _pr * 0.2, false);
    } else if (_ptype == PIECE_BISHOP) {
        draw_triangle(_ax - _pr * 0.5, _ay + _pr * 0.5, _ax + _pr * 0.5, _ay + _pr * 0.5, _ax, _ay - _pr * 0.75, false);
        draw_circle(_ax, _ay - _pr * 0.6, _pr * 0.2, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.5, _ax + _pr * 0.6, _ay + _pr * 0.7, false);
    } else if (_ptype == PIECE_ROOK) {
        draw_rectangle(_ax - _pr * 0.55, _ay - _pr * 0.3, _ax + _pr * 0.55, _ay + _pr * 0.6, false);
        draw_rectangle(_ax - _pr * 0.65, _ay + _pr * 0.4, _ax + _pr * 0.65, _ay + _pr * 0.7, false);
        draw_rectangle(_ax - _pr * 0.6, _ay - _pr * 0.6, _ax - _pr * 0.3, _ay - _pr * 0.3, false);
        draw_rectangle(_ax - _pr * 0.1, _ay - _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.3, false);
        draw_rectangle(_ax + _pr * 0.3, _ay - _pr * 0.6, _ax + _pr * 0.6, _ay - _pr * 0.3, false);
    } else if (_ptype == PIECE_KING) {
        draw_circle(_ax, _ay + _pr * 0.1, _pr * 0.6, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.45, _ax + _pr * 0.6, _ay + _pr * 0.7, false);
        draw_triangle(_ax - _pr * 0.55, _ay - _pr * 0.1, _ax - _pr * 0.25, _ay - _pr * 0.1, _ax - _pr * 0.4, _ay - _pr * 0.65, false);
        draw_triangle(_ax - _pr * 0.15, _ay - _pr * 0.1, _ax + _pr * 0.15, _ay - _pr * 0.1, _ax, _ay - _pr * 0.8, false);
        draw_triangle(_ax + _pr * 0.25, _ay - _pr * 0.1, _ax + _pr * 0.55, _ay - _pr * 0.1, _ax + _pr * 0.4, _ay - _pr * 0.65, false);
    }
    draw_set_colour(_border_col);
    if (_ptype == PIECE_PAWN) { draw_circle(_ax, _ay - _pr * 0.2, _pr * 0.5, true); }
    else if (_ptype == PIECE_KNIGHT) { draw_triangle(_ax - _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.7, true); }
    else if (_ptype == PIECE_BISHOP) { draw_triangle(_ax - _pr * 0.5, _ay + _pr * 0.5, _ax + _pr * 0.5, _ay + _pr * 0.5, _ax, _ay - _pr * 0.75, true); }
    else if (_ptype == PIECE_ROOK) { draw_rectangle(_ax - _pr * 0.65, _ay - _pr * 0.6, _ax + _pr * 0.65, _ay + _pr * 0.7, true); }
    else if (_ptype == PIECE_KING) { draw_circle(_ax, _ay + _pr * 0.1, _pr * 0.6, true); }

    draw_set_colour(#FFFFFF);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _fs = _cell / 65;
    draw_text_transformed(_ax, _ay - _pr * 0.1, piece_symbols[_ptype], _fs * 1.4, _fs * 1.4, 0);
}

// === COMBAT ANIMATION (lunge + snap back) ===
if (combat_anim_active) {
    var _t = clamp(combat_anim_timer / combat_anim_duration, 0, 1);
    var _from_r = floor(combat_anim_from_idx / _gw);
    var _from_c = combat_anim_from_idx mod _gw;
    var _to_r = floor(combat_anim_to_idx / _gw);
    var _to_c = combat_anim_to_idx mod _gw;

    // Lunge forward then snap back: go 60% of way then return
    var _lunge;
    if (_t < 0.5) _lunge = _t * 2 * 0.6; // 0 to 0.6
    else _lunge = (1 - _t) * 2 * 0.6; // 0.6 to 0

    var _ax = lerp(_bx + _from_c * _cell + _cell * 0.5, _bx + _to_c * _cell + _cell * 0.5, _lunge);
    var _ay = lerp(_by + _from_r * _cell + _cell * 0.5, _by + _to_r * _cell + _cell * 0.5, _lunge);
    var _pr = _cell * 0.36;
    var _ptype = combat_anim_type;
    var _powner = combat_anim_owner;

    var _fill_col = (_powner == 0) ? #4488FF : #CC3333;
    var _border_col = (_powner == 0) ? #2266CC : #AA2222;
    draw_set_colour(_fill_col);
    if (_ptype == PIECE_PAWN) {
        draw_circle(_ax, _ay - _pr * 0.2, _pr * 0.5, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.15, _ax + _pr * 0.6, _ay + _pr * 0.55, false);
        draw_triangle(_ax - _pr * 0.35, _ay + _pr * 0.15, _ax + _pr * 0.35, _ay + _pr * 0.15, _ax, _ay - _pr * 0.55, false);
    } else if (_ptype == PIECE_KNIGHT) {
        draw_triangle(_ax - _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.7, false);
        draw_rectangle(_ax - _pr * 0.15, _ay - _pr * 0.7, _ax + _pr * 0.5, _ay - _pr * 0.2, false);
    } else if (_ptype == PIECE_BISHOP) {
        draw_triangle(_ax - _pr * 0.5, _ay + _pr * 0.5, _ax + _pr * 0.5, _ay + _pr * 0.5, _ax, _ay - _pr * 0.75, false);
        draw_circle(_ax, _ay - _pr * 0.6, _pr * 0.2, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.5, _ax + _pr * 0.6, _ay + _pr * 0.7, false);
    } else if (_ptype == PIECE_ROOK) {
        draw_rectangle(_ax - _pr * 0.55, _ay - _pr * 0.3, _ax + _pr * 0.55, _ay + _pr * 0.6, false);
        draw_rectangle(_ax - _pr * 0.65, _ay + _pr * 0.4, _ax + _pr * 0.65, _ay + _pr * 0.7, false);
        draw_rectangle(_ax - _pr * 0.6, _ay - _pr * 0.6, _ax - _pr * 0.3, _ay - _pr * 0.3, false);
        draw_rectangle(_ax - _pr * 0.1, _ay - _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.3, false);
        draw_rectangle(_ax + _pr * 0.3, _ay - _pr * 0.6, _ax + _pr * 0.6, _ay - _pr * 0.3, false);
    } else if (_ptype == PIECE_KING) {
        draw_circle(_ax, _ay + _pr * 0.1, _pr * 0.6, false);
        draw_rectangle(_ax - _pr * 0.6, _ay + _pr * 0.45, _ax + _pr * 0.6, _ay + _pr * 0.7, false);
        draw_triangle(_ax - _pr * 0.55, _ay - _pr * 0.1, _ax - _pr * 0.25, _ay - _pr * 0.1, _ax - _pr * 0.4, _ay - _pr * 0.65, false);
        draw_triangle(_ax - _pr * 0.15, _ay - _pr * 0.1, _ax + _pr * 0.15, _ay - _pr * 0.1, _ax, _ay - _pr * 0.8, false);
        draw_triangle(_ax + _pr * 0.25, _ay - _pr * 0.1, _ax + _pr * 0.55, _ay - _pr * 0.1, _ax + _pr * 0.4, _ay - _pr * 0.65, false);
    }
    draw_set_colour(_border_col);
    if (_ptype == PIECE_PAWN) { draw_circle(_ax, _ay - _pr * 0.2, _pr * 0.5, true); }
    else if (_ptype == PIECE_KNIGHT) { draw_triangle(_ax - _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.6, _ay + _pr * 0.6, _ax + _pr * 0.1, _ay - _pr * 0.7, true); }
    else if (_ptype == PIECE_BISHOP) { draw_triangle(_ax - _pr * 0.5, _ay + _pr * 0.5, _ax + _pr * 0.5, _ay + _pr * 0.5, _ax, _ay - _pr * 0.75, true); }
    else if (_ptype == PIECE_ROOK) { draw_rectangle(_ax - _pr * 0.65, _ay - _pr * 0.6, _ax + _pr * 0.65, _ay + _pr * 0.7, true); }
    else if (_ptype == PIECE_KING) { draw_circle(_ax, _ay + _pr * 0.1, _pr * 0.6, true); }

    draw_set_colour(#FFFFFF);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _fs = _cell / 65;
    draw_text_transformed(_ax, _ay - _pr * 0.1, piece_symbols[_ptype], _fs * 1.4, _fs * 1.4, 0);
}

// Board border
draw_set_colour(#555577);
draw_rectangle(_bx, _by, _bx + _board_w, _by + _board_h, true);

// === DAMAGE PARTICLES ===
var _pi = 0;
while (_pi < ds_list_size(dmg_particles)) {
    var _p = dmg_particles[| _pi];
    var _px = _bx + _p[0] * _cell + _cell * 0.5;
    var _py = _by + _p[1] * _cell + _cell * 0.3 + _p[2];
    var _alpha = clamp(_p[3] / 20, 0, 1);
    draw_set_alpha(_alpha);
    draw_set_colour(_p[5]);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _ds = _cell / 50;
    var _sign = "-";
    if (_p[5] == #44FF44 || _p[5] == #4488FF) _sign = "+";
    draw_text_transformed(_px + 1, _py + 1, _sign + string(_p[4]), _ds, _ds, 0);
    draw_set_colour(#FFFFFF);
    draw_text_transformed(_px, _py, _sign + string(_p[4]), _ds, _ds, 0);
    draw_set_alpha(1.0);
    _pi++;
}

// === TOP BAR ===
draw_set_halign(fa_center); draw_set_valign(fa_top);
draw_set_colour(#FFDD44);
draw_text_transformed(_ww * 0.5, 4, "Hearthstone Chess", _ui_scale * 1.0, _ui_scale * 1.0, 0);

// === INFO BAR ===
var _info_y = _by + _board_h + 4;

// Score on right side of top bar
draw_set_halign(fa_right); draw_set_valign(fa_top);
draw_set_colour(#FFDD44);
draw_text_transformed(_ww - 8, 4, "Score: " + string(points), _ui_scale * 0.75, _ui_scale * 0.75, 0);

// Turn number on left of top bar
draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_colour(#AAAACC);
draw_text_transformed(8, 4, "Turn " + string(turn_number), _ui_scale * 0.75, _ui_scale * 0.75, 0);

// === CARD HAND ===
var _card_w = min(72, (_ww - 40) / MAX_HAND);
var _card_h = _card_w * 1.4;
var _hand_total_w = player_hand_count * (_card_w + 6);
var _hand_x = floor((_ww - _hand_total_w) * 0.5);
var _hand_y = _wh - _card_h - 10;

var _ci = 0;
while (_ci < player_hand_count) {
    var _cx = _hand_x + _ci * (_card_w + 6);
    var _card = player_hand[_ci];
    var _is_selected = (_ci == selected_card);
    var _is_new = (_ci == new_card_idx && new_card_timer > 0);

    // New card glow
    if (_is_new) {
        draw_set_alpha(0.3 + _pulse * 0.2);
        draw_set_colour(#FFFF44);
        draw_rectangle(_cx - 3, _hand_y - 5, _cx + _card_w + 3, _hand_y + _card_h + 3, false);
        draw_set_alpha(1.0);
    }

    // Selected highlight
    if (_is_selected) {
        draw_set_colour(#555588);
        draw_rectangle(_cx - 2, _hand_y - 4, _cx + _card_w + 2, _hand_y + _card_h + 2, false);
    }

    // Card bg
    if (_card >= 10) draw_set_colour(#442266);
    else draw_set_colour(#223344);
    draw_rectangle(_cx, _hand_y, _cx + _card_w, _hand_y + _card_h, false);

    // Border
    if (_is_selected) draw_set_colour(#FFFF44);
    else if (_is_new) draw_set_colour(#FFDD44);
    else draw_set_colour(#667788);
    draw_rectangle(_cx, _hand_y, _cx + _card_w, _hand_y + _card_h, true);

    var _cs = _card_w / 80;
    draw_set_halign(fa_center); draw_set_valign(fa_top);

    if (_card >= 10) {
        var _sname = ds_map_find_value(spell_names, _card);
        var _scost = ds_map_find_value(spell_costs, _card);
        var _sdesc = ds_map_find_value(spell_descs, _card);
        draw_set_halign(fa_left); draw_set_colour(#4488FF);
        draw_text_transformed(_cx + 3, _hand_y + 3, string(_scost), _cs * 1.2, _cs * 1.2, 0);
        draw_set_halign(fa_center); draw_set_colour(#CC88FF);
        draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.3, _sname, _cs * 0.9, _cs * 0.9, 0);
        draw_set_colour(#AAAACC);
        draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.55, _sdesc, _cs * 0.8, _cs * 0.8, 0);
    } else {
        var _cost = piece_mana_cost[_card];
        draw_set_halign(fa_left); draw_set_colour(#4488FF);
        draw_text_transformed(_cx + 3, _hand_y + 3, string(_cost), _cs * 1.2, _cs * 1.2, 0);
        draw_set_halign(fa_center); draw_set_colour(#FFFFFF);
        draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.2, piece_symbols[_card], _cs * 1.8, _cs * 1.8, 0);
        draw_set_colour(#CCCCEE);
        draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.5, piece_names[_card], _cs * 0.7, _cs * 0.7, 0);
        draw_set_halign(fa_left); draw_set_valign(fa_bottom); draw_set_colour(#FFDD44);
        draw_text_transformed(_cx + 3, _hand_y + _card_h - 3, string(piece_base_atk[_card]), _cs * 0.9, _cs * 0.9, 0);
        draw_set_halign(fa_right); draw_set_colour(#44FF44);
        draw_text_transformed(_cx + _card_w - 3, _hand_y + _card_h - 3, string(piece_base_hp[_card]), _cs * 0.9, _cs * 0.9, 0);
        var _kw = piece_base_kw[_card];
        if (_kw != KW_NONE) {
            draw_set_halign(fa_center); draw_set_valign(fa_top);
            if ((_kw & KW_TAUNT) != 0) { draw_set_colour(#FFCC00); draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.65, "Taunt", _cs * 0.55, _cs * 0.55, 0); }
            if ((_kw & KW_BATTLECRY) != 0) { draw_set_colour(#FFAA44); draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.65, "Battlecry", _cs * 0.55, _cs * 0.55, 0); }
            if ((_kw & KW_DEATHRATTLE) != 0) { draw_set_colour(#88FF88); draw_text_transformed(_cx + _card_w * 0.5, _hand_y + _card_h * 0.65, "Deathrattle", _cs * 0.55, _cs * 0.55, 0); }
        }
    }
    _ci++;
}

// === END TURN + HERO POWER (moved above cards) ===
if (game_state == 1) {
    var _btn_w = max(90, _ww * 0.2);
    var _btn_h = max(32, _wh * 0.045);
    var _btn_x = _ww - _btn_w - 10;
    var _btn_y = _info_y + 2;

    // Check if player has any remaining actions
    var _has_actions = false;
    // Check if any card is playable
    var _pai = 0;
    while (_pai < player_hand_count) {
        var _pc = player_hand[_pai];
        if (_pc >= 10) { // spell
            var _pcost = ds_map_find_value(spell_costs, _pc);
            if (_pcost <= player_mana) _has_actions = true;
        } else { // minion
            if (piece_mana_cost[_pc] <= player_mana) _has_actions = true;
        }
        _pai++;
    }
    // Check if any piece can still move/attack
    if (!_has_actions) {
        var _pci = 0;
        while (_pci < BOARD_SIZE) {
            if (board_type[_pci] != PIECE_NONE && board_owner[_pci] == 0
                && !board_has_acted[_pci] && board_can_act[_pci]
                && board_type[_pci] != PIECE_KING) {
                _has_actions = true;
                break;
            }
            _pci++;
        }
    }
    // Check hero power
    if (!_has_actions && !hero_power_used && player_mana >= 2) _has_actions = true;

    // End Turn button — pulse if no actions left
    if (!_has_actions) {
        draw_set_alpha(0.2 + _pulse * 0.25);
        draw_set_colour(#88FF88);
        draw_rectangle(_btn_x - 3, _btn_y - 3, _btn_x + _btn_w + 3, _btn_y + _btn_h + 3, false);
        draw_set_alpha(1.0);
        draw_set_colour(#336644);
    } else {
        draw_set_colour(#445566);
    }
    draw_rectangle(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, false);
    if (!_has_actions) draw_set_colour(#66CC66);
    else draw_set_colour(#88AACC);
    draw_rectangle(_btn_x, _btn_y, _btn_x + _btn_w, _btn_y + _btn_h, true);
    draw_set_colour(!_has_actions ? #AAFFAA : #FFFFFF);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text_transformed(_btn_x + _btn_w * 0.5, _btn_y + _btn_h * 0.5, "End Turn", _ui_scale * 0.8, _ui_scale * 0.8, 0);

    // Hero Power button
    var _hp_w = max(80, _ww * 0.18); var _hp_h = max(30, _wh * 0.04);
    var _hp_x = _ww - _hp_w - 10; var _hp_y = _btn_y + _btn_h + 4;
    if (hero_power_used) draw_set_colour(#333344);
    else if (player_mana >= 2) draw_set_colour(#664422);
    else draw_set_colour(#333344);
    draw_rectangle(_hp_x, _hp_y, _hp_x + _hp_w, _hp_y + _hp_h, false);
    if (input_mode == "hero_power") draw_set_colour(#FFAA44);
    else draw_set_colour(#886644);
    draw_rectangle(_hp_x, _hp_y, _hp_x + _hp_w, _hp_y + _hp_h, true);
    draw_set_colour(hero_power_used ? #666666 : #FFAA44);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text_transformed(_hp_x + _hp_w * 0.5, _hp_y + _hp_h * 0.5, "Hero Power (2)", _ui_scale * 0.6, _ui_scale * 0.6, 0);
}

// === CONTEXT PANEL (between info bar and cards) ===
if (game_state == 1) {
    var _ctx_y = _info_y + 2;
    var _ctx_x = 8;
    var _ctx_s = _ui_scale * 0.75;
    var _line_h = _ui_scale * 12;

    // Line 1: Mana crystals + deck count
    var _crystal_r = min(9, _ui_scale * 5);
    var _mi = 0;
    while (_mi < player_max_mana) {
        var _mx2 = _ctx_x + _mi * (_crystal_r * 2.2) + _crystal_r;
        if (_mi < player_mana) { draw_set_colour(#4488FF); draw_circle(_mx2, _ctx_y + _crystal_r, _crystal_r, false); }
        draw_set_colour(#334466); draw_circle(_mx2, _ctx_y + _crystal_r, _crystal_r, true);
        _mi++;
    }
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_colour(#888899);
    var _after_mana = _ctx_x + player_max_mana * (_crystal_r * 2.2) + _crystal_r + 6;
    draw_text_transformed(_after_mana, _ctx_y, "Deck: " + string(ds_list_size(player_deck)), _ctx_s * 0.85, _ctx_s * 0.85, 0);

    // Line 2-4: Context info (name, description, action hint)
    var _line2_y = _ctx_y + _line_h + 4;
    var _ctx_name = "";
    var _ctx_desc = "";
    var _ctx_hint = "";
    var _ctx_col = #AAAACC;

    if ((input_mode == "card" || input_mode == "spell_target") && selected_card >= 0) {
        var _sc = player_hand[selected_card];
        if (_sc >= 10) {
            var _scost = ds_map_find_value(spell_costs, _sc);
            _ctx_name = ds_map_find_value(spell_names, _sc) + " (" + string(_scost) + " mana)";
            if (_sc == SPELL_FIREBALL) _ctx_desc = "Deal 3 damage to any enemy";
            else if (_sc == SPELL_HEAL) _ctx_desc = "Restore 3 HP to a friendly unit";
            else if (_sc == SPELL_SHIELD) _ctx_desc = "Give +2 max HP to a friendly";
            else if (_sc == SPELL_RAGE) _ctx_desc = "Give +2 ATK to a friendly";
            if (player_mana >= _scost) _ctx_hint = "Tap a target on the board";
            else _ctx_hint = "Need " + string(_scost) + " mana to cast";
            _ctx_col = #CC88FF;
        } else {
            var _pcost = piece_mana_cost[_sc];
            _ctx_name = piece_names[_sc] + "  " + string(piece_base_atk[_sc]) + "/" + string(piece_base_hp[_sc]) + "  (" + string(_pcost) + " mana)";
            // Movement + keyword description
            if (_sc == PIECE_PAWN) _ctx_desc = "Moves fwd 1, attacks diagonal";
            else if (_sc == PIECE_KNIGHT) _ctx_desc = "L-shaped move (2+1). Battlecry: 1 dmg adj";
            else if (_sc == PIECE_BISHOP) _ctx_desc = "Diagonal up to 2. Deathrattle: heal adj 2";
            else if (_sc == PIECE_ROOK) _ctx_desc = "Straight up to 2. Taunt: attacked first";
            else _ctx_desc = "";
            // Action hint
            if (player_mana >= _pcost) _ctx_hint = "Tap a highlighted cell to summon";
            else _ctx_hint = "Need " + string(_pcost) + " mana to summon";
            _ctx_col = #88CCFF;
        }
    } else if (input_mode == "piece" && selected_row >= 0) {
        var _si = selected_row * GRID_W + selected_col;
        var _pt = board_type[_si];
        _ctx_name = piece_names[_pt] + "  " + string(board_atk[_si]) + "/" + string(board_hp[_si]);
        if (_pt == PIECE_PAWN) _ctx_desc = "Forward 1, attack diagonal";
        else if (_pt == PIECE_KNIGHT) _ctx_desc = "L-shaped (2+1)";
        else if (_pt == PIECE_BISHOP) _ctx_desc = "Diagonal up to 2";
        else if (_pt == PIECE_ROOK) _ctx_desc = "Straight up to 2";
        else if (_pt == PIECE_KING) _ctx_desc = "Any direction 1 step";
        _ctx_hint = "Green = move, Red = attack";
        _ctx_col = #88CCFF;
    } else if (input_mode == "hero_power") {
        _ctx_name = "Hero Power (2 mana)";
        _ctx_desc = "Deal 1 damage to any enemy unit";
        if (hero_power_used) _ctx_hint = "Already used this turn";
        else if (player_mana >= 2) _ctx_hint = "Tap an enemy on the board";
        else _ctx_hint = "Need 2 mana to use";
        _ctx_col = #FFAA44;
    } else {
        _ctx_name = "Tap a card or piece";
        _ctx_col = #777799;
    }

    draw_set_halign(fa_left); draw_set_valign(fa_top);
    if (_ctx_name != "") {
        draw_set_colour(_ctx_col);
        draw_text_transformed(_ctx_x, _line2_y, _ctx_name, _ctx_s * 1.1, _ctx_s * 1.1, 0);
    }
    if (_ctx_desc != "") {
        draw_set_colour(#AAAACC);
        draw_text_transformed(_ctx_x, _line2_y + _line_h, _ctx_desc, _ctx_s * 0.85, _ctx_s * 0.85, 0);
    }
    if (_ctx_hint != "") {
        draw_set_colour(#666688);
        draw_text_transformed(_ctx_x, _line2_y + _line_h * 2, _ctx_hint, _ctx_s * 0.8, _ctx_s * 0.8, 0);
    }
}

// === MESSAGE ===
if (message != "" && message_timer > 0) {
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _msg_alpha = clamp(message_timer / 30, 0, 1);
    draw_set_alpha(_msg_alpha * 0.6); draw_set_colour(#000000);
    var _msg_y = _by + _board_h * 0.5;
    draw_rectangle(0, _msg_y - _ui_scale * 12, _ww, _msg_y + _ui_scale * 12, false);
    draw_set_alpha(_msg_alpha); draw_set_colour(#FFFFFF);
    draw_text_transformed(_ww * 0.5, _msg_y, message, _ui_scale * 0.9, _ui_scale * 0.9, 0);
    draw_set_alpha(1.0);
}

// === AI THINKING ===
if (game_state == 2 || game_state == 5) {
    draw_set_halign(fa_center); draw_set_valign(fa_top);
    draw_set_colour(#FF6666);
    draw_text_transformed(_ww * 0.5, _by - _ui_scale * 14, "AI thinking...", _ui_scale * 0.7, _ui_scale * 0.7, 0);
}

// === GAME OVER ===
if (game_state == 4 && message_timer <= 0) {
    draw_set_alpha(0.6); draw_set_colour(#000000);
    draw_rectangle(0, 0, _ww, _wh, false);
    draw_set_alpha(1.0);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_colour(#FFDD44);
    draw_text_transformed(_ww * 0.5, _wh * 0.38, "Game Over", _ui_scale * 1.8, _ui_scale * 1.8, 0);
    draw_set_colour(#FFFFFF);
    draw_text_transformed(_ww * 0.5, _wh * 0.48, "Score: " + string(points), _ui_scale * 1.2, _ui_scale * 1.2, 0);
    draw_set_colour(#88FF88);
    draw_text_transformed(_ww * 0.5, _wh * 0.6, "Tap to play again", _ui_scale * 0.9, _ui_scale * 0.9, 0);
}

// Reset
draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_colour(c_white); draw_set_alpha(1.0);
