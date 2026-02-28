
username = "";
level = 0;
points = 0;
prev_points = 0;

// === GAME STATE ===
// 0=loading, 1=player turn, 2=ai turn, 3=animating, 4=game over
// Sub-states for player turn:
//   phase: "draw","play","action","done"
game_state = 0;
turn_phase = "draw";

// === BOARD: 5x6 grid (extra row for more space) ===
GRID_W = 5;
GRID_H = 6;
BOARD_SIZE = GRID_W * GRID_H;

// Board arrays
board_type  = array_create(BOARD_SIZE, 0);
board_owner = array_create(BOARD_SIZE, -1);
board_hp    = array_create(BOARD_SIZE, 0);
board_max_hp = array_create(BOARD_SIZE, 0);
board_atk   = array_create(BOARD_SIZE, 0);
board_has_acted = array_create(BOARD_SIZE, false); // moved/attacked this turn
board_keyword = array_create(BOARD_SIZE, 0); // keyword flags
board_can_act = array_create(BOARD_SIZE, false); // summoning sickness

// === PIECE TYPES ===
PIECE_NONE   = 0;
PIECE_PAWN   = 1;  // basic 1/2
PIECE_KNIGHT = 2;  // 3/3 Battlecry: 1 dmg to adjacent enemy
PIECE_BISHOP = 3;  // 2/4 Deathrattle: heal adjacent friendlies 2
PIECE_ROOK   = 4;  // 2/6 Taunt
PIECE_KING   = 5;  // 2/8 Hero

// Keywords
KW_NONE       = 0;
KW_TAUNT      = 1;
KW_BATTLECRY  = 2;
KW_DEATHRATTLE = 4;

// Base stats [atk, hp, keyword, mana_cost]
piece_base_atk = array_create(6, 0);
piece_base_atk[PIECE_PAWN]   = 1;
piece_base_atk[PIECE_KNIGHT] = 3;
piece_base_atk[PIECE_BISHOP] = 2;
piece_base_atk[PIECE_ROOK]   = 2;
piece_base_atk[PIECE_KING]   = 2;

piece_base_hp = array_create(6, 0);
piece_base_hp[PIECE_PAWN]   = 2;
piece_base_hp[PIECE_KNIGHT] = 3;
piece_base_hp[PIECE_BISHOP] = 4;
piece_base_hp[PIECE_ROOK]   = 6;
piece_base_hp[PIECE_KING]   = 8;

piece_base_kw = array_create(6, 0);
piece_base_kw[PIECE_KNIGHT] = KW_BATTLECRY;
piece_base_kw[PIECE_BISHOP] = KW_DEATHRATTLE;
piece_base_kw[PIECE_ROOK]   = KW_TAUNT;

piece_mana_cost = array_create(6, 0);
piece_mana_cost[PIECE_PAWN]   = 1;
piece_mana_cost[PIECE_KNIGHT] = 3;
piece_mana_cost[PIECE_BISHOP] = 3;
piece_mana_cost[PIECE_ROOK]   = 4;

piece_names = array_create(6, "");
piece_names[PIECE_NONE]   = "";
piece_names[PIECE_PAWN]   = "Pawn";
piece_names[PIECE_KNIGHT] = "Knight";
piece_names[PIECE_BISHOP] = "Bishop";
piece_names[PIECE_ROOK]   = "Rook";
piece_names[PIECE_KING]   = "King";

piece_symbols = array_create(6, "");
piece_symbols[PIECE_PAWN]   = "P";
piece_symbols[PIECE_KNIGHT] = "N";
piece_symbols[PIECE_BISHOP] = "B";
piece_symbols[PIECE_ROOK]   = "R";
piece_symbols[PIECE_KING]   = "K";

kw_names_taunt = "TAUNT";
kw_names_battlecry = "BATTLECRY";
kw_names_deathrattle = "DEATHRATTLE";

// === SPELL TYPES ===
SPELL_FIREBALL = 10;  // 3 dmg to any enemy, cost 2
SPELL_HEAL     = 11;  // heal 3 HP, cost 1
SPELL_SHIELD   = 12;  // give +2 HP, cost 2
SPELL_RAGE     = 13;  // give +2 ATK this turn, cost 2

spell_names = ds_map_create();
ds_map_add(spell_names, SPELL_FIREBALL, "Fireball");
ds_map_add(spell_names, SPELL_HEAL, "Heal");
ds_map_add(spell_names, SPELL_SHIELD, "Shield");
ds_map_add(spell_names, SPELL_RAGE, "Rage");

spell_costs = ds_map_create();
ds_map_add(spell_costs, SPELL_FIREBALL, 2);
ds_map_add(spell_costs, SPELL_HEAL, 1);
ds_map_add(spell_costs, SPELL_SHIELD, 2);
ds_map_add(spell_costs, SPELL_RAGE, 2);

spell_descs = ds_map_create();
ds_map_add(spell_descs, SPELL_FIREBALL, "3 dmg");
ds_map_add(spell_descs, SPELL_HEAL, "Heal 3");
ds_map_add(spell_descs, SPELL_SHIELD, "+2 HP");
ds_map_add(spell_descs, SPELL_RAGE, "+2 ATK");

// === CARD / HAND SYSTEM ===
// Cards: positive = minion piece type, 10+ = spell
MAX_HAND = 5;
player_hand = array_create(MAX_HAND, 0); // card type (0=empty)
player_hand_count = 0;
ai_hand = array_create(MAX_HAND, 0);
ai_hand_count = 0;

// Deck: list of card types to draw from
player_deck = ds_list_create();
ai_deck = ds_list_create();

// Fill decks (2x each minion + spells)
var _deck_template = [
    PIECE_PAWN, PIECE_PAWN, PIECE_PAWN, PIECE_PAWN,
    PIECE_KNIGHT, PIECE_KNIGHT,
    PIECE_BISHOP, PIECE_BISHOP,
    PIECE_ROOK, PIECE_ROOK,
    SPELL_FIREBALL, SPELL_FIREBALL,
    SPELL_HEAL, SPELL_HEAL,
    SPELL_SHIELD,
    SPELL_RAGE,
];

var _di = 0;
while (_di < array_length(_deck_template)) {
    ds_list_add(player_deck, _deck_template[_di]);
    ds_list_add(ai_deck, _deck_template[_di]);
    _di++;
}

// Shuffle decks
ds_list_shuffle(player_deck);
ds_list_shuffle(ai_deck);

// === MANA ===
turn_number = 0; // incremented at start of each player turn
player_mana = 0;
player_max_mana = 0;
ai_mana = 0;
ai_max_mana = 0;

// Hero power
hero_power_used = false; // once per turn, 2 mana, 1 dmg
ai_hero_power_used = false;

// === SELECTION ===
selected_row = -1;
selected_col = -1;
selected_card = -1;  // index in hand (-1 = none)
selected_spell = -1; // spell being targeted
valid_moves = array_create(BOARD_SIZE, false);
valid_summons = array_create(BOARD_SIZE, false);
input_mode = "none"; // "none","piece","card","spell_target","hero_power"

// === ANIMATION ===
anim_timer = 0;
anim_duration = 12;
anim_atk_idx = -1;
anim_def_idx = -1;
anim_callback = -1;
dmg_particles = ds_list_create();

// Move animation: piece slides from one cell to another
move_anim_active = false;
move_anim_timer = 0;
move_anim_duration = 10;
move_anim_from_idx = -1;
move_anim_to_idx = -1;
move_anim_type = PIECE_NONE;  // piece type being animated
move_anim_owner = -1;
move_anim_is_attack = false;  // true = lunge attack animation

// Combat animation: attacker lunges toward defender then snaps back
combat_anim_active = false;
combat_anim_timer = 0;
combat_anim_duration = 16;
combat_anim_from_idx = -1;
combat_anim_to_idx = -1;
combat_anim_type = PIECE_NONE;
combat_anim_owner = -1;
combat_anim_phase = 0; // 0=lunge forward, 1=snap back

// Summon animation: piece scales up from 0
summon_anim_active = false;
summon_anim_timer = 0;
summon_anim_duration = 14;
summon_anim_idx = -1;

// Pulse timer for actionable pieces
pulse_timer = 0;

// New card highlight
new_card_idx = -1;
new_card_timer = 0;

// === AI ===
ai_thinking_timer = 0;
ai_action_queue = ds_list_create(); // queued AI actions

// === UI ===
message = "Loading...";
message_timer = 0;
total_damage_dealt = 0;
game_over_submitted = false;

// this is stored (create event)
window_width = 0;
window_height = 0;

// === INIT BOARD: Just kings ===
// Player king at bottom center (row 5, col 2)
var _pk = 5 * GRID_W + 2;
board_type[_pk]   = PIECE_KING;
board_owner[_pk]  = 0;
board_hp[_pk]     = piece_base_hp[PIECE_KING];
board_max_hp[_pk] = piece_base_hp[PIECE_KING];
board_atk[_pk]    = piece_base_atk[PIECE_KING];
board_can_act[_pk] = true;

// AI king at top center (row 0, col 2)
var _ak = 0 * GRID_W + 2;
board_type[_ak]   = PIECE_KING;
board_owner[_ak]  = 1;
board_hp[_ak]     = piece_base_hp[PIECE_KING];
board_max_hp[_ak] = piece_base_hp[PIECE_KING];
board_atk[_ak]    = piece_base_atk[PIECE_KING];
board_can_act[_ak] = true;

// Draw starting hands (3 cards each)
// Using a manual approach to avoid closure issues
var _draws = 0;
while (_draws < 3 && ds_list_size(player_deck) > 0 && player_hand_count < MAX_HAND) {
    player_hand[player_hand_count] = player_deck[| 0];
    ds_list_delete(player_deck, 0);
    player_hand_count++;
    _draws++;
}
_draws = 0;
while (_draws < 3 && ds_list_size(ai_deck) > 0 && ai_hand_count < MAX_HAND) {
    ai_hand[ai_hand_count] = ai_deck[| 0];
    ds_list_delete(ai_deck, 0);
    ai_hand_count++;
    _draws++;
}

// === LOAD STATE ===
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        level = _state.level;
        points = _state.data.points;
    }
    catch (_ex) {
        api_save_state(0, { points: points }, undefined);
    }
    // Start first turn
    turn_number = 1;
    player_mana = 1;
    player_max_mana = 1;
    hero_power_used = false;
    turn_phase = "play";
    game_state = 1;
    message = "Turn 1 - Play cards or move pieces!";
    message_timer = 90;
    alarm[0] = 60;
});
