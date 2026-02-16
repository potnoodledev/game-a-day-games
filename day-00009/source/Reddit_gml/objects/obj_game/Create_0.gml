
// === PILATES FLOW — Pose Sequence Minigames ===
// Go through pilates poses. Each pose is a minigame: HOLD, BREATHE, or BALANCE.
// Animated stick figure transitions between poses.

// --- Core State ---
game_state = 0; // 0=title, 1=preview, 2=pose_intro, 3=minigame, 4=result, 5=gameover
points = 0;
prev_points = 0;
username = "";
level = 0;
window_width = 0;
window_height = 0;

// --- Score ---
run_score = 0;
score_accum = 0; // fractional accumulator — run_score = floor(score_accum)
poses_completed = 0;
difficulty = 1.0;

// --- Session Timer ---
session_max = 2400; // 40 seconds at 60fps
session_timer = session_max;

// --- Preview ---
preview_timer = 0;
preview_pose_idx = 0;
preview_pose_hold = 40; // frames per pose in preview

// --- Pose Management ---
// Pose types: 0=HOLD, 1=BREATHE, 2=BALANCE
pose_name_list = ["Standing", "Plank", "Tree Pose", "Hundred", "Bridge", "Warrior", "V-Sit", "Side Plank"];
pose_types = [-1, 0, 2, 1, 0, 2, 0, 2];
mg_type_names = ["HOLD", "BREATHE", "BALANCE"];
pose_queue = [1, 2, 3, 4, 5, 6, 7];
pose_queue_idx = 0;
current_pose_id = 0;

// --- Stick Figure Joint Positions ---
// 22 values per pose: head_x,y, chest_x,y, hip_x,y,
//   l_hand_x,y, r_hand_x,y, l_elbow_x,y, r_elbow_x,y,
//   l_foot_x,y, r_foot_x,y, l_knee_x,y, r_knee_x,y
all_poses = [];

// Standing (neutral)
all_poses[0] = [0,-3.5, 0,-2.2, 0,-0.5,
  -0.8,-0.5, 0.8,-0.5, -0.5,-1.3, 0.5,-1.3,
  -0.5,2.5, 0.5,2.5, -0.3,1.0, 0.3,1.0];

// Plank (HOLD)
all_poses[1] = [-2.5,-0.5, -1.2,0.0, 1.0,0.2,
  -1.5,2.0, -0.9,2.0, -1.5,1.0, -0.9,1.0,
  2.5,0.5, 2.8,0.5, 1.8,0.35, 2.1,0.35];

// Tree Pose (BALANCE)
all_poses[2] = [0,-3.5, 0,-2.2, 0,-0.5,
  -1.5,-4.2, 1.5,-4.2, -0.8,-3.2, 0.8,-3.2,
  0.0,2.5, 0.6,-0.5, 0.0,1.0, 1.0,-0.2];

// Hundred (BREATHE)
all_poses[3] = [-2.5,0.5, -1.2,0.3, 0.5,0.5,
  -0.3,-1.0, 0.2,-1.0, -0.8,-0.3, -0.3,-0.3,
  2.2,-1.8, 2.5,-1.5, 1.3,-0.5, 1.5,-0.3];

// Bridge (HOLD)
all_poses[4] = [-2.5,1.2, -1.2,0.5, 0.3,-0.3,
  -2.8,1.2, -2.2,1.2, -2.2,0.8, -1.8,0.8,
  1.8,1.2, 2.2,1.2, 1.0,0.0, 1.4,0.0];

// Warrior II (BALANCE)
all_poses[5] = [0,-3.5, 0,-2.2, 0,-0.5,
  -2.8,-2.2, 2.8,-2.2, -1.4,-2.2, 1.4,-2.2,
  -1.8,2.5, 1.8,2.5, -1.5,0.5, 1.2,1.5];

// V-Sit (HOLD)
all_poses[6] = [-0.5,-2.8, -0.2,-1.5, 0.3,0.5,
  1.0,-2.2, 1.5,-2.2, 0.4,-1.8, 0.8,-1.8,
  1.5,-1.8, 2.0,-1.8, 0.8,-0.5, 1.2,-0.5];

// Side Plank (BALANCE)
all_poses[7] = [-1.8,-1.8, -0.8,-0.5, 0.8,0.3,
  -1.2,-3.0, -1.0,1.5, -1.0,-1.8, -0.9,0.5,
  2.2,0.8, 2.2,1.0, 1.5,0.5, 1.5,0.7];

// Current & target figure joints
fig_current = array_create(22, 0);
fig_target = array_create(22, 0);
fig_display = array_create(22, 0);
array_copy(fig_current, 0, all_poses[0], 0, 22);
array_copy(fig_target, 0, all_poses[0], 0, 22);
array_copy(fig_display, 0, all_poses[0], 0, 22);
fig_lerp_speed = 0.06;

// --- Timing ---
intro_timer = 0;
result_timer = 0;
result_text = "";
result_col = c_white;
tap_cooldown = 0;

// --- Minigame Common ---
minigame_type = 0;
mg_phase = 0;
mg_result = -1;

// --- HOLD Minigame ---
hold_setup_timer = 0;
hold_timer = 0;
hold_max = 180; // shorter hold window
hold_holding = false;
hold_wait_timer = 0;
// Zone boundaries — tight green zone for challenge
hold_green_start = 0.68;
hold_green_end = 0.84;

// --- BREATHE Minigame ---
br_phase = 0;
br_speed = 0;
br_radius = 0;
br_prev_radius = 0;
br_center = 0.5;
br_amplitude = 0.25;
br_target = 0.65;
br_cycle_frames = 140; // faster breathing (~2.3s per cycle)
br_total_cycles = 2;
br_window = 14; // tighter hit window
br_crossing_active = false;
br_crossing_timer = 0;
br_crossing_tapped = false;
br_crossings_done = 0;
br_hits = 0;
br_timer = 0;
br_duration = 0;

// --- BALANCE Minigame ---
bal_x = 0;
bal_vel = 0;
bal_timer = 0;
bal_duration = 240; // 4 seconds
bal_zone_frames = 0;
bal_zone_size = 0.20; // smaller center zone
bal_tap_cooldown = 0;

// --- Visual ---
shake = 0;
flash_timer = 0;
part_x = [];
part_y = [];
part_text = [];
part_life = [];
part_max_life = [];
part_col = [];
part_count = 0;

// --- Colors ---
bg_top = make_colour_rgb(235, 242, 255);
bg_bot = make_colour_rgb(252, 248, 243);
text_dark = make_colour_rgb(55, 55, 75);
gold_col = make_colour_rgb(255, 200, 50);
fig_col = make_colour_rgb(160, 140, 175);
heart_col = make_colour_rgb(255, 100, 120);
heart_empty = make_colour_rgb(200, 200, 210);

// Pastel palette (for zone coloring and decorations)
zone_green = make_colour_rgb(130, 210, 140);
zone_yellow = make_colour_rgb(240, 210, 100);
zone_red = make_colour_rgb(240, 120, 120);
zone_blue = make_colour_rgb(130, 180, 240);

// --- Load saved state ---
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        if (_ok) {
            var _data = json_parse(_result);
            if (variable_struct_exists(_data, "username")) username = _data.username;
            if (variable_struct_exists(_data, "data")) {
                var _d = _data.data;
                if (variable_struct_exists(_d, "points")) {
                    points = _d.points;
                    prev_points = points;
                }
                if (variable_struct_exists(_d, "level")) level = _d.level;
            }
        }
    } catch(e) {}
    alarm[0] = 60;
});
