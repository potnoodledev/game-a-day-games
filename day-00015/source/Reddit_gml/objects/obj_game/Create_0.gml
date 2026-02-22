
// ============================================================
// AUTO CHESS — Day 15
// ============================================================

username = "";
level = 0;
points = 0;
prev_points = 0;

// --- Game State ---
// 0 = loading, 1 = shop phase, 2 = battle, 3 = round result, 4 = game over
game_state = 0;

// --- Player Stats ---
gold = 5;
current_round = 1;
max_board_units = 6;

// --- Grid: 6 columns x 4 rows ---
// Bottom 2 rows = player (rows 2,3), Top 2 rows = enemy (rows 0,1)
grid_cols = 6;
grid_rows = 4;
player_rows_start = 2; // rows 2 and 3 are player placement area

// --- Layout (recalculated in Step_2) ---
window_width = 0;
window_height = 0;
layout_dirty = true;
grid_x = 0;
grid_y = 0;
cell_size = 64;
shop_y = 0;
shop_btns = [];
go_btn = {};
sell_btn = {};
hud_h = 50;

// --- Unit Type Definitions ---
// Types: 0=Warrior, 1=Knight, 2=Archer, 3=Mage, 4=Rogue, 5=Healer
UNIT_WARRIOR = 0;
UNIT_KNIGHT  = 1;
UNIT_ARCHER  = 2;
UNIT_MAGE    = 3;
UNIT_ROGUE   = 4;
UNIT_HEALER  = 5;
NUM_UNIT_TYPES = 6;

// Unit names
unit_names = array_create(NUM_UNIT_TYPES);
unit_names[0] = "Warrior";
unit_names[1] = "Knight";
unit_names[2] = "Archer";
unit_names[3] = "Mage";
unit_names[4] = "Rogue";
unit_names[5] = "Healer";

// Unit letters (for display)
unit_letters = array_create(NUM_UNIT_TYPES);
unit_letters[0] = "W";
unit_letters[1] = "K";
unit_letters[2] = "A";
unit_letters[3] = "M";
unit_letters[4] = "R";
unit_letters[5] = "H";

// Unit colors
unit_colors = array_create(NUM_UNIT_TYPES);
unit_colors[0] = make_colour_rgb(220, 50, 50);   // Warrior - red
unit_colors[1] = make_colour_rgb(230, 200, 40);   // Knight - yellow
unit_colors[2] = make_colour_rgb(50, 180, 50);    // Archer - green
unit_colors[3] = make_colour_rgb(60, 100, 220);   // Mage - blue
unit_colors[4] = make_colour_rgb(160, 50, 200);   // Rogue - purple
unit_colors[5] = make_colour_rgb(230, 230, 240);  // Healer - white

// Unit base stats: [cost, hp, atk, range, speed]
unit_stats = array_create(NUM_UNIT_TYPES);
unit_stats[0] = [1, 80, 10, 1, 2.0];   // Warrior
unit_stats[1] = [3, 120, 8, 1, 1.5];   // Knight
unit_stats[2] = [2, 40, 15, 3, 1.0];   // Archer
unit_stats[3] = [3, 50, 20, 2, 1.2];   // Mage
unit_stats[4] = [2, 50, 18, 1, 2.5];   // Rogue
unit_stats[5] = [3, 45, 5, 2, 1.0];    // Healer

// --- Synergy Definitions ---
// Tags: 0=Frontline, 1=Ranged, 2=Mystic, 3=Armored, 4=Assassin
TAG_FRONTLINE = 0;
TAG_RANGED    = 1;
TAG_MYSTIC    = 2;
TAG_ARMORED   = 3;
TAG_ASSASSIN  = 4;
NUM_TAGS = 5;

tag_names = array_create(NUM_TAGS);
tag_names[0] = "Frontline";
tag_names[1] = "Ranged";
tag_names[2] = "Mystic";
tag_names[3] = "Armored";
tag_names[4] = "Assassin";

// Unit tags (each unit has 1-2 tags)
unit_tags = array_create(NUM_UNIT_TYPES);
unit_tags[0] = [TAG_FRONTLINE];                  // Warrior
unit_tags[1] = [TAG_FRONTLINE, TAG_ARMORED];     // Knight
unit_tags[2] = [TAG_RANGED];                     // Archer
unit_tags[3] = [TAG_RANGED, TAG_MYSTIC];         // Mage
unit_tags[4] = [TAG_FRONTLINE, TAG_ASSASSIN];    // Rogue
unit_tags[5] = [TAG_RANGED, TAG_MYSTIC];         // Healer

// Synergy requirements and bonuses (checked per tag)
// Frontline: 2 Frontline units => +30% HP to Frontline
// Ranged: 2 Ranged units => +25% ATK to Ranged
// Mystic: need both Mage AND Healer => Mage splash x2, Healer heal +50%
// Armored: Knight + another Frontline => Knight takes -30% dmg
// Assassin: Rogue + any Ranged => Rogue crits 2x first hit
SYNERGY_FRONTLINE_HP_BONUS = 0.30;
SYNERGY_RANGED_ATK_BONUS = 0.25;
SYNERGY_MYSTIC_SPLASH_MULT = 2;
SYNERGY_MYSTIC_HEAL_BONUS = 0.50;
SYNERGY_ARMORED_DR = 0.30;
SYNERGY_ASSASSIN_CRIT_MULT = 2;

// Active synergies (recalculated each battle)
active_synergies = array_create(NUM_TAGS, false);

// --- Board Units ---
// Player units on board — array of structs
board_units = [];
// Enemy units — array of structs
enemy_units = [];

// --- Shop ---
shop_slots = 4;
shop_items = []; // array of unit type indices (or -1 for empty)
shop_timer = 0;
shop_timer_max = 600; // 10 seconds at 60fps

// --- Drag System ---
dragging = false;
drag_unit_idx = -1;
drag_ox = 0;
drag_oy = 0;

// --- Battle State ---
battle_tick = 0;
battle_speed = 30; // frames between actions
battle_over = false;
round_won = false;
enemies_killed = 0;
total_enemies_killed = 0;
spawn_wave = false;

// --- Result splash ---
result_timer = 0;
result_timer_max = 120; // 2 seconds

// --- Visual Effects ---
damage_numbers = []; // {x, y, text, timer, color}
attack_anims = [];   // {unit_ref, ox, oy, tx, ty, timer, max_timer}
death_anims = [];    // {x, y, r, color, letter, timer, max_timer}
projectiles = [];    // {x, y, tx, ty, color, timer, max_timer, size}
anim_lerp_speed = 0.15; // How fast units slide to target position

// --- Game Over ---
final_score = 0;
score_submitted = false;
pending_game_over = false;

// --- Load state from API ---
api_load_state(method(self, function(_status, _ok, _result, _payload) {
	try {
		var _state = json_parse(_result);
		username = _state.username;
	}
	catch (_ex) {
	}

	// Start the game — enter shop phase and spawn wave preview
	game_state = 1;
	shop_items = [];
	var _si = 0;
	while (_si < shop_slots) {
		array_push(shop_items, irandom(NUM_UNIT_TYPES - 1));
		_si++;
	}
	shop_timer = shop_timer_max;
	spawn_wave = true; // Flag for Step_0 to generate enemies

	alarm[0] = 60;
}));
