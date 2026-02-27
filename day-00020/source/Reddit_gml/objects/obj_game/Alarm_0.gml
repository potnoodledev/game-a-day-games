if (prev_points != points) {
    prev_points = points;
    api_save_state(0, { points: points, gold: gold, wave: wave, total_kills: total_kills, player_hp: player_hp }, function(_status, _ok, _result) {
        alarm[0] = 60;
    });
}
else alarm[0] = 60;
