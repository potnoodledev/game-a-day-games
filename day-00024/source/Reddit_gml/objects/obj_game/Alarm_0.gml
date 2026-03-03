
if (prev_points != points) {
    prev_points = points;
    api_save_state(0, { points: points, round_num: round_num, lives: lives, streak: streak }, function(_status, _ok, _result) {
        alarm[0] = 60;
    });
}
else alarm[0] = 60;
