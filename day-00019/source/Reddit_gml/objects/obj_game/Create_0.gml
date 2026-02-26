
// === TINY TOWN: Kairosoft-style Micro Sim ===
username = "";
level = 0;
points = 0;
prev_points = 0;

// Grid setup: 5 cols x 6 rows
grid_cols = 5;
grid_rows = 6;
grid_total = grid_cols * grid_rows;

// Building types
EMPTY = 0;
HOUSE = 1;
SHOP = 2;
PARK = 3;
TOWER = 4;

// Grid arrays
grid_type = array_create(grid_total, EMPTY);
grid_level = array_create(grid_total, 0);

// Building data: [EMPTY, HOUSE, SHOP, PARK, TOWER]
build_cost =   [0, 10, 25, 15, 50];
build_income = [0, 1,  3,  0,  5];
build_names =  ["", "House", "Shop", "Park", "Tower"];

// Building colors (stored as arrays for rgb)
build_r = [80,  66,  230, 76,  156];
build_g = [80,  135, 126, 175, 100];
build_b = [80,  245, 34,  80,  230];

// Visitor pool
max_visitors = 20;
vis_x = array_create(max_visitors, 0);
vis_y = array_create(max_visitors, 0);
vis_tx = array_create(max_visitors, 0);
vis_ty = array_create(max_visitors, 0);
vis_active = array_create(max_visitors, false);
vis_vip = array_create(max_visitors, false);
vis_speed = array_create(max_visitors, 0);
vis_timer = array_create(max_visitors, 0);
visitor_spawn_timer = 0;

// Float text pool
max_floats = 16;
ft_x = array_create(max_floats, 0);
ft_y = array_create(max_floats, 0);
ft_text = array_create(max_floats, "");
ft_r = array_create(max_floats, 255);
ft_g = array_create(max_floats, 255);
ft_b = array_create(max_floats, 0);
ft_life = array_create(max_floats, 0);

// Combo zones
cell_combo = array_create(grid_total, 1.0);
cell_combo_name = array_create(grid_total, "");
combo_count = 0;

// Star rating
star_rating = 0;
stars_reached = 0;
star_flash = 0;
star_flash_text = "";
star_income_mult = 1.0;

// Income system
income_timer = 0;
income_interval = 120; // every 2 seconds

// Year system
year = 1;
year_timer = 0;
year_duration = 36 * 60; // 36 seconds per year at 60fps
max_years = 5;
year_flash = 0;

// Event system
evt_timer = 0;
evt_interval = 1800; // 30 seconds
EVENT_NONE = 0;
EVENT_BOOM = 1;
EVENT_STORM = 2;
EVENT_VIP = 3;
evt_type = EVENT_NONE;
evt_target = -1;
evt_duration = 0;
evt_flash = 0;
evt_text = "";

// UI state
menu_open = false;
menu_cell = -1;
menu_mode = 0; // 0=build, 1=upgrade
menu_anim = 0;

// Coins and score
coins = 50;
total_earned = 0;

// Game state: 1=playing, 2=game over (always fresh start)
game_state = 1;

// Layout (computed in Draw_64)
window_width = 0;
window_height = 0;
cell_size = 0;
grid_ox = 0;
grid_oy = 0;

// Tap feedback
tap_x = -1;
tap_y = -1;
tap_timer = 0;

// Combo flags (bitmask — a tile can be in multiple zones)
CFLAG_MARKET  = 1;   // House+Shop
CFLAG_PLAZA   = 2;   // Shop+Shop
CFLAG_BIZ     = 4;   // Tower+Shop
CFLAG_SUBURB  = 8;   // House+Park
CFLAG_RESERVE = 16;  // Park+Park
cell_combo_flags = array_create(grid_total, 0);

// Just grab username for leaderboard
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
    } catch (_ex) {}
});
