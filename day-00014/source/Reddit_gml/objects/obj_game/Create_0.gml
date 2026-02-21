
// === GAME STATE ===
game_state = 0; // 0=loading, 1=choosing, 2=reacting, 3=results, 4=game_over
state_loaded = false;

username = "";
points = 0;
best_score = 0;
posts_made = 0;
streak = 0;
max_streak = 0;
reputation = 3.0; // 0-5, starts at 3
day_num = 1;

// === SUBREDDITS ===
sub_names = [];
array_push(sub_names, "r/AskReddit");
array_push(sub_names, "r/aww");
array_push(sub_names, "r/gaming");
array_push(sub_names, "r/science");
array_push(sub_names, "r/mildlyinteresting");
array_push(sub_names, "r/todayilearned");
array_push(sub_names, "r/unpopularopinion");
array_push(sub_names, "r/showerthoughts");
array_push(sub_names, "r/tifu");
array_push(sub_names, "r/nostalgia");

// Preference matrix: sub_prefs[sub_idx][post_type] = 1-5 match score
// Post types: 0=Wholesome, 1=Hot Take, 2=Meme, 3=OC, 4=Shitpost, 5=Repost, 6=Question, 7=Rant
sub_prefs = [];
array_push(sub_prefs, [3, 5, 2, 3, 2, 1, 5, 4]); // AskReddit
array_push(sub_prefs, [5, 1, 4, 3, 1, 3, 2, 1]); // aww
array_push(sub_prefs, [2, 2, 5, 3, 3, 4, 2, 3]); // gaming
array_push(sub_prefs, [2, 1, 1, 5, 1, 2, 4, 1]); // science
array_push(sub_prefs, [3, 2, 3, 5, 2, 1, 2, 1]); // mildlyinteresting
array_push(sub_prefs, [3, 3, 2, 4, 1, 3, 3, 2]); // todayilearned
array_push(sub_prefs, [1, 5, 3, 2, 4, 2, 3, 5]); // unpopularopinion
array_push(sub_prefs, [3, 4, 3, 2, 4, 2, 4, 2]); // showerthoughts
array_push(sub_prefs, [3, 2, 2, 2, 5, 1, 2, 5]); // tifu
array_push(sub_prefs, [4, 1, 4, 3, 2, 5, 2, 2]); // nostalgia

sub_colors = [];
array_push(sub_colors, $4c47ff);
array_push(sub_colors, $79c9ff);
array_push(sub_colors, $3cba46);
array_push(sub_colors, $d49e30);
array_push(sub_colors, $28b8d4);
array_push(sub_colors, $3498db);
array_push(sub_colors, $9b59b6);
array_push(sub_colors, $e67e22);
array_push(sub_colors, $e74c3c);
array_push(sub_colors, $f39c12);

num_subs_unlocked = 3;

// === POST TYPES ===
post_type_names = [];
array_push(post_type_names, "Wholesome Story");
array_push(post_type_names, "Hot Take");
array_push(post_type_names, "Dank Meme");
array_push(post_type_names, "OC Deep Dive");
array_push(post_type_names, "Shitpost");
array_push(post_type_names, "Repost Classic");
array_push(post_type_names, "Genuine Question");
array_push(post_type_names, "Angry Rant");

post_type_emojis = [];
array_push(post_type_emojis, "<3");
array_push(post_type_emojis, "!!");
array_push(post_type_emojis, ":)");
array_push(post_type_emojis, "**");
array_push(post_type_emojis, "xD");
array_push(post_type_emojis, "->");
array_push(post_type_emojis, "??");
array_push(post_type_emojis, ">:(");

// === CURRENT ROUND ===
current_sub = 0;
choice_options = [0, 1, 2, 3];
selected_choice = -1;
choice_timer = 0;
choice_timer_max = 0;

// === REACTION PHASE ===
react_timer = 0;
react_timer_max = 180;
match_score = 0;
vote_count = 0;
vote_target = 0;
comment_count = 0;
comment_target = 0;
award_type = -1;
award_timer = 0;
karma_earned = 0;

// Floating vote arrows
vote_arrows = [];

// === RESULTS PHASE ===
results_timer = 0;
results_tap_ready = false;

// === POST TITLES ===
current_title = "";

title_lists = [];
// 0: wholesome
array_push(title_lists, ["My grandma learned to code today", "Stranger paid for my coffee", "Dog waited 3 hours at the door", "Kid drew me as a superhero", "Found a note from my late father"]);
// 1: hot take
array_push(title_lists, ["Unpopular opinion but...", "I will die on this hill", "Pineapple on pizza is valid", "Hot take: sequels are better", "This is objectively correct"]);
// 2: meme
array_push(title_lists, ["me_irl", "Every single time", "This hits different at 3am", "POV: you opened Reddit again", "nobody: absolutely nobody:"]);
// 3: OC
array_push(title_lists, ["[OC] 6-month research project", "I made a detailed infographic", "Original analysis with data", "After 200 hours of research...", "I built this from scratch"]);
// 4: shitpost
array_push(title_lists, ["hear me out", "am I the only one who", "this but unironically", "bottom text", "I have no explanation for this"]);
// 5: repost
array_push(title_lists, ["Classic gem from 2019", "Never gets old", "Timeless content right here", "Throwback to this banger", "Remember this?"]);
// 6: question
array_push(title_lists, ["What's the weirdest thing you...", "How do you deal with...", "ELI5: Why does this happen?", "Serious: has anyone noticed...", "What would you do if..."]);
// 7: rant
array_push(title_lists, ["I'm so tired of this", "Can we PLEASE stop doing this", "This is getting ridiculous", "Nobody talks about this", "Am I crazy or is this wrong?"]);

// === COMMENT FLAVOR TEXT ===
good_comments = [];
array_push(good_comments, "This is the way");
array_push(good_comments, "Take my upvote");
array_push(good_comments, "Underrated post");
array_push(good_comments, "Based");
array_push(good_comments, "W post");
array_push(good_comments, "This deserves gold");
array_push(good_comments, "Front page material");
array_push(good_comments, "Absolute chad energy");

bad_comments = [];
array_push(bad_comments, "Sir this is a Wendy's");
array_push(bad_comments, "Who asked?");
array_push(bad_comments, "Least unhinged redditor");
array_push(bad_comments, "Ratio");
array_push(bad_comments, "Cringe");
array_push(bad_comments, "Tell me you're new here");
array_push(bad_comments, "Read the room");
array_push(bad_comments, "Wrong sub buddy");

// Floating comments
floating_comments = []; // {x, y, text, alpha, timer}

// === POPUPS ===
popups = [];

// === SCREEN EFFECTS ===
shake_timer = 0;
shake_intensity = 0;
shake_x = 0;
shake_y = 0;

// === LAYOUT ===
window_width = 0;
window_height = 0;
layout_dirty = true;

hud_h = 0;
sub_area_y = 0;
post_card_y = 0;
post_card_h = 0;
choices_y = 0;
choice_btn_h = 0;
post_btn = {x1: 0, y1: 0, x2: 0, y2: 0};
choice_btns = [];

// Game over
final_score = 0;
final_posts = 0;
final_streak = 0;
score_submitted = false;
game_over_tap_delay = 0;

// New sub announcement
new_sub_timer = 0;
new_sub_name = "";

// === LOAD STATE ===
api_load_state(function(_status, _ok, _result, _payload) {
    try {
        var _state = json_parse(_result);
        username = _state.username;
        if (variable_struct_exists(_state.data, "best_score")) {
            best_score = _state.data.best_score;
        }
        if (variable_struct_exists(_state.data, "reputation")) {
            if (_state.data.reputation > 0) {
                points = _state.data.points;
                reputation = _state.data.reputation;
                posts_made = _state.data.posts_made;
                day_num = _state.data.day_num;
                num_subs_unlocked = _state.data.num_subs_unlocked;
                streak = _state.data.streak;
            }
        }
    }
    catch (_ex) {
        api_save_state(0, { points: 0, reputation: 3.0, posts_made: 0, day_num: 1, num_subs_unlocked: 3, streak: 0, best_score: 0 }, undefined);
    }
    state_loaded = true;
    alarm[0] = 60 * 15;
});
