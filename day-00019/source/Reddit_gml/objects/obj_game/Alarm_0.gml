
// Periodic score submit (no state save — always fresh start)
if (points > 0) {
    api_submit_score(points, function(_status, _ok, _result) {});
}
alarm[0] = 600; // every 10 seconds
