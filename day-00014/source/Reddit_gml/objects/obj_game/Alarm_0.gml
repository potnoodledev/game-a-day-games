
api_save_state(0, {
    points: points,
    reputation: reputation,
    posts_made: posts_made,
    day_num: day_num,
    num_subs_unlocked: num_subs_unlocked,
    streak: streak,
    best_score: best_score
}, function(_status, _ok, _result) {
    alarm[0] = 60 * 15;
});
