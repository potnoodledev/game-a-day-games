
// Auto-save: check if points or grid changed
var _grid_str = get_grid_string();
if (prev_points != points || prev_grid_string != _grid_str) {
    prev_points = points;
    prev_grid_string = _grid_str;
    api_save_state(0, { points: points, grid: grid }, function(_status, _ok, _result) {
        alarm[0] = 60;
    });
}
else alarm[0] = 60;
