
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

var _lane_w = _w / 3;
var _lc0 = _lane_w * 0.5;
var _lc1 = _lane_w * 1.5;
var _lc2 = _lane_w * 2.5;

// --- BACKGROUND: Road ---
draw_set_colour(make_colour_rgb(45, 45, 55));
draw_rectangle(0, 0, _w, _h, false);

// Sidewalk edges
draw_set_colour(make_colour_rgb(75, 75, 75));
draw_rectangle(0, 0, 8, _h, false);
draw_rectangle(_w - 8, 0, _w, _h, false);

// Lane dividers (dashed, scrolling)
draw_set_colour(make_colour_rgb(180, 180, 180));
var _dash = 30;
var _gap = 30;
var _cycle = _dash + _gap;
var _start_y = -((_cycle) - (scroll_offset mod _cycle));
var _div1 = _lane_w;
var _div2 = _lane_w * 2;
for (var _y = _start_y; _y < _h; _y += _cycle) {
	draw_rectangle(_div1 - 2, _y, _div1 + 2, _y + _dash, false);
	draw_rectangle(_div2 - 2, _y, _div2 + 2, _y + _dash, false);
}

// --- CN TOWER silhouette (background) ---
draw_set_alpha(0.12);
draw_set_colour(make_colour_rgb(140, 140, 170));
var _cn_x = _w * 0.5;
// Antenna
draw_rectangle(_cn_x - 2, _h * 0.02, _cn_x + 2, _h * 0.25, false);
// Shaft
draw_rectangle(_cn_x - 6, _h * 0.08, _cn_x + 6, _h * 0.55, false);
// Pod
draw_circle(_cn_x, _h * 0.28, _lane_w * 0.18, false);
// Base flare
draw_triangle(_cn_x - _lane_w * 0.25, _h * 0.55, _cn_x + _lane_w * 0.25, _h * 0.55, _cn_x, _h * 0.42, false);
draw_set_alpha(1);

// --- COINS ---
for (var _i = 0; _i < array_length(coins); _i++) {
	var _c = coins[_i];
	var _cx = 0;
	if (_c.lane == 0) _cx = _lc0;
	else if (_c.lane == 1) _cx = _lc1;
	else _cx = _lc2;
	var _cr = _lane_w * 0.08;

	// Outer gold
	draw_set_colour(make_colour_rgb(255, 200, 50));
	draw_circle(_cx, _c.y, _cr, false);
	// Inner
	draw_set_colour(make_colour_rgb(255, 170, 0));
	draw_circle(_cx, _c.y, _cr * 0.65, false);
	// $ symbol
	draw_set_colour(c_white);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);
	var _cs = _cr / 10;
	draw_text_ext_transformed(_cx, _c.y, "$", 0, 100, _cs, _cs, 0);
}

// --- OBSTACLES ---
for (var _i = 0; _i < array_length(obstacles); _i++) {
	var _o = obstacles[_i];
	var _ox = 0;
	if (_o.lane == 0) _ox = _lc0;
	else if (_o.lane == 1) _ox = _lc1;
	else _ox = _lc2;
	var _ow = _lane_w * 0.4;
	var _oh = _lane_w * 0.5;

	if (_o.type == 1) {
		// Streetcar / train (red, long)
		_oh = _lane_w * 2.5;
		var _x1 = _ox - _ow * 0.5;
		var _x2 = _ox + _ow * 0.5;
		var _y1 = _o.y - _oh * 0.5;
		var _y2 = _o.y + _oh * 0.5;

		// Body
		draw_set_colour(make_colour_rgb(190, 35, 35));
		draw_rectangle(_x1, _y1, _x2, _y2, false);
		// Roof stripe
		draw_set_colour(make_colour_rgb(220, 60, 60));
		draw_rectangle(_x1 + 2, _y1, _x2 - 2, _y1 + 8, false);
		// Windows (repeating down the train)
		draw_set_colour(make_colour_rgb(150, 200, 255));
		var _win_spacing = _oh / 5;
		for (var _wi = 1; _wi < 5; _wi++) {
			var _wy = _y1 + _wi * _win_spacing;
			draw_rectangle(_x1 + 4, _wy - 4, _ox - 2, _wy + 4, false);
			draw_rectangle(_ox + 2, _wy - 4, _x2 - 4, _wy + 4, false);
		}
		// Bottom bumper
		draw_set_colour(make_colour_rgb(150, 30, 30));
		draw_rectangle(_x1, _y2 - 6, _x2, _y2, false);
	} else {
		// Barrier (orange/yellow)
		draw_set_colour(make_colour_rgb(220, 130, 30));
		draw_rectangle(_ox - _ow * 0.5, _o.y - _oh * 0.5, _ox + _ow * 0.5, _o.y + _oh * 0.5, false);
		// Hazard stripe
		draw_set_colour(make_colour_rgb(255, 200, 50));
		draw_rectangle(_ox - _ow * 0.5, _o.y - 3, _ox + _ow * 0.5, _o.y + 3, false);
	}
}

// --- PLAYER ---
var _ground_y = _h * 0.82;
var _pw = _lane_w * 0.35;
var _ph = _lane_w * 0.45;

// Calculate effective y (jump + train + falling)
var _player_y = _ground_y;
if (on_train) {
	_player_y = _ground_y - _lane_w * 0.2;  // slight elevation
} else if (falling) {
	_player_y = _ground_y + fall_y;  // fall_y is negative, approaches 0
}
_player_y += jump_offset;

// Ground shadow (shows height when jumping/on train)
draw_set_alpha(0.2);
draw_set_colour(c_black);
var _shadow_scale = 1 + (jump_offset / _h) * 2;  // shrinks when higher
if (_shadow_scale < 0.3) _shadow_scale = 0.3;
var _shadow_w = _pw * 0.5 * _shadow_scale;
draw_rectangle(player_x - _shadow_w, _ground_y + _ph * 0.3,
               player_x + _shadow_w, _ground_y + _ph * 0.4, false);
draw_set_alpha(1);

// Body
draw_set_colour(make_colour_rgb(45, 130, 230));
if (on_train) draw_set_colour(make_colour_rgb(50, 200, 120));  // green tint when riding
draw_rectangle(player_x - _pw * 0.5, _player_y - _ph * 0.5,
               player_x + _pw * 0.5, _player_y + _ph * 0.5, false);
// Highlight
draw_set_colour(make_colour_rgb(80, 170, 255));
if (on_train) draw_set_colour(make_colour_rgb(100, 230, 160));
draw_rectangle(player_x - _pw * 0.3, _player_y - _ph * 0.35,
               player_x + _pw * 0.3, _player_y - _ph * 0.05, false);

// --- HUD ---
draw_set_font(fnt_default);

// Score (top center)
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_set_colour(c_white);
var _hud_s = min(_w, _h) * 0.003;
draw_text_ext_transformed(_w * 0.5, 12, string(session_score), 0, _w, _hud_s, _hud_s, 0);

// Speed multiplier (top right)
draw_set_halign(fa_right);
draw_set_colour(make_colour_rgb(255, 200, 50));
var _spd_s = _hud_s * 0.45;
var _mult = game_speed / base_speed;
draw_text_ext_transformed(_w - 10, 15, $"x{string_format(_mult, 1, 1)}", 0, _w, _spd_s, _spd_s, 0);

// Best score (top left)
draw_set_halign(fa_left);
draw_set_colour(make_colour_rgb(180, 180, 180));
draw_text_ext_transformed(10, 15, $"Best: {points}", 0, _w, _spd_s, _spd_s, 0);

// Arrow hints (fade early)
if (game_state == 1 && distance < 400) {
	var _aa = 1 - (distance / 400);
	draw_set_alpha(_aa);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	var _as = _hud_s * 0.7;
	draw_text_ext_transformed(_w * 0.12, _h * 0.5, "<", 0, _w, _as, _as, 0);
	draw_text_ext_transformed(_w * 0.88, _h * 0.5, ">", 0, _w, _as, _as, 0);
	draw_set_alpha(1);
}

// === WAITING STATE OVERLAY ===
if (game_state == 0) {
	draw_set_alpha(0.7);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false);
	draw_set_alpha(1);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);

	// Title
	var _ts = min(_w, _h) * 0.0035;
	draw_set_colour(make_colour_rgb(45, 130, 230));
	draw_text_ext_transformed(_w * 0.5 + 2, _h * 0.28 + 2, "SUBWAY SURFERS", 0, _w * 0.95, _ts, _ts, 0);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.28, "SUBWAY SURFERS", 0, _w * 0.95, _ts, _ts, 0);

	// Subtitle
	draw_set_colour(make_colour_rgb(255, 200, 50));
	var _sub_s = _ts * 0.7;
	draw_text_ext_transformed(_w * 0.5, _h * 0.38, "TORONTO", 0, _w, _sub_s, _sub_s, 0);

	// Tap prompt
	draw_set_colour(make_colour_rgb(200, 200, 200));
	var _ps = _ts * 0.4;
	draw_text_ext_transformed(_w * 0.5, _h * 0.55, "Tap to Start", 0, _w, _ps, _ps, 0);

	// Instructions
	draw_set_colour(make_colour_rgb(150, 150, 150));
	var _is = _ts * 0.3;
	draw_text_ext_transformed(_w * 0.5, _h * 0.63, "Swipe L/R to dodge, UP to jump", 0, _w, _is, _is, 0);

	// Best score
	if (points > 0) {
		draw_set_colour(c_white);
		draw_text_ext_transformed(_w * 0.5, _h * 0.75, $"Best: {points}", 0, _w, _is, _is, 0);
	}
}

// === DEAD STATE OVERLAY ===
if (game_state == 2) {
	draw_set_alpha(0.65);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false);
	draw_set_alpha(1);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(fnt_default);

	// Game over
	var _gs = min(_w, _h) * 0.004;
	draw_set_colour(make_colour_rgb(255, 70, 70));
	draw_text_ext_transformed(_w * 0.5, _h * 0.28, "GAME OVER", 0, _w, _gs, _gs, 0);

	// Run score
	draw_set_colour(c_white);
	var _ss = _gs * 0.55;
	draw_text_ext_transformed(_w * 0.5, _h * 0.43, $"Score: {session_score}", 0, _w, _ss, _ss, 0);

	// Best
	draw_set_colour(make_colour_rgb(255, 200, 50));
	draw_text_ext_transformed(_w * 0.5, _h * 0.53, $"Best: {points}", 0, _w, _ss, _ss, 0);

	// Restart
	draw_set_colour(make_colour_rgb(200, 200, 200));
	var _rs = _gs * 0.35;
	draw_text_ext_transformed(_w * 0.5, _h * 0.68, "Tap to Continue", 0, _w, _rs, _rs, 0);
}
