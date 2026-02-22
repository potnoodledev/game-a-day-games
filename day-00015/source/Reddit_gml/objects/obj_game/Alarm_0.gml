
// ============================================================
// AUTO CHESS — Alarm_0 (Periodic State Save)
// ============================================================

if (prev_points != points || game_state == 1) {
	prev_points = points;

	// Serialize board units for save
	var _board_save = [];
	var _i = 0;
	while (_i < array_length(board_units)) {
		var _u = board_units[_i];
		array_push(_board_save, {
			unit_type: _u.unit_type,
			star: _u.star,
			hp: _u.hp,
			max_hp: _u.max_hp,
			atk: _u.atk,
			base_range: _u.base_range,
			spd: _u.spd,
			grid_col: _u.grid_col,
			grid_row: _u.grid_row
		});
		_i++;
	}

	api_save_state(0, {
		points: points,
		gold: gold,
		current_round: current_round,
		total_enemies_killed: total_enemies_killed,
		board_units_data: _board_save
	}, method(self, function(_status, _ok, _result) {
		alarm[0] = 60 * 15; // 15 seconds
	}));
}
else {
	alarm[0] = 60;
}
