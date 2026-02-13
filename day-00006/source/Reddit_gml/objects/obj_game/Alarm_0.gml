
if (prev_points != points) {
    prev_points = points;
    api_save_state(0, {
        points: points,
        lives: lives,
        customers_served: customers_served,
        wave: wave,
        tables_unlocked: tables_unlocked,
        table_seats: table_seats
    }, function(_status, _ok, _result) {
        alarm[0] = 60;
    });
}
else alarm[0] = 60;
