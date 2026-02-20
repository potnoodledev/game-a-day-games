
if (prev_points != points) {
    prev_points = points;
    api_save_state(level, { points: points, level: level, lives: lives, orders_completed: orders_completed, combo: combo, best_score: best_score, tutorial_done: tutorial_done }, function(_status, _ok, _result) {
        alarm[0] = 60 * 15;
    });
}
else alarm[0] = 60 * 15;
