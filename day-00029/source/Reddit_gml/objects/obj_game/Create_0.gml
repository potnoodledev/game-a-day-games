
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

// Window size
window_width = 0;
window_height = 0;

// Game state: 0=big_bang, 1=playing, 2=game_over
game_state = 0;
big_bang_timer = 0;
big_bang_duration = 90; // 1.5 seconds

// Energy
energy = 5;
max_energy = 12;

// Stars
stars = [];
max_stars = 20;

// Rogue planets
rogues = [];
max_rogues = 30;

// Dust
dust = [];
max_dust = 400;
dust_spawn_timer = 0;
dust_spawn_rate = 1;
dust_speed = 0.8;
dust_per_spawn = 2;

// Visual particles
nova_particles = [];
popups = [];

// Difficulty
game_time = 0;

// Star constants
star_pull_radius = 120;
star_max_life = 420;
star_grow_rate = 0.3;

// Planet formation
planet_first_threshold = 6;
planet_every = 4;
max_planets_per_star = 5;

// Gravity
gravity_g = 12;
planet_pull_radius = 45;

// Rogue lifespan
rogue_max_life = 600;

// Touch
tap_cooldown = 0;

// Planet colors
planet_colors = [
	make_colour_rgb(160, 120, 80),
	make_colour_rgb(220, 160, 60),
	make_colour_rgb(80, 160, 220),
	make_colour_rgb(180, 80, 80),
	make_colour_rgb(100, 200, 100),
	make_colour_rgb(200, 100, 200)
];

// --- THE VOID ---
void_level = 0;
void_speed = 0.00008;
void_accel = 0.0000004;
void_pushback_amount = 0;
void_light_power = 0;
void_color = make_colour_rgb(10, 0, 20);

// Grace period: 15 seconds, warning at last 4
void_grace_period = 900; // 15 seconds
void_active = false;

// Big bang flash
bang_flash = 0;

// Background stars
bg_stars = [];
var _i = 0;
repeat (80) {
	bg_stars[_i] = {
		bx: random(1920),
		by: random(1080),
		bsize: random_range(0.5, 2),
		btwinkle: random(360),
		bspeed: random_range(0.5, 2)
	};
	_i++;
}

// Nebulae (colorful background clouds)
nebulae = [];
_i = 0;
repeat (12) {
	var _nc = irandom(4);
	var _ncol = c_purple;
	if (_nc == 0) _ncol = make_colour_rgb(60, 20, 80);   // purple
	else if (_nc == 1) _ncol = make_colour_rgb(20, 40, 80); // deep blue
	else if (_nc == 2) _ncol = make_colour_rgb(80, 20, 40); // crimson
	else if (_nc == 3) _ncol = make_colour_rgb(20, 60, 60); // teal
	else _ncol = make_colour_rgb(60, 40, 20);              // warm brown

	nebulae[_i] = {
		nx: random(1920),
		ny: random(1080),
		nradius: random_range(80, 250),
		ncolor: _ncol,
		nalpha: random_range(0.04, 0.10),
		ndrift: random_range(0.3, 1.0)
	};
	_i++;
}
