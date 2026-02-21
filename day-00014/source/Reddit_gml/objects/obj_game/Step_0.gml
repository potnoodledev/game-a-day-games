
// === SCREEN EFFECTS ===
if (shake_timer > 0) {
    shake_timer -= 1;
    shake_x = random_range(-shake_intensity, shake_intensity) * (shake_timer / 10);
    shake_y = random_range(-shake_intensity, shake_intensity) * (shake_timer / 10);
}
else {
    shake_x = 0;
    shake_y = 0;
}

// === POPUPS ===
var _pi = array_length(popups) - 1;
while (_pi >= 0) {
    popups[_pi].timer -= 1;
    popups[_pi].y -= 1.2;
    if (popups[_pi].timer <= 0) {
        array_delete(popups, _pi, 1);
    }
    _pi -= 1;
}

// === FLOATING COMMENTS ===
var _ci = array_length(floating_comments) - 1;
while (_ci >= 0) {
    floating_comments[_ci].timer -= 1;
    floating_comments[_ci].alpha = floating_comments[_ci].timer / 120;
    if (floating_comments[_ci].timer <= 0) {
        array_delete(floating_comments, _ci, 1);
    }
    _ci -= 1;
}

// === NEW SUB ANNOUNCEMENT ===
if (new_sub_timer > 0) {
    new_sub_timer -= 1;
}

// === STATE 0: LOADING ===
if (game_state == 0) {
    if (state_loaded) {
        // Start first round
        game_state = 1;
        // Pick a random subreddit
        current_sub = irandom(num_subs_unlocked - 1);
        // Pick 4 random post types (no duplicates)
        var _all_types = [0, 1, 2, 3, 4, 5, 6, 7];
        array_sort(_all_types, function(_a, _b) { return irandom(2) - 1; });
        choice_options[0] = _all_types[0];
        choice_options[1] = _all_types[1];
        choice_options[2] = _all_types[2];
        choice_options[3] = _all_types[3];
        selected_choice = -1;

        // Timer starts after 10 posts
        if (posts_made >= 10) {
            choice_timer_max = max(300, 600 - posts_made * 10);
            choice_timer = choice_timer_max;
        }
        else {
            choice_timer = 0;
            choice_timer_max = 0;
        }
    }
}

// === STATE 1: CHOOSING ===
if (game_state == 1) {
    // Choice countdown timer
    if (choice_timer > 0) {
        choice_timer -= 1;
        if (choice_timer <= 0) {
            // Time's up — pick random
            selected_choice = choice_options[irandom(3)];
            game_state = 2;
            // Set up reaction
            match_score = sub_prefs[current_sub][selected_choice];
            // Add variance to vote target
            var _base_votes = 0;
            if (match_score == 1) _base_votes = irandom_range(5, 30);
            if (match_score == 2) _base_votes = irandom_range(20, 80);
            if (match_score == 3) _base_votes = irandom_range(60, 200);
            if (match_score == 4) _base_votes = irandom_range(150, 500);
            if (match_score == 5) _base_votes = irandom_range(400, 1200);
            vote_target = _base_votes;
            comment_target = floor(vote_target * random_range(0.05, 0.15));
            vote_count = 0;
            comment_count = 0;
            react_timer = react_timer_max;
            vote_arrows = [];
            floating_comments = [];
            award_type = -1;
            award_timer = 0;

            // Generate title
            var _titles = title_lists[selected_choice];
            current_title = _titles[irandom(array_length(_titles) - 1)];

            // Determine award
            if (match_score >= 5) {
                award_type = irandom(2);
            }
            else if (match_score >= 4 && irandom(2) == 0) {
                award_type = 0;
            }

            // Calculate karma
            karma_earned = vote_target * match_score;
            if (streak >= 3) karma_earned = floor(karma_earned * 1.5);
        }
    }

    // Touch input
    if (device_mouse_check_button_pressed(0, mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);

        // Check choice buttons
        var _bi = 0;
        while (_bi < array_length(choice_btns)) {
            var _btn = choice_btns[_bi];
            if (_mx >= _btn.x1 && _mx <= _btn.x2 && _my >= _btn.y1 && _my <= _btn.y2) {
                selected_choice = _btn.type_idx;
            }
            _bi += 1;
        }

        // Check POST IT button
        if (selected_choice >= 0) {
            if (_mx >= post_btn.x1 && _mx <= post_btn.x2 && _my >= post_btn.y1 && _my <= post_btn.y2) {
                // Start reaction phase
                game_state = 2;
                match_score = sub_prefs[current_sub][selected_choice];

                var _base_votes2 = 0;
                if (match_score == 1) _base_votes2 = irandom_range(5, 30);
                if (match_score == 2) _base_votes2 = irandom_range(20, 80);
                if (match_score == 3) _base_votes2 = irandom_range(60, 200);
                if (match_score == 4) _base_votes2 = irandom_range(150, 500);
                if (match_score == 5) _base_votes2 = irandom_range(400, 1200);
                vote_target = _base_votes2;
                comment_target = floor(vote_target * random_range(0.05, 0.15));
                vote_count = 0;
                comment_count = 0;
                react_timer = react_timer_max;
                vote_arrows = [];
                floating_comments = [];
                award_type = -1;
                award_timer = 0;

                var _titles2 = title_lists[selected_choice];
                current_title = _titles2[irandom(array_length(_titles2) - 1)];

                if (match_score >= 5) {
                    award_type = irandom(2);
                }
                else if (match_score >= 4 && irandom(2) == 0) {
                    award_type = 0;
                }

                karma_earned = vote_target * match_score;
                if (streak >= 3) karma_earned = floor(karma_earned * 1.5);
            }
        }
    }
}

// === STATE 2: REACTING ===
if (game_state == 2) {
    react_timer -= 1;
    var _progress = 1.0 - (react_timer / react_timer_max);

    // Stream in votes
    var _target_votes_now = floor(vote_target * _progress);
    if (vote_count < _target_votes_now) {
        vote_count = _target_votes_now;
    }

    // Stream in comments
    var _target_comments_now = floor(comment_target * _progress);
    if (comment_count < _target_comments_now) {
        comment_count = _target_comments_now;
    }

    // Spawn floating vote arrows
    if (irandom(3) == 0 && react_timer > 10) {
        var _is_up = (match_score >= 3) || (irandom(4) < match_score);
        var _ax = post_btn.x1 + random(post_btn.x2 - post_btn.x1);
        var _ay = post_card_y + post_card_h * 0.5 + random_range(-30, 30);
        array_push(vote_arrows, {
            x: _ax,
            y: _ay,
            vy: _is_up ? -2.5 : 2.5,
            alpha: 1.0,
            is_up: _is_up
        });
    }

    // Spawn floating comments
    if (irandom(20) == 0 && react_timer > 30) {
        var _comment_list = (match_score >= 3) ? good_comments : bad_comments;
        var _ct = _comment_list[irandom(array_length(_comment_list) - 1)];
        array_push(floating_comments, {
            x: random_range(window_width * 0.1, window_width * 0.9),
            y: post_card_y + post_card_h + random_range(10, 50),
            text: _ct,
            alpha: 1.0,
            timer: 120
        });
    }

    // Update vote arrows
    var _vi = array_length(vote_arrows) - 1;
    while (_vi >= 0) {
        vote_arrows[_vi].y += vote_arrows[_vi].vy;
        vote_arrows[_vi].alpha -= 0.02;
        if (vote_arrows[_vi].alpha <= 0) {
            array_delete(vote_arrows, _vi, 1);
        }
        _vi -= 1;
    }

    // Award appears at 70% through
    if (_progress > 0.7 && award_type >= 0 && award_timer == 0) {
        award_timer = 1;
        shake_timer = 15;
        shake_intensity = 6;
    }

    // Shake on viral posts
    if (match_score >= 4 && react_timer == 90) {
        shake_timer = 20;
        shake_intensity = 4;
    }

    // End reaction
    if (react_timer <= 0) {
        game_state = 3;
        results_timer = 0;
        results_tap_ready = false;

        // Apply results
        points += karma_earned;
        posts_made += 1;

        // Reputation change
        if (match_score >= 4) {
            reputation = min(5.0, reputation + 0.5);
            streak += 1;
            if (streak > max_streak) max_streak = streak;
        }
        else if (match_score == 3) {
            // neutral
            streak = 0;
        }
        else {
            reputation -= 1.0;
            streak = 0;
            shake_timer = 15;
            shake_intensity = 8;
        }

        // Best score
        if (points > best_score) {
            best_score = points;
        }

        // Check game over
        if (reputation <= 0) {
            game_state = 4;
            final_score = points;
            final_posts = posts_made;
            final_streak = max_streak;
            game_over_tap_delay = 60;
            score_submitted = false;
        }

        // Unlock new sub every 5 posts
        if (posts_made > 0 && (posts_made mod 5) == 0 && num_subs_unlocked < array_length(sub_names)) {
            num_subs_unlocked += 1;
            new_sub_timer = 120;
            new_sub_name = sub_names[num_subs_unlocked - 1];
        }
    }
}

// === STATE 3: RESULTS ===
if (game_state == 3) {
    results_timer += 1;
    if (results_timer >= 40) {
        results_tap_ready = true;
    }

    if (results_tap_ready && device_mouse_check_button_pressed(0, mb_left)) {
        // Start next round
        game_state = 1;
        current_sub = irandom(num_subs_unlocked - 1);

        var _all_types2 = [0, 1, 2, 3, 4, 5, 6, 7];
        array_sort(_all_types2, function(_a2, _b2) { return irandom(2) - 1; });
        choice_options[0] = _all_types2[0];
        choice_options[1] = _all_types2[1];
        choice_options[2] = _all_types2[2];
        choice_options[3] = _all_types2[3];
        selected_choice = -1;

        if (posts_made >= 10) {
            choice_timer_max = max(300, 600 - posts_made * 10);
            choice_timer = choice_timer_max;
        }
        else {
            choice_timer = 0;
            choice_timer_max = 0;
        }

        day_num += 1;
    }
}

// === STATE 4: GAME OVER ===
if (game_state == 4) {
    if (game_over_tap_delay > 0) {
        game_over_tap_delay -= 1;
    }

    if (!score_submitted) {
        score_submitted = true;
        api_submit_score(points, undefined);
        api_save_state(0, { points: 0, reputation: 3.0, posts_made: 0, day_num: 1, num_subs_unlocked: 3, streak: 0, best_score: best_score }, undefined);
    }

    if (game_over_tap_delay <= 0 && device_mouse_check_button_pressed(0, mb_left)) {
        // Restart
        points = 0;
        posts_made = 0;
        streak = 0;
        max_streak = 0;
        reputation = 3.0;
        day_num = 1;
        num_subs_unlocked = 3;
        game_state = 1;

        current_sub = irandom(num_subs_unlocked - 1);
        var _all_types3 = [0, 1, 2, 3, 4, 5, 6, 7];
        array_sort(_all_types3, function(_a3, _b3) { return irandom(2) - 1; });
        choice_options[0] = _all_types3[0];
        choice_options[1] = _all_types3[1];
        choice_options[2] = _all_types3[2];
        choice_options[3] = _all_types3[3];
        selected_choice = -1;
        choice_timer = 0;
        choice_timer_max = 0;
    }
}
