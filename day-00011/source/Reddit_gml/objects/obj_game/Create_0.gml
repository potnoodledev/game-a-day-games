// ========================================
// RICOCHET — Create_0.gml
// ========================================

#macro RC_BALL_SPEED 12
#macro RC_BALL_RADIUS 10
#macro RC_TARGET_RADIUS 18
#macro RC_MAX_BOUNCES 8
#macro RC_PREVIEW_BOUNCES 3
#macro RC_WALL_PAD 8

// --- Game State ---
// 0=loading, 1=aiming, 2=ball_moving, 3=round_complete, 4=game_over
game_state = 0;
points = 0;
round_num = 0;
shots_left = 3;
level = 0;

// --- Ball ---
ball_x = 0;
ball_y = 0;
ball_vx = 0;
ball_vy = 0;
ball_bounces = 0;
ball_active = false;
ball_trail = [];

// --- Targets ---
targets = [];
targets_hit = 0;

// --- Obstacles (from round 4+) ---
obstacles = [];

// --- Aiming ---
aim_active = false;
aim_sx = 0;
aim_sy = 0;
aim_angle = 0;
aim_power = 1;

// --- Visual ---
bg_color = make_color_rgb(18, 18, 30);
ball_color = make_color_rgb(255, 255, 255);
target_colors = [
    make_color_rgb(231, 76, 60),
    make_color_rgb(46, 204, 113),
    make_color_rgb(52, 152, 219),
    make_color_rgb(241, 196, 15),
    make_color_rgb(155, 89, 182),
];

popups = [];
combo_count = 0;
combo_timer = 0;
combo_text = "";
round_msg = "";
round_msg_timer = 0;
score_submitted = false;

// Screen shake
shake_x = 0;
shake_y = 0;
shake_timer = 0;
shake_intensity = 0;

// FX: expanding rings
fx = [];

// Layout
scr_w = window_get_width();
scr_h = window_get_height();
play_x1 = 0;
play_y1 = 0;
play_x2 = 0;
play_y2 = 0;
ball_start_x = 0;
ball_start_y = 0;

// --- Functions ---

function calc_layout() {
    scr_w = window_get_width();
    scr_h = window_get_height();
    var _pad = RC_WALL_PAD;
    play_x1 = _pad;
    play_y1 = scr_h * 0.12;
    play_x2 = scr_w - _pad;
    play_y2 = scr_h - _pad;
    ball_start_x = scr_w * 0.5;
    ball_start_y = play_y2 - RC_BALL_RADIUS * 3;
}

function add_shake(_intensity, _duration) {
    if (_intensity > shake_intensity || shake_timer <= 0) {
        shake_intensity = _intensity;
        shake_timer = _duration;
    }
}

function spawn_fx(_x, _y, _color, _size, _dur) {
    array_push(fx, {x: _x, y: _y, clr: _color, sz: _size, t: 0, mt: _dur});
}

function reset_ball() {
    ball_x = ball_start_x;
    ball_y = ball_start_y;
    ball_vx = 0;
    ball_vy = 0;
    ball_bounces = 0;
    ball_active = false;
    ball_trail = [];
}

function spawn_targets() {
    targets = [];
    targets_hit = 0;
    obstacles = [];

    var _count = min(3 + floor(round_num * 0.7), 12);
    var _margin = RC_TARGET_RADIUS * 2.5;
    var _area_x1 = play_x1 + _margin;
    var _area_y1 = play_y1 + _margin;
    var _area_x2 = play_x2 - _margin;
    var _area_y2 = play_y2 - _margin - (play_y2 - play_y1) * 0.25;

    for (var _i = 0; _i < _count; _i++) {
        var _placed = false;
        var _attempts = 0;
        while (!_placed && _attempts < 80) {
            var _tx = random_range(_area_x1, _area_x2);
            var _ty = random_range(_area_y1, _area_y2);
            var _ok = true;
            for (var _j = 0; _j < array_length(targets); _j++) {
                var _dx = _tx - targets[_j].x;
                var _dy = _ty - targets[_j].y;
                if (sqrt(_dx * _dx + _dy * _dy) < RC_TARGET_RADIUS * 3) {
                    _ok = false;
                    break;
                }
            }
            var _dbx = _tx - ball_start_x;
            var _dby = _ty - ball_start_y;
            if (sqrt(_dbx * _dbx + _dby * _dby) < RC_TARGET_RADIUS * 4) _ok = false;

            if (_ok) {
                var _clr_idx = _i mod array_length(target_colors);
                array_push(targets, {
                    x: _tx,
                    y: _ty,
                    r: RC_TARGET_RADIUS,
                    clr: target_colors[_clr_idx],
                    hit: false,
                    pulse: 0,
                });
                _placed = true;
            }
            _attempts++;
        }
    }

    // Add obstacles from round 4+
    if (round_num >= 4) {
        var _obs_count = min(floor((round_num - 3) * 0.5), 4);
        for (var _i = 0; _i < _obs_count; _i++) {
            var _placed = false;
            var _attempts = 0;
            while (!_placed && _attempts < 50) {
                var _cx = random_range(_area_x1 + 40, _area_x2 - 40);
                var _cy = random_range(_area_y1 + 20, _area_y2 - 20);
                var _ang = random(180);
                var _len = random_range(40, 80);
                var _ox1 = _cx + lengthdir_x(_len * 0.5, _ang);
                var _oy1 = _cy + lengthdir_y(_len * 0.5, _ang);
                var _ox2 = _cx - lengthdir_x(_len * 0.5, _ang);
                var _oy2 = _cy - lengthdir_y(_len * 0.5, _ang);

                var _ok = true;
                for (var _j = 0; _j < array_length(targets); _j++) {
                    var _dx = _cx - targets[_j].x;
                    var _dy = _cx - targets[_j].y;
                    if (sqrt(_dx * _dx + _dy * _dy) < RC_TARGET_RADIUS * 4) {
                        _ok = false;
                        break;
                    }
                }
                if (_ok) {
                    array_push(obstacles, {x1: _ox1, y1: _oy1, x2: _ox2, y2: _oy2});
                    _placed = true;
                }
                _attempts++;
            }
        }
    }
}

function start_round() {
    round_num++;
    shots_left = 3;
    reset_ball();
    spawn_targets();
    game_state = 1;
    round_msg = "Round " + string(round_num);
    round_msg_timer = 45;
    combo_count = 0;
}

function launch_ball(_angle) {
    ball_vx = lengthdir_x(RC_BALL_SPEED, _angle);
    ball_vy = lengthdir_y(RC_BALL_SPEED, _angle);
    ball_bounces = 0;
    ball_active = true;
    ball_trail = [];
    game_state = 2;
}

function reflect_ball_wall() {
    var _bounced = false;
    if (ball_x - RC_BALL_RADIUS <= play_x1) {
        ball_x = play_x1 + RC_BALL_RADIUS;
        ball_vx = abs(ball_vx);
        _bounced = true;
    }
    if (ball_x + RC_BALL_RADIUS >= play_x2) {
        ball_x = play_x2 - RC_BALL_RADIUS;
        ball_vx = -abs(ball_vx);
        _bounced = true;
    }
    if (ball_y - RC_BALL_RADIUS <= play_y1) {
        ball_y = play_y1 + RC_BALL_RADIUS;
        ball_vy = abs(ball_vy);
        _bounced = true;
    }
    if (ball_y + RC_BALL_RADIUS >= play_y2) {
        ball_y = play_y2 - RC_BALL_RADIUS;
        ball_vy = -abs(ball_vy);
        _bounced = true;
    }
    if (_bounced) {
        ball_bounces++;
        add_shake(2, 4);
    }
    return _bounced;
}

function reflect_ball_obstacle(_ox1, _oy1, _ox2, _oy2) {
    var _dx = _ox2 - _ox1;
    var _dy = _oy2 - _oy1;
    var _len = sqrt(_dx * _dx + _dy * _dy);
    if (_len == 0) return false;
    var _nx = -_dy / _len;
    var _ny = _dx / _len;

    var _bx = ball_x - _ox1;
    var _by = ball_y - _oy1;
    var _dist = _bx * _nx + _by * _ny;

    if (abs(_dist) > RC_BALL_RADIUS) return false;

    var _proj = (_bx * _dx + _by * _dy) / (_len * _len);
    if (_proj < -0.1 || _proj > 1.1) return false;

    var _vdot = ball_vx * _nx + ball_vy * _ny;
    if (_dist > 0 && _vdot > 0) return false;
    if (_dist < 0 && _vdot < 0) return false;

    ball_vx -= 2 * _vdot * _nx;
    ball_vy -= 2 * _vdot * _ny;

    var _push = (RC_BALL_RADIUS - abs(_dist) + 1) * sign(_dist);
    ball_x += _nx * _push;
    ball_y += _ny * _push;

    ball_bounces++;
    add_shake(3, 5);
    spawn_fx(ball_x, ball_y, make_color_rgb(100, 100, 120), 20, 10);
    return true;
}

function check_target_hits() {
    for (var _i = 0; _i < array_length(targets); _i++) {
        if (targets[_i].hit) continue;
        var _dx = ball_x - targets[_i].x;
        var _dy = ball_y - targets[_i].y;
        var _dist = sqrt(_dx * _dx + _dy * _dy);
        if (_dist <= RC_BALL_RADIUS + targets[_i].r) {
            targets[_i].hit = true;
            targets[_i].pulse = 1;
            targets_hit++;
            combo_count++;
            combo_timer = 30;

            var _base = 50 + round_num * 10;
            var _combo_mult = 1 + (combo_count - 1) * 0.5;
            var _score = floor(_base * _combo_mult);
            points += _score;

            var _txt = "+" + string(_score);
            if (combo_count > 1) _txt += " x" + string(combo_count);
            array_push(popups, {x: targets[_i].x, y: targets[_i].y, txt: _txt, t: 50, clr: targets[_i].clr});

            spawn_fx(targets[_i].x, targets[_i].y, targets[_i].clr, RC_TARGET_RADIUS * 3, 20);
            add_shake(5, 8);

            if (combo_count > 1) {
                combo_text = "COMBO x" + string(combo_count);
            }
        }
    }
}

function all_targets_hit() {
    for (var _i = 0; _i < array_length(targets); _i++)
        if (!targets[_i].hit) return false;
    return true;
}

function on_ball_stop() {
    ball_active = false;
    if (all_targets_hit()) {
        var _bonus = 100 * round_num;
        points += _bonus;
        array_push(popups, {x: scr_w * 0.5, y: scr_h * 0.4, txt: "CLEAR! +" + string(_bonus), t: 60, clr: make_color_rgb(46, 204, 113)});
        add_shake(6, 10);
        round_msg = "Round Clear!";
        round_msg_timer = 50;
        game_state = 3;
    } else {
        shots_left--;
        if (shots_left <= 0) {
            game_state = 4;
            score_submitted = false;
        } else {
            reset_ball();
            game_state = 1;
        }
    }
}

function get_preview_path(_angle, _max_bounces) {
    var _path = [];
    var _px = ball_start_x;
    var _py = ball_start_y;
    var _pvx = lengthdir_x(RC_BALL_SPEED, _angle);
    var _pvy = lengthdir_y(RC_BALL_SPEED, _angle);
    var _bounces = 0;
    array_push(_path, [_px, _py]);

    for (var _step = 0; _step < 200 && _bounces <= _max_bounces; _step++) {
        _px += _pvx;
        _py += _pvy;
        var _did_bounce = false;
        if (_px - RC_BALL_RADIUS <= play_x1) { _px = play_x1 + RC_BALL_RADIUS; _pvx = abs(_pvx); _did_bounce = true; }
        if (_px + RC_BALL_RADIUS >= play_x2) { _px = play_x2 - RC_BALL_RADIUS; _pvx = -abs(_pvx); _did_bounce = true; }
        if (_py - RC_BALL_RADIUS <= play_y1) { _py = play_y1 + RC_BALL_RADIUS; _pvy = abs(_pvy); _did_bounce = true; }
        if (_py + RC_BALL_RADIUS >= play_y2) { _py = play_y2 - RC_BALL_RADIUS; _pvy = -abs(_pvy); _did_bounce = true; }
        if (_did_bounce) {
            _bounces++;
            array_push(_path, [_px, _py]);
        }
    }
    return _path;
}

function reset_game() {
    points = 0;
    round_num = 0;
    shots_left = 3;
    combo_count = 0;
    popups = [];
    fx = [];
    score_submitted = false;
    start_round();
}

// --- Load State ---
state_loaded = false;
state_data = undefined;
username = "";

api_load_state(function(_status, _ok, _result, _payload) {
    if (_ok && _status >= 200 && _status < 400 && _result != undefined && _result != "") {
        try { self.state_data = json_parse(_result); }
        catch (_ex) { self.state_data = undefined; }
    }
    self.state_loaded = true;
});

calc_layout();
