// Save state periodically
if (game_state == 1 || game_state == 3) {
    var _g = [];
    var _sp = [];
    for (var _c = 0; _c < GF_COLS; _c++) {
        _g[_c] = [];
        _sp[_c] = [];
        for (var _r = 0; _r < GF_ROWS; _r++) {
            _g[_c][_r] = grid[_c][_r];
            _sp[_c][_r] = special[_c][_r];
        }
    }
    var _save = {
        p: points,
        rn: round_num,
        rs: round_score,
        ts: target_score,
        ml: moves_left,
        mm: max_moves,
        g: _g,
        sp: _sp,
        am: active_mods,
        mbc: mod_bomb_count,
        mlc: mod_lightning_count,
        mmc: mod_mult_count,
        mcc: mod_cascade_count,
        mem: mod_extra_moves,
        nc: num_colors,
    };
    api_save_state(round_num, json_stringify(_save), function(_s, _o, _r, _p) {});
}
alarm[0] = room_speed * 20;
