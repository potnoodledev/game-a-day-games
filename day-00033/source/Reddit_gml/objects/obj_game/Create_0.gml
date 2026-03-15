
username = "";
level = 0;
points = 0;
prev_points = 0;

// Game state: 0=title, 1=playing, 2=game over
game_state = 0;
state_timer = 0;

// Screen
window_width = 0;
window_height = 0;

// === BOIDS ===
max_birds = 250;
num_birds = 0;
bird_x = array_create(max_birds, 0);
bird_y = array_create(max_birds, 0);
bird_vx = array_create(max_birds, 0);
bird_vy = array_create(max_birds, 0);
bird_alive = array_create(max_birds, false);

// Boid parameters
boid_speed_max = 4;
boid_separation_dist = 20;
boid_alignment_dist = 60;
boid_cohesion_dist = 80;
boid_separation_weight = 1.8;
boid_alignment_weight = 1.0;
boid_cohesion_weight = 0.8;
boid_player_weight = 2.5;
boid_predator_weight = 5.0;
boid_edge_margin = 60;
boid_edge_weight = 1.5;

// === PREDATORS (hawks) ===
max_hawks = 10;
num_hawks = 0;
hawk_x = array_create(max_hawks, 0);
hawk_y = array_create(max_hawks, 0);
hawk_vx = array_create(max_hawks, 0);
hawk_vy = array_create(max_hawks, 0);
hawk_alive = array_create(max_hawks, false);
hawk_top_speed = 6.0;       // fast in a straight line
hawk_accel = 0.12;          // how quickly they build speed
hawk_turn_drag = 0.7;       // speed multiplier when turning hard (0-1, lower = more drag)
hawk_steer_rate = 0.03;     // how quickly they can change direction
hawk_catch_dist = 18;
hawk_target = array_create(max_hawks, -1);
hawk_kills = array_create(max_hawks, 0);
hawk_speed_cur = array_create(max_hawks, 0); // current speed (builds up)

// === STRAY BIRDS ===
stray_timer = 0;
stray_interval = 90; // frames between stray spawns

// === TOUCH ===
touch_active = false;
touch_x = 0;
touch_y = 0;

// === DIFFICULTY ===
difficulty_timer = 0;
hawk_spawn_interval = 300;
next_hawk_spawn = 180; // first hawk at 3 seconds
hawk_speed_ramp = 0;
game_timer = 60 * 60; // 60 seconds at 60fps
game_timer_max = 60 * 60;

// === VISUAL ===
bg_color_top = make_colour_rgb(15, 10, 40);
bg_color_bot = make_colour_rgb(40, 25, 70);
trail_alpha = 0.4;

// Kill particles (feather burst when hawk eats a bird)
max_kill_fx = 20;
kill_fx_x = array_create(max_kill_fx, 0);
kill_fx_y = array_create(max_kill_fx, 0);
kill_fx_age = array_create(max_kill_fx, -1);
kill_fx_next = 0;

// Touch feedback: ripple rings
max_ripples = 8;
ripple_x = array_create(max_ripples, 0);
ripple_y = array_create(max_ripples, 0);
ripple_age = array_create(max_ripples, -1); // -1 = inactive
ripple_next = 0;
ripple_interval = 0; // frames since last ripple spawn

// Score display
score_display = 0;
birds_lost = 0;
birds_collected = 0;
best_flock = 0;

// Title pulse
title_pulse = 0;

// Load state
api_load_state(function(_status, _ok, _result, _payload) {
	try {
		var _state = json_parse(_result);
		username = _state.username;
		level = _state.level;
		points = _state.data.points;
	}
	catch (_ex) {
		api_save_state(0, { points: 0 }, undefined);
	}
	alarm[0] = 60;
});
