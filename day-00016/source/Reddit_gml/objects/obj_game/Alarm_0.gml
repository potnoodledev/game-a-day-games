/// Alarm_0 — Periodic state save

if (prev_points != points) {
    prev_points = points;
    api_save_state(0, {
        points: points,
        wave: wave,
        total_placed: total_placed,
    }, function(_status, _ok, _result) {
        alarm[0] = 60;
    });
}
else {
    alarm[0] = 60;
}
