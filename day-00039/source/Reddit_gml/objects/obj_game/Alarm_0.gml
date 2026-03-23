/// @description Periodic save

api_save_state(0, { points: points, words: words_found, best_word: best_word, combo: max_combo }, undefined);
alarm[0] = 300; // Save every 5 seconds
