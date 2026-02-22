
// ============================================================
// AUTO CHESS — Draw_64 (GUI Layer Rendering)
// ============================================================

var _w = window_width;
var _h = window_height;
if (_w <= 0) _w = window_get_width();
if (_h <= 0) _h = window_get_height();

// --- Background ---
draw_set_colour(make_colour_rgb(20, 22, 30));
draw_rectangle(0, 0, _w, _h, false);

// --- Scale factor ---
var _scale = max(1.0, _h * 0.0015);

// ============================================================
// STATE 0: LOADING
// ============================================================
if (game_state == 0) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	draw_set_font(fnt_default);
	draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Loading...", 0, _w, _scale * 2, _scale * 2, 0);
	exit;
}

// ============================================================
// HUD — Top Bar (Gold, Lives, Round)
// ============================================================
// HUD background
draw_set_colour(make_colour_rgb(30, 35, 50));
draw_rectangle(0, 0, _w, hud_h, false);

draw_set_font(fnt_default);
var _hud_scale = max(1.2, _h * 0.002);
var _hud_y = hud_h * 0.5;
var _pad = max(8, _w * 0.02);

// Round
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
var _round_text = "Round " + string(current_round);
if (current_round mod 5 == 0 && game_state == 2) _round_text = "BOSS Round " + string(current_round);
draw_text_ext_transformed(_pad, _hud_y, _round_text, 0, _w, _hud_scale, _hud_scale, 0);

// Score
draw_set_halign(fa_right);
draw_set_colour(c_white);
draw_text_ext_transformed(_w - _pad, _hud_y, "Score: " + string(points), 0, _w, _hud_scale, _hud_scale, 0);

// ============================================================
// SYNERGY BAR — Below HUD
// ============================================================
var _syn_y = hud_h + 2;
var _syn_h = max(20, _h * 0.03);
draw_set_colour(make_colour_rgb(25, 28, 40));
draw_rectangle(0, _syn_y, _w, _syn_y + _syn_h, false);

draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var _syn_scale = max(0.8, _h * 0.0012);
var _sx = _pad;
var _syn_colors = array_create(NUM_TAGS);
_syn_colors[0] = make_colour_rgb(220, 100, 50);   // Frontline - orange
_syn_colors[1] = make_colour_rgb(50, 200, 50);     // Ranged - green
_syn_colors[2] = make_colour_rgb(150, 80, 255);    // Mystic - purple
_syn_colors[3] = make_colour_rgb(200, 200, 100);   // Armored - gold
_syn_colors[4] = make_colour_rgb(200, 50, 200);    // Assassin - magenta

var _ti = 0;
while (_ti < NUM_TAGS) {
	if (active_synergies[_ti]) {
		draw_set_colour(_syn_colors[_ti]);
		draw_text_ext_transformed(_sx, _syn_y + _syn_h * 0.5, tag_names[_ti], 0, _w, _syn_scale, _syn_scale, 0);
		_sx += string_width(tag_names[_ti]) * _syn_scale + _pad;
	}
	_ti++;
}

// ============================================================
// GRID
// ============================================================
var _grid_top = grid_y;

// Draw grid cells
var _row = 0;
while (_row < grid_rows) {
	var _col = 0;
	while (_col < grid_cols) {
		var _cx = grid_x + _col * cell_size;
		var _cy = grid_y + _row * cell_size;

		// Cell background
		if (_row < player_rows_start) {
			// Enemy rows — darker
			draw_set_colour(make_colour_rgb(40, 25, 25));
		} else {
			// Player rows — darker blue
			draw_set_colour(make_colour_rgb(25, 30, 45));
		}
		draw_rectangle(_cx + 1, _cy + 1, _cx + cell_size - 1, _cy + cell_size - 1, false);

		// Cell border
		draw_set_colour(make_colour_rgb(60, 65, 80));
		draw_rectangle(_cx, _cy, _cx + cell_size, _cy + cell_size, true);

		_col++;
	}
	_row++;
}

// Divider line between enemy/player rows
draw_set_colour(make_colour_rgb(100, 100, 120));
var _div_y = grid_y + player_rows_start * cell_size;
draw_line_width(grid_x, _div_y, grid_x + grid_cols * cell_size, _div_y, 2);

// ============================================================
// DRAW UNITS
// ============================================================
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_default);
var _unit_scale = max(1.0, cell_size * 0.018);

// --- Draw enemy units ---
var _ei = 0;
while (_ei < array_length(enemy_units)) {
	var _e = enemy_units[_ei];
	if (_e.alive) {
		var _ux = _e.draw_x;
		var _uy = _e.draw_y;
		if (game_state != 2) {
			_ux = grid_x + _e.grid_col * cell_size + cell_size * 0.5;
			_uy = grid_y + _e.grid_row * cell_size + cell_size * 0.5;
		}
		var _r = cell_size * 0.35;

		// Enemy tint: darken color slightly
		var _c = unit_colors[_e.unit_type];
		draw_set_colour(_c);
		draw_set_alpha(0.8);
		draw_circle(_ux, _uy, _r, false);
		draw_set_alpha(1.0);

		// Dark border
		draw_set_colour(make_colour_rgb(80, 20, 20));
		draw_circle(_ux, _uy, _r, true);

		// Letter
		draw_set_colour(c_white);
		draw_text_ext_transformed(_ux, _uy, unit_letters[_e.unit_type], 0, cell_size, _unit_scale, _unit_scale, 0);

		// Star level
		if (_e.star > 1) {
			draw_set_colour(make_colour_rgb(255, 215, 0));
			var _star_text = "";
			var _si2 = 0;
			while (_si2 < _e.star) { _star_text += "*"; _si2++; }
			draw_set_valign(fa_bottom);
			draw_text_ext_transformed(_ux, _uy - _r - 2, _star_text, 0, cell_size, _unit_scale * 0.8, _unit_scale * 0.8, 0);
			draw_set_valign(fa_middle);
		}

		// HP bar
		var _bar_w = cell_size * 0.7;
		var _bar_h = max(3, cell_size * 0.06);
		var _bar_x = _ux - _bar_w * 0.5;
		var _bar_y = _uy + _r + 3;
		var _hp_pct = clamp(_e.hp / _e.max_hp, 0, 1);
		draw_set_colour(make_colour_rgb(40, 40, 40));
		draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
		if (_hp_pct > 0.5) draw_set_colour(make_colour_rgb(50, 200, 50));
		else if (_hp_pct > 0.25) draw_set_colour(make_colour_rgb(220, 180, 30));
		else draw_set_colour(make_colour_rgb(220, 40, 40));
		draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _hp_pct, _bar_y + _bar_h, false);
	}
	_ei++;
}

// --- Draw player units ---
var _bi = 0;
while (_bi < array_length(board_units)) {
	var _u = board_units[_bi];

	// If dragging this unit, draw at drag position
	var _is_dragged = (dragging && drag_unit_idx == _bi);
	var _ux = 0;
	var _uy = 0;

	if (_is_dragged) {
		_ux = drag_ox;
		_uy = drag_oy;
	} else if (game_state == 2) {
		_ux = _u.draw_x;
		_uy = _u.draw_y;
	} else {
		_ux = grid_x + _u.grid_col * cell_size + cell_size * 0.5;
		_uy = grid_y + _u.grid_row * cell_size + cell_size * 0.5;
	}

	if (_u.alive || game_state == 1) {
		var _r = cell_size * 0.38;

		// Synergy glow
		var _has_active_syn = false;
		var _gi = 0;
		while (_gi < array_length(unit_tags[_u.unit_type])) {
			if (active_synergies[unit_tags[_u.unit_type][_gi]]) _has_active_syn = true;
			_gi++;
		}
		if (_has_active_syn && game_state == 2) {
			draw_set_alpha(0.3 + sin(battle_tick * 0.1) * 0.15);
			draw_set_colour(make_colour_rgb(255, 255, 200));
			draw_circle(_ux, _uy, _r + 4, false);
			draw_set_alpha(1.0);
		}

		// Unit circle
		draw_set_colour(unit_colors[_u.unit_type]);
		draw_circle(_ux, _uy, _r, false);

		// Border (brighter for higher stars)
		if (_u.star >= 3) draw_set_colour(make_colour_rgb(255, 215, 0));
		else if (_u.star >= 2) draw_set_colour(make_colour_rgb(200, 200, 200));
		else draw_set_colour(make_colour_rgb(100, 100, 120));
		draw_circle(_ux, _uy, _r, true);

		// Unit letter
		draw_set_colour(c_white);
		draw_text_ext_transformed(_ux, _uy, unit_letters[_u.unit_type], 0, cell_size, _unit_scale * (0.8 + _u.star * 0.2), _unit_scale * (0.8 + _u.star * 0.2), 0);

		// Star level
		if (_u.star > 1) {
			draw_set_colour(make_colour_rgb(255, 215, 0));
			var _star_text = "";
			var _si3 = 0;
			while (_si3 < _u.star) { _star_text += "*"; _si3++; }
			draw_set_valign(fa_bottom);
			draw_text_ext_transformed(_ux, _uy - _r - 2, _star_text, 0, cell_size, _unit_scale * 0.8, _unit_scale * 0.8, 0);
			draw_set_valign(fa_middle);
		}

		// HP bar (only during battle)
		if (game_state == 2 && _u.alive) {
			var _bar_w = cell_size * 0.7;
			var _bar_h = max(3, cell_size * 0.06);
			var _bar_x = _ux - _bar_w * 0.5;
			var _bar_y = _uy + _r + 3;
			var _hp_pct = clamp(_u.hp / _u.max_hp, 0, 1);
			draw_set_colour(make_colour_rgb(40, 40, 40));
			draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
			if (_hp_pct > 0.5) draw_set_colour(make_colour_rgb(50, 200, 50));
			else if (_hp_pct > 0.25) draw_set_colour(make_colour_rgb(220, 180, 30));
			else draw_set_colour(make_colour_rgb(220, 40, 40));
			draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _hp_pct, _bar_y + _bar_h, false);
		}
	}
	_bi++;
}

// ============================================================
// PROJECTILES
// ============================================================
var _pri = 0;
while (_pri < array_length(projectiles)) {
	var _pr = projectiles[_pri];
	if (variable_struct_exists(_pr, "cx")) {
		draw_set_colour(_pr.color);
		draw_set_alpha(0.9);
		draw_circle(_pr.cx, _pr.cy, _pr.size, false);
		// Bright core
		draw_set_colour(c_white);
		draw_set_alpha(0.7);
		draw_circle(_pr.cx, _pr.cy, _pr.size * 0.5, false);
		// Trail
		var _trail_prog = _pr.timer / _pr.max_timer;
		draw_set_colour(_pr.color);
		draw_set_alpha(0.3);
		var _trail_x = _pr.cx + (_pr.x - _pr.tx) * 0.15;
		var _trail_y = _pr.cy + (_pr.y - _pr.ty) * 0.15;
		draw_circle(_trail_x, _trail_y, _pr.size * 0.7, false);
		draw_set_alpha(1.0);
	}
	_pri++;
}

// ============================================================
// DEATH ANIMATIONS
// ============================================================
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var _dai = 0;
while (_dai < array_length(death_anims)) {
	var _da = death_anims[_dai];
	var _dprog = _da.timer / _da.max_timer; // 1 -> 0
	var _dr = _da.r * _dprog; // shrink
	draw_set_colour(_da.color);
	draw_set_alpha(_dprog * 0.7);
	draw_circle(_da.x, _da.y, _dr, false);
	// Expanding ring
	draw_set_alpha(_dprog * 0.4);
	draw_set_colour(c_white);
	draw_circle(_da.x, _da.y, _da.r * (1.0 + (1.0 - _dprog) * 0.8), true);
	draw_set_alpha(1.0);
	_dai++;
}

// ============================================================
// DAMAGE NUMBERS
// ============================================================
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
var _di = 0;
while (_di < array_length(damage_numbers)) {
	var _dn = damage_numbers[_di];
	draw_set_colour(_dn.col);
	draw_set_alpha(clamp(_dn.timer / 20.0, 0, 1));
	draw_text_ext_transformed(_dn.x, _dn.y, _dn.text, 0, 200, _unit_scale * 1.2, _unit_scale * 1.2, 0);
	draw_set_alpha(1.0);
	_di++;
}

// ============================================================
// SHOP PANEL (State 1)
// ============================================================
if (game_state == 1) {
	// Shop background
	draw_set_colour(make_colour_rgb(30, 35, 50));
	draw_rectangle(0, shop_y, _w, _h, false);

	// Shop border
	draw_set_colour(make_colour_rgb(80, 85, 100));
	draw_line_width(0, shop_y, _w, shop_y, 2);

	// Timer bar
	var _timer_pct = clamp(shop_timer / shop_timer_max, 0, 1);
	draw_set_colour(make_colour_rgb(50, 180, 50));
	draw_rectangle(0, shop_y, _w * _timer_pct, shop_y + 3, false);

	// Gold display (prominent, left side of shop bar)
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	var _shop_label_scale = max(1.0, _h * 0.0014);
	draw_set_colour(make_colour_rgb(255, 215, 0));
	draw_text_ext_transformed(_pad, shop_y + 6, "Gold: " + string(gold), 0, _w, _shop_label_scale * 1.1, _shop_label_scale * 1.1, 0);

	// Unit count (right side)
	draw_set_halign(fa_right);
	draw_set_colour(make_colour_rgb(150, 150, 170));
	draw_text_ext_transformed(_w - _pad, shop_y + 6, string(array_length(board_units)) + "/" + string(max_board_units), 0, _w, _shop_label_scale * 0.9, _shop_label_scale * 0.9, 0);

	// Shop items
	var _name_scale = max(0.7, _h * 0.001);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _shop_item_h = max(50, (_h - shop_y - 40) * 0.45);
	var _shop_item_w = min((_w - _pad * 2) / shop_slots - _pad, _shop_item_h * 1.2);
	var _total_shop_w = shop_slots * (_shop_item_w + _pad) - _pad;
	var _shop_start_x = (_w - _total_shop_w) * 0.5;
	var _shop_items_y = shop_y + max(28, _h * 0.035);

	shop_btns = [];
	var _si = 0;
	while (_si < shop_slots) {
		var _ix = _shop_start_x + _si * (_shop_item_w + _pad);
		var _iy = _shop_items_y;

		var _btn_data = { x1: _ix, y1: _iy, x2: _ix + _shop_item_w, y2: _iy + _shop_item_h };
		array_push(shop_btns, _btn_data);

		if (_si < array_length(shop_items) && shop_items[_si] >= 0) {
			var _type = shop_items[_si];
			var _cost = unit_stats[_type][UNIT_COST];
			var _can_buy = (gold >= _cost && array_length(board_units) < max_board_units);

			// Card background
			if (_can_buy) draw_set_colour(make_colour_rgb(40, 45, 65));
			else draw_set_colour(make_colour_rgb(30, 30, 40));
			draw_rectangle(_ix, _iy, _ix + _shop_item_w, _iy + _shop_item_h, false);

			// Card border
			draw_set_colour(unit_colors[_type]);
			draw_set_alpha(_can_buy ? 1.0 : 0.3);
			draw_rectangle(_ix, _iy, _ix + _shop_item_w, _iy + _shop_item_h, true);
			draw_set_alpha(1.0);

			// Unit circle preview
			var _preview_r = min(_shop_item_w, _shop_item_h) * 0.22;
			var _preview_x = _ix + _shop_item_w * 0.5;
			var _preview_y = _iy + _shop_item_h * 0.35;
			draw_set_colour(unit_colors[_type]);
			draw_set_alpha(_can_buy ? 1.0 : 0.4);
			draw_circle(_preview_x, _preview_y, _preview_r, false);
			draw_set_alpha(1.0);

			// Letter
			draw_set_colour(c_white);
			var _card_scale = max(0.9, _shop_item_h * 0.012);
			draw_text_ext_transformed(_preview_x, _preview_y, unit_letters[_type], 0, _shop_item_w, _card_scale, _card_scale, 0);

			// Name
			draw_set_valign(fa_top);
			draw_set_colour(_can_buy ? c_white : make_colour_rgb(100, 100, 110));
			var _name_scale = max(0.7, _shop_item_h * 0.008);
			draw_text_ext_transformed(_preview_x, _iy + _shop_item_h * 0.62, unit_names[_type], 0, _shop_item_w, _name_scale, _name_scale, 0);

			// Cost
			draw_set_colour(_can_buy ? make_colour_rgb(255, 215, 0) : make_colour_rgb(120, 100, 50));
			draw_text_ext_transformed(_preview_x, _iy + _shop_item_h * 0.8, string(_cost) + "g", 0, _shop_item_w, _name_scale, _name_scale, 0);
			draw_set_valign(fa_middle);
		} else {
			// Empty slot
			draw_set_colour(make_colour_rgb(30, 30, 40));
			draw_rectangle(_ix, _iy, _ix + _shop_item_w, _iy + _shop_item_h, false);
			draw_set_colour(make_colour_rgb(50, 50, 60));
			draw_rectangle(_ix, _iy, _ix + _shop_item_w, _iy + _shop_item_h, true);
			draw_set_colour(make_colour_rgb(60, 60, 70));
			draw_text_ext_transformed(_ix + _shop_item_w * 0.5, _iy + _shop_item_h * 0.5, "SOLD", 0, _shop_item_w, _unit_scale * 0.8, _unit_scale * 0.8, 0);
		}
		_si++;
	}

	// --- GO button ---
	var _go_w = max(80, _w * 0.2);
	var _go_h = max(35, _shop_item_h * 0.5);
	var _go_x = _w * 0.5 - _go_w * 0.5;
	var _go_y2 = _h - max(10, _h * 0.01);
	var _go_y1 = _go_y2 - _go_h;

	go_btn = { x1: _go_x, y1: _go_y1, x2: _go_x + _go_w, y2: _go_y2 };

	draw_set_colour(make_colour_rgb(50, 160, 50));
	draw_rectangle(_go_x, _go_y1, _go_x + _go_w, _go_y2, false);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_go_x + _go_w * 0.5, (_go_y1 + _go_y2) * 0.5, "FIGHT!", 0, _go_w, _hud_scale, _hud_scale, 0);

	// --- Sell zone ---
	var _sell_w = max(70, _w * 0.15);
	var _sell_h = _go_h;
	var _sell_x = _w - _pad - _sell_w;
	sell_btn = { x1: _sell_x, y1: _go_y1, x2: _sell_x + _sell_w, y2: _go_y2 };

	if (dragging) {
		draw_set_colour(make_colour_rgb(180, 50, 50));
	} else {
		draw_set_colour(make_colour_rgb(100, 40, 40));
	}
	draw_rectangle(_sell_x, _go_y1, _sell_x + _sell_w, _go_y2, false);
	draw_set_colour(c_white);
	draw_set_halign(fa_center);
	var _sell_text = "SELL";
	if (dragging && drag_unit_idx >= 0 && drag_unit_idx < array_length(board_units)) {
		var _su = board_units[drag_unit_idx];
		var _sell_price = max(1, floor(unit_stats[_su.unit_type][UNIT_COST] * _su.star * 0.5));
		_sell_text = "SELL +" + string(_sell_price) + "g";
	}
	draw_text_ext_transformed(_sell_x + _sell_w * 0.5, (_go_y1 + _go_y2) * 0.5, _sell_text, 0, _sell_w, _name_scale, _name_scale, 0);
}

// ============================================================
// BATTLE PHASE overlay (State 2)
// ============================================================
if (game_state == 2) {
	// "BATTLE" text at bottom
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(make_colour_rgb(255, 80, 80));
	var _battle_scale = max(1.5, _h * 0.002);
	var _pulse = 1.0 + sin(battle_tick * 0.08) * 0.05;
	draw_text_ext_transformed(_w * 0.5, _h - max(30, _h * 0.04), "BATTLE", 0, _w, _battle_scale * _pulse, _battle_scale * _pulse, 0);
}

// ============================================================
// ROUND RESULT (State 3)
// ============================================================
if (game_state == 3) {
	// Dim overlay
	draw_set_alpha(0.6);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false);
	draw_set_alpha(1.0);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _result_scale = max(2.0, _h * 0.004);
	if (round_won) {
		draw_set_colour(make_colour_rgb(50, 255, 50));
		draw_text_ext_transformed(_w * 0.5, _h * 0.4, "VICTORY!", 0, _w, _result_scale, _result_scale, 0);
	} else {
		draw_set_colour(make_colour_rgb(255, 50, 50));
		draw_text_ext_transformed(_w * 0.5, _h * 0.4, "DEFEAT!", 0, _w, _result_scale, _result_scale, 0);
	}

	draw_set_colour(c_white);
	var _info_scale = max(1.2, _h * 0.002);
	draw_text_ext_transformed(_w * 0.5, _h * 0.55, "Tap to continue", 0, _w, _info_scale, _info_scale, 0);

	// Score
	draw_set_colour(make_colour_rgb(255, 215, 0));
	draw_text_ext_transformed(_w * 0.5, _h * 0.65, "Score: " + string(points), 0, _w, _info_scale, _info_scale, 0);
}

// ============================================================
// GAME OVER (State 4)
// ============================================================
if (game_state == 4) {
	// Dim overlay
	draw_set_alpha(0.8);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false);
	draw_set_alpha(1.0);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);

	var _go_scale = max(2.5, _h * 0.005);
	draw_set_colour(make_colour_rgb(255, 50, 50));
	draw_text_ext_transformed(_w * 0.5, _h * 0.3, "GAME OVER", 0, _w, _go_scale, _go_scale, 0);

	var _info_scale2 = max(1.2, _h * 0.002);
	draw_set_colour(c_white);
	draw_text_ext_transformed(_w * 0.5, _h * 0.45, "Rounds Survived: " + string(current_round - 1), 0, _w, _info_scale2, _info_scale2, 0);
	draw_text_ext_transformed(_w * 0.5, _h * 0.52, "Enemies Defeated: " + string(total_enemies_killed), 0, _w, _info_scale2, _info_scale2, 0);

	draw_set_colour(make_colour_rgb(255, 215, 0));
	draw_text_ext_transformed(_w * 0.5, _h * 0.62, "Final Score: " + string(points), 0, _w, _info_scale2 * 1.3, _info_scale2 * 1.3, 0);

	draw_set_colour(make_colour_rgb(150, 150, 170));
	draw_text_ext_transformed(_w * 0.5, _h * 0.75, "Tap to play again", 0, _w, _info_scale2, _info_scale2, 0);
}

// Reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1.0);
