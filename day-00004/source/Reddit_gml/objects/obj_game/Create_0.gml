
username = "";
level = 0;
points = 0;

prev_points = 0;

api_load_state(function(_status, _ok, _result, _payload) {
	try {
		var _state = json_parse(_result);
		username = _state.username;
		level = _state.level;
		points = _state.data.points;
	}
	catch (_ex) {
		api_save_state(0, { points }, undefined);
	}
	alarm[0] = 60;
});

// Screen dimensions (updated each frame)
screen_w = 0;
screen_h = 0;

// Game state: 0=waiting, 1=playing, 2=dead
game_state = 0;

// Current run score
current_score = 0;

// Pipe spawning
pipe_timer = 0;
pipe_interval = 90;     // frames between pipe spawns (starts at 90 = 1.5 sec)
pipe_speed = 3;          // how fast pipes scroll left
pipe_gap = 180;          // vertical gap between top/bottom pipes
min_pipe_gap = 120;      // minimum gap (difficulty cap)
gap_shrink_rate = 0.5;   // how much gap shrinks per pipe scored

// Difficulty tracking
pipes_passed = 0;

// Death state
death_timer = 0;

// Cat starting position (fraction of screen)
cat_start_x_frac = 0.25;
cat_start_y_frac = 0.5;

/// @function game_start()
/// Transition from waiting to playing
function game_start() {
    game_state = 1;
    current_score = 0;
    pipes_passed = 0;
    pipe_timer = 0;
    pipe_interval = 90;
    pipe_gap = 180;
    pipe_speed = 3;

    // Give cat initial flap
    if (instance_exists(obj_player)) {
        obj_player.vy = obj_player.flap_power;
    }
}

/// @function game_die()
/// Handle death
function game_die() {
    if (game_state != 1) return; // prevent double-death
    game_state = 2;
    death_timer = 45; // ~0.75 seconds before can restart

    // Update best score
    if (current_score > points) {
        points = current_score;
    }
}

/// @function game_restart()
/// Reset everything for a new run
function game_restart() {
    game_state = 0;
    current_score = 0;
    pipes_passed = 0;
    pipe_timer = 0;
    pipe_interval = 90;
    pipe_gap = 180;
    pipe_speed = 3;
    death_timer = 0;

    // Destroy all pipes
    with (obj_pipe) {
        instance_destroy();
    }

    // Reset cat position
    if (instance_exists(obj_player)) {
        obj_player.x = screen_w * cat_start_x_frac;
        obj_player.y = screen_h * cat_start_y_frac;
        obj_player.vy = 0;
        obj_player.image_angle = 0;
    }
}

/// @function spawn_pipe_pair()
/// Create a top and bottom pipe pair at the right edge
function spawn_pipe_pair() {
    var _x = screen_w + 64;

    // Random gap position (leave margin from top/bottom)
    var _margin = 60;
    var _gap_center = _margin + irandom(screen_h - _margin * 2 - pipe_gap) + (pipe_gap / 2);

    var _gap_top = _gap_center - (pipe_gap / 2);
    var _gap_bottom = _gap_center + (pipe_gap / 2);

    // Bottom pipe: starts at gap_bottom, extends to screen bottom
    var _bottom = instance_create_depth(_x, _gap_bottom, 0, obj_pipe);
    _bottom.pipe_speed = pipe_speed;
    _bottom.is_top = false;
    _bottom.image_yscale = (screen_h - _gap_bottom) / 64; // stretch to fill

    // Top pipe: starts at 0, extends down to gap_top
    var _top = instance_create_depth(_x, 0, 0, obj_pipe);
    _top.pipe_speed = pipe_speed;
    _top.is_top = true;
    _top.image_yscale = _gap_top / 64; // stretch to fill
}
