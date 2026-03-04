// Auto-save every 2 seconds
if (points != prev_points) {
    prev_points = points;
    api_save_state(wave_num, { points: points, wave_num: wave_num }, undefined);
}
alarm[0] = 120;
