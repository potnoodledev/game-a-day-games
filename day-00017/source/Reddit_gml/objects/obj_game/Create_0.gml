
// Orbital - Gravity Slingshot Puzzle (Day 17)
// Tap to place gravity wells, slingshot a comet through star gates

// Game state: 0=waiting, 1=playing, 2=dead
game_state = 0;
points = 0;
best_score = 0;
username = "";
level = 0;

// Physics constants
GRAVITY = 12;
PLANET_RADIUS = 22;
COMET_RADIUS = 5;
GATE_RADIUS = 28;
GATE_COLLECT_DIST = 34;
MAX_PLANETS = 5;
SPEED_CAP = 10;

// Comet state
comet_x = 0;
comet_y = 0;
comet_vx = 0;
comet_vy = 0;

// Comet trail
TRAIL_MAX = 40;
trail_x = array_create(TRAIL_MAX, 0);
trail_y = array_create(TRAIL_MAX, 0);
trail_count = 0;

// Placed planets
planet_count = 0;
planet_x = array_create(MAX_PLANETS, 0);
planet_y = array_create(MAX_PLANETS, 0);
planet_col = array_create(MAX_PLANETS, c_purple);
planet_age = array_create(MAX_PLANETS, 0);
planets_remaining = MAX_PLANETS;

// Planet color palette
pcols = array_create(5, 0);
pcols[0] = make_color_rgb(120, 80, 200);
pcols[1] = make_color_rgb(80, 150, 220);
pcols[2] = make_color_rgb(200, 100, 150);
pcols[3] = make_color_rgb(100, 200, 150);
pcols[4] = make_color_rgb(220, 160, 80);

// Star gates
GATE_MAX = 10;
gate_count = 0;
gate_x = array_create(GATE_MAX, 0);
gate_y = array_create(GATE_MAX, 0);
gate_collected = array_create(GATE_MAX, false);
gate_anim = array_create(GATE_MAX, -1);
gates_got = 0;

// Wave tracking
wave = 0;
wave_start = false;
wave_phase = 0; // 0=pre-launch, 1=active, 2=complete
wave_timer = 0;
wave_text_alpha = 0;

// Particles
PART_MAX = 60;
part_px = array_create(PART_MAX, 0);
part_py = array_create(PART_MAX, 0);
part_vx = array_create(PART_MAX, 0);
part_vy = array_create(PART_MAX, 0);
part_life = array_create(PART_MAX, 0);
part_col = array_create(PART_MAX, c_white);
part_count = 0;

// Background stars
STAR_COUNT = 80;
star_sx = array_create(STAR_COUNT, 0);
star_sy = array_create(STAR_COUNT, 0);
star_br = array_create(STAR_COUNT, 0);
for (var i = 0; i < STAR_COUNT; i++) {
	star_sx[i] = random(1);
	star_sy[i] = random(1);
	star_br[i] = 0.3 + random(0.7);
}

// Palette
COL_BG = make_color_rgb(8, 8, 24);
COL_COMET = make_color_rgb(255, 220, 100);
COL_TRAIL = make_color_rgb(255, 140, 50);
COL_GATE = make_color_rgb(100, 255, 200);
COL_GATE_HIT = make_color_rgb(255, 255, 100);

// Score popup
popup_text = "";
popup_x = 0;
popup_y = 0;
popup_timer = 0;

// Death effect
death_timer = 0;

// Animation counter
anim_t = 0;

// Input cooldown
tap_cd = 0;

// Responsive
window_width = 0;
window_height = 0;

// Load saved state
api_load_state(function(_status, _ok, _result, _payload) {
	try {
		var _state = json_parse(_result);
		username = _state.username;
		if (variable_struct_exists(_state, "data") && _state.data != undefined) {
			var _d = _state.data;
			if (is_string(_d)) _d = json_parse(_d);
			if (variable_struct_exists(_d, "best")) best_score = _d.best;
		}
	}
	catch (_ex) {
		// Fresh start
	}
	alarm[0] = room_speed * 30;
});
