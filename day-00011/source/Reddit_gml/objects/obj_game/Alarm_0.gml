// ========================================
// RICOCHET — Alarm_0.gml (periodic state save)
// ========================================

var _data = json_stringify({
    points: points,
    round_num: round_num,
    level: level,
});

api_save_state(level, _data, function(_status, _ok, _result, _payload) {
    alarm[0] = room_speed * 20;
});
