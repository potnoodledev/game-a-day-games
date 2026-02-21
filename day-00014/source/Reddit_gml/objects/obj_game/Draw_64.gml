
var _w = window_width;
var _h = window_height;
if (_w == 0 || _h == 0) exit;

var _pad = max(8, _w * 0.03);
var _sx = shake_x;
var _sy = shake_y;

// === BACKGROUND (Reddit dark mode) ===
draw_set_alpha(1);
draw_set_color($1a1a1a);
draw_rectangle(0, 0, _w, _h, false);

// === HUD BAR ===
draw_set_color($272729);
draw_rectangle(0, 0, _w, hud_h, false);
// Bottom border
draw_set_color($343536);
draw_rectangle(0, hud_h - 1, _w, hud_h, false);

draw_set_font(fnt_default);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var _hud_scale = max(1.2, _h * 0.0018);

// Upvote icon + karma
draw_set_color($ff4500); // Reddit orange
var _karma_x = _pad + _sx;
var _karma_y = hud_h * 0.5 + _sy;
// Draw upvote triangle
var _tri_s = max(5, _h * 0.008);
draw_triangle(_karma_x + _tri_s, _karma_y - _tri_s, _karma_x, _karma_y + _tri_s * 0.5, _karma_x + _tri_s * 2, _karma_y + _tri_s * 0.5, false);
draw_set_color($d7dadc);
draw_text_ext_transformed(_karma_x + _tri_s * 2.5, _karma_y, string(points), 0, _w, _hud_scale, _hud_scale, 0);

// Posts counter
draw_set_color($818384);
draw_set_halign(fa_center);
var _small_scale = _hud_scale * 0.75;
draw_text_ext_transformed(_w * 0.5 + _sx, _karma_y, "Post #" + string(posts_made + 1), 0, _w, _small_scale, _small_scale, 0);

// Reputation stars
draw_set_halign(fa_right);
var _star_x = _w - _pad + _sx;
var _star_y = hud_h * 0.5 + _sy;
var _star_r = max(6, _h * 0.009);
var _si = 4;
while (_si >= 0) {
    var _cx = _star_x - (4 - _si) * (_star_r * 2.8);
    var _cy = _star_y;
    // Draw 5-pointed star shape using triangles
    if (_si < floor(reputation)) {
        draw_set_color($ff4500); // full star - reddit orange
    }
    else if (_si < reputation) {
        draw_set_color($7a3a1a); // half star
    }
    else {
        draw_set_color($343536); // empty
    }
    // Star: 5 outer points
    var _inner = _star_r * 0.45;
    var _pi2 = 0;
    while (_pi2 < 5) {
        var _a1 = ((_pi2 * 72) - 90) * pi / 180;
        var _a2 = (((_pi2 + 1) * 72) - 90) * pi / 180;
        var _am = (((_pi2 * 72) + 36) - 90) * pi / 180;
        draw_triangle(
            _cx + cos(_a1) * _star_r, _cy + sin(_a1) * _star_r,
            _cx + cos(_am) * _inner, _cy + sin(_am) * _inner,
            _cx + cos(_a2) * _star_r, _cy + sin(_a2) * _star_r,
            false
        );
        // Inner triangle to fill center
        draw_triangle(
            _cx, _cy,
            _cx + cos(_am) * _inner, _cy + sin(_am) * _inner,
            _cx + cos(((_pi2 * 72 + 72 + 36) - 90) * pi / 180) * _inner, _cy + sin(((_pi2 * 72 + 72 + 36) - 90) * pi / 180) * _inner,
            false
        );
        _pi2 += 1;
    }
    _si -= 1;
}

// === LOADING STATE ===
if (game_state == 0) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color($d7dadc);
    var _load_scale = max(1.5, _h * 0.0025);
    draw_text_ext_transformed(_w * 0.5, _h * 0.5, "Loading...", 0, _w, _load_scale, _load_scale, 0);
    exit;
}

// === SUBREDDIT HEADER ===
var _sub_y = sub_area_y + _sy;
var _sub_h = max(40, _h * 0.06);
var _sub_col = sub_colors[current_sub];

// Subreddit bar
draw_set_color($1a1a1b);
draw_roundrect(_pad * 0.5 + _sx, _sub_y, _w - _pad * 0.5 + _sx, _sub_y + _sub_h, false);

// Subreddit icon circle
var _icon_r = _sub_h * 0.35;
var _icon_x = _pad * 2 + _icon_r + _sx;
var _icon_y = _sub_y + _sub_h * 0.5;
draw_set_color(_sub_col);
draw_circle(_icon_x, _icon_y, _icon_r, false);
// First letter of sub (after "r/")
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
var _icon_scale = max(0.9, _h * 0.0014);
var _sub_letter = string_char_at(sub_names[current_sub], 3);
draw_text_ext_transformed(_icon_x, _icon_y, _sub_letter, 0, 50, _icon_scale, _icon_scale, 0);

// Subreddit name
draw_set_halign(fa_left);
draw_set_color($d7dadc);
var _sub_scale = max(1.1, _h * 0.0017);
draw_text_ext_transformed(_icon_x + _icon_r + _pad * 0.5, _icon_y, sub_names[current_sub], 0, _w, _sub_scale, _sub_scale, 0);

// === POST CARD (states 2 & 3) ===
if (game_state >= 2 && game_state <= 3) {
    var _card_x1 = _pad * 0.5 + _sx;
    var _card_y1 = post_card_y + _sy;
    var _card_x2 = _w - _pad * 0.5 + _sx;
    var _card_y2 = post_card_y + post_card_h + _sy;

    // Card background
    draw_set_color($1a1a1b);
    draw_roundrect(_card_x1, _card_y1, _card_x2, _card_y2, false);

    // Left vote column
    var _vote_col_w = max(30, _w * 0.1);
    var _vote_cx = _card_x1 + _vote_col_w * 0.5;
    var _vote_cy = _card_y1 + post_card_h * 0.5;

    // Upvote triangle
    var _vtri = max(6, _h * 0.01);
    var _up_col = (match_score >= 3) ? $ff4500 : $818384;
    draw_set_color(_up_col);
    draw_triangle(
        _vote_cx, _vote_cy - _vtri * 2.5,
        _vote_cx - _vtri, _vote_cy - _vtri,
        _vote_cx + _vtri, _vote_cy - _vtri,
        false
    );

    // Vote count
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color((match_score >= 3) ? $ff4500 : $8888ff);
    var _vote_scale = max(1.0, _h * 0.0015);
    draw_text_ext_transformed(_vote_cx, _vote_cy, string(vote_count), 0, _vote_col_w, _vote_scale, _vote_scale, 0);

    // Downvote triangle
    var _dn_col = (match_score < 3) ? $7193ff : $818384;
    draw_set_color(_dn_col);
    draw_triangle(
        _vote_cx, _vote_cy + _vtri * 2.5,
        _vote_cx - _vtri, _vote_cy + _vtri,
        _vote_cx + _vtri, _vote_cy + _vtri,
        false
    );

    // Post content area
    var _content_x = _card_x1 + _vote_col_w + _pad * 0.5;

    // Posted by line
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color($818384);
    var _meta_scale = max(0.6, _h * 0.001);
    draw_text_ext_transformed(_content_x, _card_y1 + _pad * 0.5, "Posted by u/" + username + " - just now", 0, _w * 0.7, _meta_scale, _meta_scale, 0);

    // Title
    draw_set_color($d7dadc);
    var _title_scale = max(1.0, _h * 0.0015);
    draw_text_ext_transformed(_content_x, _card_y1 + _pad * 0.5 + _meta_scale * 16, current_title, _title_scale * 16, _w * 0.7, _title_scale, _title_scale, 0);

    // Bottom bar: comments + award
    var _bar_y = _card_y2 - _pad * 1.2;
    draw_set_valign(fa_middle);
    draw_set_color($818384);
    var _bar_scale = max(0.7, _h * 0.0011);
    draw_text_ext_transformed(_content_x, _bar_y, string(comment_count) + " comments", 0, _w, _bar_scale, _bar_scale, 0);

    // Award badge
    if (award_type >= 0 && award_timer > 0) {
        var _award_name = "Silver";
        var _award_col3 = $aaaaaa;
        if (award_type == 1) { _award_name = "Gold"; _award_col3 = $00d4ff; }
        if (award_type == 2) { _award_name = "Platinum"; _award_col3 = $e5b800; }

        var _badge_x = _card_x2 - _pad * 2;
        draw_set_color(_award_col3);
        var _badge_r = max(8, _h * 0.012);
        draw_circle(_badge_x, _bar_y, _badge_r, false);
        draw_set_color($1a1a1b);
        draw_set_halign(fa_center);
        var _badge_txt = "S";
        if (award_type == 1) _badge_txt = "G";
        if (award_type == 2) _badge_txt = "P";
        draw_text_ext_transformed(_badge_x, _bar_y, _badge_txt, 0, 30, _bar_scale, _bar_scale, 0);
    }
}

// === FLOATING VOTE ARROWS ===
var _vai = 0;
while (_vai < array_length(vote_arrows)) {
    var _va = vote_arrows[_vai];
    draw_set_alpha(_va.alpha);
    var _tri_sz = max(4, _h * 0.007);
    if (_va.is_up) {
        draw_set_color($ff4500);
        draw_triangle(
            _va.x + _sx, _va.y + _sy - _tri_sz,
            _va.x - _tri_sz * 0.7 + _sx, _va.y + _sy + _tri_sz * 0.5,
            _va.x + _tri_sz * 0.7 + _sx, _va.y + _sy + _tri_sz * 0.5,
            false
        );
    }
    else {
        draw_set_color($7193ff);
        draw_triangle(
            _va.x + _sx, _va.y + _sy + _tri_sz,
            _va.x - _tri_sz * 0.7 + _sx, _va.y + _sy - _tri_sz * 0.5,
            _va.x + _tri_sz * 0.7 + _sx, _va.y + _sy - _tri_sz * 0.5,
            false
        );
    }
    _vai += 1;
}
draw_set_alpha(1);

// === FLOATING COMMENTS ===
var _fci = 0;
while (_fci < array_length(floating_comments)) {
    var _fc = floating_comments[_fci];
    draw_set_alpha(_fc.alpha * 0.85);
    // Comment bubble background
    draw_set_color($2d2d2d);
    var _fc_scale = max(0.65, _h * 0.001);
    var _fc_tw = string_length(_fc.text) * _fc_scale * 6;
    var _fc_th = _fc_scale * 14;
    draw_roundrect(_fc.x - _fc_tw * 0.5 - 4 + _sx, _fc.y - _fc_th * 0.5 - 2 + _sy, _fc.x + _fc_tw * 0.5 + 4 + _sx, _fc.y + _fc_th * 0.5 + 2 + _sy, false);
    draw_set_color((match_score >= 3) ? $d7dadc : $ff6666);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_ext_transformed(_fc.x + _sx, _fc.y + _sy, _fc.text, 0, _w * 0.6, _fc_scale, _fc_scale, 0);
    _fci += 1;
}
draw_set_alpha(1);

// === CHOICE BUTTONS (state 1) ===
if (game_state == 1) {
    // Timer bar
    if (choice_timer > 0 && choice_timer_max > 0) {
        var _timer_frac = choice_timer / choice_timer_max;
        var _timer_y = post_card_y - 6 + _sy;
        draw_set_color($343536);
        draw_rectangle(_pad, _timer_y, _w - _pad, _timer_y + 4, false);
        if (_timer_frac > 0.5) draw_set_color($46d160);
        else if (_timer_frac > 0.25) draw_set_color($ffcc00);
        else draw_set_color($ff4500);
        draw_rectangle(_pad, _timer_y, _pad + (_w - _pad * 2) * _timer_frac, _timer_y + 4, false);
    }

    // "Choose your post:" label
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_set_color($818384);
    var _label_scale = max(0.8, _h * 0.0012);
    draw_text_ext_transformed(_pad + _sx, choices_y - _pad * 0.3 - 20 + _sy, "Choose your post type:", 0, _w, _label_scale, _label_scale, 0);

    var _bi = 0;
    while (_bi < array_length(choice_btns)) {
        var _btn = choice_btns[_bi];
        var _type = _btn.type_idx;
        var _is_selected = (selected_choice == _type);

        // Button background
        if (_is_selected) {
            draw_set_color($ff4500);
        }
        else {
            draw_set_color($272729);
        }
        draw_roundrect(_btn.x1 + _sx, _btn.y1 + _sy, _btn.x2 + _sx, _btn.y2 + _sy, false);

        // Border
        draw_set_color(_is_selected ? $ff6633 : $343536);
        draw_roundrect(_btn.x1 + _sx, _btn.y1 + _sy, _btn.x2 + _sx, _btn.y2 + _sy, true);

        // Emoji badge
        var _badge_w = max(28, _w * 0.08);
        draw_set_color(_is_selected ? $cc3300 : $343536);
        draw_roundrect(_btn.x1 + 2 + _sx, _btn.y1 + 2 + _sy, _btn.x1 + _badge_w + _sx, _btn.y2 - 2 + _sy, false);

        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        var _emoji_scale = max(0.8, _h * 0.0012);
        draw_text_ext_transformed(_btn.x1 + _badge_w * 0.5 + _sx, (_btn.y1 + _btn.y2) * 0.5 + _sy, post_type_emojis[_type], 0, _badge_w, _emoji_scale, _emoji_scale, 0);

        // Name
        draw_set_halign(fa_left);
        draw_set_color(_is_selected ? c_white : $d7dadc);
        var _btn_scale = max(0.9, _h * 0.0013);
        draw_text_ext_transformed(_btn.x1 + _badge_w + _pad * 0.5 + _sx, (_btn.y1 + _btn.y2) * 0.5 + _sy, post_type_names[_type], 0, _w, _btn_scale, _btn_scale, 0);

        _bi += 1;
    }

    // POST IT button
    var _can_post = (selected_choice >= 0);
    if (_can_post) {
        draw_set_color($ff4500);
    }
    else {
        draw_set_color($343536);
    }
    draw_roundrect(post_btn.x1 + _sx, post_btn.y1 + _sy, post_btn.x2 + _sx, post_btn.y2 + _sy, false);

    // Button glow when active
    if (_can_post) {
        draw_set_color($ff6633);
        draw_roundrect(post_btn.x1 + _sx, post_btn.y1 + _sy, post_btn.x2 + _sx, post_btn.y2 + _sy, true);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_can_post ? c_white : $818384);
    var _post_scale = max(1.3, _h * 0.002);
    draw_text_ext_transformed(_w * 0.5 + _sx, (post_btn.y1 + post_btn.y2) * 0.5 + _sy, "POST IT!", 0, _w, _post_scale, _post_scale, 0);
}

// === REACTION STATUS (state 2) ===
if (game_state == 2) {
    var _react_y = choices_y + _sy;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Match quality bar
    var _bar_w = _w * 0.6;
    var _bar_h = max(6, _h * 0.01);
    var _bar_x = (_w - _bar_w) * 0.5 + _sx;
    var _bar_y2 = _react_y + 10;
    draw_set_color($343536);
    draw_roundrect(_bar_x, _bar_y2, _bar_x + _bar_w, _bar_y2 + _bar_h, false);
    var _fill = (1.0 - react_timer / react_timer_max);
    var _fill_col = $818384;
    if (match_score >= 5) _fill_col = $ff4500;
    else if (match_score >= 4) _fill_col = $46d160;
    else if (match_score == 3) _fill_col = $ffcc00;
    else _fill_col = $7193ff;
    draw_set_color(_fill_col);
    draw_roundrect(_bar_x, _bar_y2, _bar_x + _bar_w * _fill, _bar_y2 + _bar_h, false);

    // Status text
    var _react_text = "";
    if (match_score >= 5) _react_text = "GOING VIRAL!!";
    else if (match_score >= 4) _react_text = "Trending!";
    else if (match_score == 3) _react_text = "Decent reception";
    else if (match_score == 2) _react_text = "Not great...";
    else _react_text = "Getting buried";

    draw_set_color(_fill_col);
    var _react_scale = max(1.3, _h * 0.002);
    var _pulse = 1.0 + sin(react_timer * 0.15) * 0.05;
    draw_text_ext_transformed(_w * 0.5 + _sx, _react_y + 40, _react_text, 0, _w, _react_scale * _pulse, _react_scale * _pulse, 0);

    // Karma counter
    draw_set_color($ff4500);
    var _karma_scale = max(1.6, _h * 0.0025);
    draw_text_ext_transformed(_w * 0.5 + _sx, _react_y + 80, "+" + string(karma_earned), 0, _w, _karma_scale, _karma_scale, 0);
    draw_set_color($818384);
    var _karma_label = max(0.8, _h * 0.0012);
    draw_text_ext_transformed(_w * 0.5 + _sx, _react_y + 105, "karma", 0, _w, _karma_label, _karma_label, 0);

    // Streak indicator
    if (streak >= 2) {
        draw_set_color($ff4500);
        var _streak_scale = max(0.9, _h * 0.0014);
        var _fire_pulse = 1.0 + sin(current_time * 0.008) * 0.15;
        draw_text_ext_transformed(_w * 0.5 + _sx, _react_y + 135, "STREAK x" + string(streak) + "!", 0, _w, _streak_scale * _fire_pulse, _streak_scale * _fire_pulse, 0);
    }
}

// === RESULTS OVERLAY (state 3) ===
if (game_state == 3) {
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Result card
    var _rc_w = _w * 0.85;
    var _rc_h = _h * 0.5;
    var _rc_x = (_w - _rc_w) * 0.5;
    var _rc_y = _h * 0.22;
    draw_set_color($1a1a1b);
    draw_roundrect(_rc_x, _rc_y, _rc_x + _rc_w, _rc_y + _rc_h, false);
    draw_set_color($343536);
    draw_roundrect(_rc_x, _rc_y, _rc_x + _rc_w, _rc_y + _rc_h, true);

    // Header
    var _result_text = "";
    var _result_col = c_white;
    if (match_score >= 5) { _result_text = "FRONT PAGE!"; _result_col = $ff4500; }
    else if (match_score >= 4) { _result_text = "Popular Post!"; _result_col = $46d160; }
    else if (match_score == 3) { _result_text = "It's OK"; _result_col = $818384; }
    else if (match_score == 2) { _result_text = "Didn't Land"; _result_col = $7193ff; }
    else { _result_text = "BURIED"; _result_col = $7193ff; }

    draw_set_color(_result_col);
    var _res_scale = max(1.8, _h * 0.003);
    draw_text_ext_transformed(_w * 0.5, _rc_y + _rc_h * 0.12, _result_text, 0, _w, _res_scale, _res_scale, 0);

    // Divider
    draw_set_color($343536);
    draw_rectangle(_rc_x + _pad * 2, _rc_y + _rc_h * 0.2, _rc_x + _rc_w - _pad * 2, _rc_y + _rc_h * 0.2 + 1, false);

    // Karma earned
    draw_set_color($ff4500);
    var _ke_scale = max(2.0, _h * 0.0032);
    draw_text_ext_transformed(_w * 0.5, _rc_y + _rc_h * 0.32, "+" + string(karma_earned), 0, _w, _ke_scale, _ke_scale, 0);
    draw_set_color($818384);
    var _kl_scale = max(0.8, _h * 0.0012);
    draw_text_ext_transformed(_w * 0.5, _rc_y + _rc_h * 0.42, "karma earned", 0, _w, _kl_scale, _kl_scale, 0);

    // Stats row
    var _stat_y = _rc_y + _rc_h * 0.55;
    var _stat_scale2 = max(0.9, _h * 0.0013);
    var _col_w = _rc_w / 3;

    // Upvotes
    draw_set_color($ff4500);
    draw_text_ext_transformed(_rc_x + _col_w * 0.5, _stat_y, string(vote_count), 0, _col_w, _stat_scale2 * 1.2, _stat_scale2 * 1.2, 0);
    draw_set_color($818384);
    draw_text_ext_transformed(_rc_x + _col_w * 0.5, _stat_y + _stat_scale2 * 18, "upvotes", 0, _col_w, _stat_scale2 * 0.8, _stat_scale2 * 0.8, 0);

    // Comments
    draw_set_color($d7dadc);
    draw_text_ext_transformed(_rc_x + _col_w * 1.5, _stat_y, string(comment_count), 0, _col_w, _stat_scale2 * 1.2, _stat_scale2 * 1.2, 0);
    draw_set_color($818384);
    draw_text_ext_transformed(_rc_x + _col_w * 1.5, _stat_y + _stat_scale2 * 18, "comments", 0, _col_w, _stat_scale2 * 0.8, _stat_scale2 * 0.8, 0);

    // Award
    if (award_type >= 0) {
        var _aw_name = "Silver";
        var _aw_col = $aaaaaa;
        if (award_type == 1) { _aw_name = "Gold"; _aw_col = $00d4ff; }
        if (award_type == 2) { _aw_name = "Platinum"; _aw_col = $e5b800; }
        draw_set_color(_aw_col);
        draw_text_ext_transformed(_rc_x + _col_w * 2.5, _stat_y, _aw_name, 0, _col_w, _stat_scale2 * 1.2, _stat_scale2 * 1.2, 0);
        draw_set_color($818384);
        draw_text_ext_transformed(_rc_x + _col_w * 2.5, _stat_y + _stat_scale2 * 18, "award", 0, _col_w, _stat_scale2 * 0.8, _stat_scale2 * 0.8, 0);
    }
    else {
        draw_set_color($343536);
        draw_text_ext_transformed(_rc_x + _col_w * 2.5, _stat_y, "-", 0, _col_w, _stat_scale2 * 1.2, _stat_scale2 * 1.2, 0);
        draw_set_color($818384);
        draw_text_ext_transformed(_rc_x + _col_w * 2.5, _stat_y + _stat_scale2 * 18, "award", 0, _col_w, _stat_scale2 * 0.8, _stat_scale2 * 0.8, 0);
    }

    // Reputation change
    var _rep_y = _rc_y + _rc_h * 0.78;
    if (match_score >= 4) {
        draw_set_color($46d160);
        draw_text_ext_transformed(_w * 0.5, _rep_y, "Reputation +0.5", 0, _w, _stat_scale2, _stat_scale2, 0);
    }
    else if (match_score <= 2) {
        draw_set_color($ff4444);
        draw_text_ext_transformed(_w * 0.5, _rep_y, "Reputation -1.0", 0, _w, _stat_scale2, _stat_scale2, 0);
    }
    else {
        draw_set_color($818384);
        draw_text_ext_transformed(_w * 0.5, _rep_y, "Reputation unchanged", 0, _w, _stat_scale2 * 0.9, _stat_scale2 * 0.9, 0);
    }

    // Tap to continue
    if (results_tap_ready) {
        var _blink = (results_timer mod 50) < 35;
        if (_blink) {
            draw_set_color($818384);
            var _tap_s = max(0.9, _h * 0.0013);
            draw_text_ext_transformed(_w * 0.5, _rc_y + _rc_h + _pad * 2, "Tap to continue", 0, _w, _tap_s, _tap_s, 0);
        }
    }
}

// === NEW SUB ANNOUNCEMENT ===
if (new_sub_timer > 0) {
    var _nsf = new_sub_timer / 120;
    draw_set_alpha(min(1, _nsf * 2));

    // Dark overlay
    draw_set_color(c_black);
    draw_set_alpha(0.6 * min(1, _nsf * 2));
    draw_rectangle(0, 0, _w, _h, false);

    // Announcement card
    draw_set_alpha(min(1, _nsf * 2));
    var _ann_h = _h * 0.18;
    var _ann_y = (_h - _ann_h) * 0.5;
    draw_set_color($ff4500);
    draw_roundrect(_pad * 2, _ann_y, _w - _pad * 2, _ann_y + _ann_h, false);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    var _ns_scale = max(1.0, _h * 0.0015);
    draw_text_ext_transformed(_w * 0.5, _ann_y + _ann_h * 0.35, "NEW SUBREDDIT UNLOCKED!", 0, _w, _ns_scale, _ns_scale, 0);
    var _ns_scale2 = max(1.5, _h * 0.0025);
    draw_text_ext_transformed(_w * 0.5, _ann_y + _ann_h * 0.65, new_sub_name, 0, _w, _ns_scale2, _ns_scale2, 0);
    draw_set_alpha(1);
}

// === POPUPS ===
var _ppi = 0;
while (_ppi < array_length(popups)) {
    var _pp = popups[_ppi];
    var _pp_alpha = _pp.timer / _pp.max_timer;
    draw_set_alpha(_pp_alpha);
    draw_set_color(_pp.color);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _pp_scale = max(1.0, _h * 0.0015);
    draw_text_ext_transformed(_pp.x + _sx, _pp.y + _sy, _pp.text, 0, _w, _pp_scale, _pp_scale, 0);
    _ppi += 1;
}
draw_set_alpha(1);

// === GAME OVER ===
if (game_state == 4) {
    draw_set_alpha(0.9);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _w, _h, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Suspended card
    var _go_w = _w * 0.85;
    var _go_h = _h * 0.55;
    var _go_x = (_w - _go_w) * 0.5;
    var _go_y = _h * 0.18;
    draw_set_color($1a1a1b);
    draw_roundrect(_go_x, _go_y, _go_x + _go_w, _go_y + _go_h, false);
    draw_set_color($ff4444);
    draw_roundrect(_go_x, _go_y, _go_x + _go_w, _go_y + _go_h, true);

    // Red ban icon (X in circle)
    var _ban_r = max(20, _h * 0.035);
    var _ban_cx = _w * 0.5;
    var _ban_cy = _go_y + _go_h * 0.13;
    draw_set_color($ff4444);
    draw_circle(_ban_cx, _ban_cy, _ban_r, true);
    draw_line_width(_ban_cx - _ban_r * 0.5, _ban_cy - _ban_r * 0.5, _ban_cx + _ban_r * 0.5, _ban_cy + _ban_r * 0.5, 2);
    draw_line_width(_ban_cx + _ban_r * 0.5, _ban_cy - _ban_r * 0.5, _ban_cx - _ban_r * 0.5, _ban_cy + _ban_r * 0.5, 2);

    // Header
    draw_set_color($ff4444);
    var _go_scale = max(1.6, _h * 0.0028);
    draw_text_ext_transformed(_w * 0.5, _go_y + _go_h * 0.25, "ACCOUNT SUSPENDED", 0, _w, _go_scale, _go_scale, 0);

    draw_set_color($818384);
    var _go_sub_s = max(0.8, _h * 0.0012);
    draw_text_ext_transformed(_w * 0.5, _go_y + _go_h * 0.33, "Your reputation dropped to zero", 0, _w, _go_sub_s, _go_sub_s, 0);

    // Divider
    draw_set_color($343536);
    draw_rectangle(_go_x + _pad * 2, _go_y + _go_h * 0.38, _go_x + _go_w - _pad * 2, _go_y + _go_h * 0.38 + 1, false);

    // Stats
    draw_set_color($d7dadc);
    var _go_stat = max(1.1, _h * 0.0017);
    draw_text_ext_transformed(_w * 0.5, _go_y + _go_h * 0.48, "Total Karma: " + string(final_score), 0, _w, _go_stat, _go_stat, 0);
    draw_text_ext_transformed(_w * 0.5, _go_y + _go_h * 0.57, "Posts Made: " + string(final_posts), 0, _w, _go_stat, _go_stat, 0);
    draw_text_ext_transformed(_w * 0.5, _go_y + _go_h * 0.66, "Best Streak: " + string(final_streak), 0, _w, _go_stat, _go_stat, 0);

    if (best_score > 0) {
        draw_set_color($ff4500);
        draw_text_ext_transformed(_w * 0.5, _go_y + _go_h * 0.77, "Personal Best: " + string(best_score), 0, _w, _go_stat, _go_stat, 0);
    }

    // Restart button
    if (game_over_tap_delay <= 0) {
        var _restart_y = _go_y + _go_h + _pad * 2;
        var _restart_h = max(40, _h * 0.06);
        draw_set_color($ff4500);
        draw_roundrect(_go_x + _pad, _restart_y, _go_x + _go_w - _pad, _restart_y + _restart_h, false);
        draw_set_color(c_white);
        var _restart_s = max(1.1, _h * 0.0017);
        draw_text_ext_transformed(_w * 0.5, _restart_y + _restart_h * 0.5, "Create New Account", 0, _w, _restart_s, _restart_s, 0);
    }
}
