
if (prev_points != points || game_state == 1) {
    prev_points = points;
    api_save_state(floor_num, get_save_data(), function(_status, _ok, _result) {
        alarm[0] = 60;
    });
}
else alarm[0] = 60;
