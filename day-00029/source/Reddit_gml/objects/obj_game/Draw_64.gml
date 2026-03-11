
var _w = window_width;
var _h = window_height;
if (_w <= 0 || _h <= 0) exit;

// --- BACKGROUND (deep space) ---
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(2, 2, 8));
draw_rectangle(0, 0, _w, _h, false);

// --- NEBULAE ---
var _neb_len = array_length(nebulae);
var _ni = 0;
repeat (_neb_len) {
	var _nb = nebulae[_ni];
	var _nx = (_nb.nx / 1920) * _w;
	var _ny = (_nb.ny / 1080) * _h;
	var _nr = _nb.nradius * (_w / 1920);
	// Slow breathing
	var _breath = 1.0 + 0.15 * dsin(game_time * _nb.ndrift + _ni * 73);
	draw_set_colour(_nb.ncolor);
	// Multiple layers for soft cloud look
	draw_set_alpha(_nb.nalpha * 0.3);
	draw_circle(_nx, _ny, _nr * _breath * 1.3, false);
	draw_set_alpha(_nb.nalpha * 0.5);
	draw_circle(_nx, _ny, _nr * _breath, false);
	draw_set_alpha(_nb.nalpha);
	draw_circle(_nx, _ny, _nr * _breath * 0.6, false);
	_ni++;
}
draw_set_alpha(1);

// --- BG STARS ---
var _bg_len = array_length(bg_stars);
var _bgi = 0;
repeat (_bg_len) {
	var _bs = bg_stars[_bgi];
	_bs.btwinkle += _bs.bspeed;
	var _bsx = (_bs.bx / 1920) * _w;
	var _bsy = (_bs.by / 1080) * _h;
	draw_set_alpha(0.3 + 0.5 * abs(dsin(_bs.btwinkle)));
	draw_set_colour(c_white);
	draw_circle(_bsx, _bsy, _bs.bsize, false);
	_bgi++;
}
draw_set_alpha(1);

// --- DUST ---
var _dust_len = array_length(dust);
var _di = 0;
repeat (_dust_len) {
	var _d = dust[_di];
	draw_set_alpha(_d.alpha * 0.5);
	draw_set_colour(make_colour_rgb(180, 180, 255));
	draw_circle(_d.x, _d.y, _d.size + 1.5, false);
	draw_set_alpha(_d.alpha * 0.9);
	draw_set_colour(c_white);
	draw_circle(_d.x, _d.y, _d.size, false);
	_di++;
}

// --- ROGUES ---
var _rogue_len = array_length(rogues);
var _roi = 0;
repeat (_rogue_len) {
	var _rp = rogues[_roi];
	var _rlife = _rp.life / _rp.max_life;

	var _tlen = array_length(_rp.trail);
	if (_tlen >= 4) {
		var _ti = 0;
		repeat (_tlen / 2 - 1) {
			draw_set_alpha(0.06 * (_ti / (_tlen / 2)) * _rlife);
			draw_set_colour(_rp.color);
			draw_line_width(_rp.trail[_ti * 2], _rp.trail[_ti * 2 + 1],
				_rp.trail[(_ti + 1) * 2], _rp.trail[(_ti + 1) * 2 + 1], 1.5);
			_ti++;
		}
	}

	draw_set_alpha(0.03 * _rlife);
	draw_set_colour(_rp.color);
	draw_circle(_rp.px, _rp.py, _rp.pull_radius, true);

	draw_set_alpha(0.2 * _rlife);
	draw_circle(_rp.px, _rp.py, _rp.psize + 3, false);

	draw_set_alpha(_rlife);
	draw_set_colour(_rp.color);
	draw_circle(_rp.px, _rp.py, _rp.psize, false);

	draw_set_alpha(0.3 * _rlife);
	draw_set_colour(c_white);
	draw_circle(_rp.px - _rp.psize * 0.3, _rp.py - _rp.psize * 0.3, _rp.psize * 0.35, false);
	_roi++;
}

// --- STARS ---
var _star_len = array_length(stars);
var _si = 0;
repeat (_star_len) {
	var _s = stars[_si];

	if (_s.supernova) {
		var _na = 1.0 - (_s.nova_timer / 45);
		draw_set_alpha(_na * 0.5);
		draw_set_colour(c_yellow);
		draw_circle(_s.x, _s.y, _s.nova_radius, true);
		draw_set_alpha(_na * 0.2);
		draw_set_colour(c_orange);
		draw_circle(_s.x, _s.y, _s.nova_radius * 0.7, false);
		draw_set_alpha(_na);
		draw_set_colour(c_white);
		var _cr = _s.radius * max(0, 1.0 - _s.nova_timer / 45);
		if (_cr > 0) draw_circle(_s.x, _s.y, _cr, false);
	} else {
		var _life_ratio = _s.life / _s.max_life;

		// Planet trails
		var _plen = array_length(_s.planets);
		var _pi = 0;
		repeat (_plen) {
			var _p = _s.planets[_pi];
			var _tlen = array_length(_p.trail);
			if (_tlen >= 4) {
				var _ti = 0;
				repeat (_tlen / 2 - 1) {
					draw_set_alpha(0.1 * (_ti / (_tlen / 2)));
					draw_set_colour(_p.color);
					draw_line_width(_p.trail[_ti * 2], _p.trail[_ti * 2 + 1],
						_p.trail[(_ti + 1) * 2], _p.trail[(_ti + 1) * 2 + 1], 1.5);
					_ti++;
				}
			}
			_pi++;
		}

		// Pull radius
		if (_life_ratio > 0.2) {
			draw_set_alpha(0.04);
			draw_set_colour(make_colour_rgb(100, 100, 255));
			draw_circle(_s.x, _s.y, star_pull_radius, true);
		}

		// Star glow
		var _glow_col = merge_colour(make_colour_rgb(150, 150, 255), make_colour_rgb(255, 200, 50), _s.color_lerp);
		draw_set_alpha(0.2 + 0.1 * dsin(game_time * 3 + _si * 90));
		draw_set_colour(_glow_col);
		draw_circle(_s.x, _s.y, _s.radius + 8, false);

		var _core_col = merge_colour(c_white, make_colour_rgb(255, 220, 100), _s.color_lerp);
		draw_set_alpha(0.9);
		draw_set_colour(_core_col);
		draw_circle(_s.x, _s.y, _s.radius, false);

		draw_set_alpha(1);
		draw_set_colour(c_white);
		draw_circle(_s.x, _s.y, _s.radius * 0.5, false);

		// Life bar
		draw_set_alpha(0.5);
		draw_set_colour(merge_colour(c_red, c_lime, _life_ratio));
		var _bar_max = max(_s.radius, 12);
		draw_rectangle(_s.x - _bar_max, _s.y + _s.radius + 6,
			_s.x - _bar_max + _bar_max * 2 * _life_ratio, _s.y + _s.radius + 8, false);

		// Dust count
		if (_s.dust_count > 0) {
			draw_set_alpha(0.7);
			draw_set_colour(c_white);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_font(fnt_default);
			draw_text(_s.x, _s.y - _s.radius - 10, string(_s.dust_count));
		}

		// Planets
		_pi = 0;
		repeat (_plen) {
			var _p = _s.planets[_pi];
			draw_set_alpha(0.04);
			draw_set_colour(_p.color);
			draw_circle(_p.px, _p.py, planet_pull_radius, true);

			draw_set_alpha(0.25);
			draw_circle(_p.px, _p.py, _p.psize + 3, false);

			draw_set_alpha(1);
			draw_set_colour(_p.color);
			draw_circle(_p.px, _p.py, _p.psize, false);

			draw_set_alpha(0.4);
			draw_set_colour(c_white);
			draw_circle(_p.px - _p.psize * 0.3, _p.py - _p.psize * 0.3, _p.psize * 0.35, false);
			_pi++;
		}
	}
	_si++;
}

// --- NOVA PARTICLES ---
var _nova_len = array_length(nova_particles);
_ni = 0;
repeat (_nova_len) {
	var _np = nova_particles[_ni];
	draw_set_alpha(_np.alpha);
	draw_set_colour(_np.color);
	draw_circle(_np.x, _np.y, _np.size, false);
	_ni++;
}

// --- POPUPS ---
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_default);
var _pop_len = array_length(popups);
var _poi = 0;
repeat (_pop_len) {
	var _pop = popups[_poi];
	draw_set_alpha(min(_pop.alpha, 1.0));
	draw_set_colour(c_yellow);
	draw_text_transformed(_pop.x, _pop.y, _pop.text, 1.3, 1.3, 0);
	_poi++;
}
draw_set_alpha(1);

// --- THE VOID (black borders) ---
var _vp_x = void_level * _w;
var _vp_y = void_level * _h;

if (_vp_x > 0 || _vp_y > 0) {
	draw_set_alpha(1);
	draw_set_colour(c_black);
	if (_vp_x > 0) draw_rectangle(0, 0, _vp_x, _h, false);
	if (_vp_x > 0) draw_rectangle(_w - _vp_x, 0, _w, _h, false);
	if (_vp_y > 0) draw_rectangle(_vp_x, 0, _w - _vp_x, _vp_y, false);
	if (_vp_y > 0) draw_rectangle(_vp_x, _h - _vp_y, _w - _vp_x, _h, false);

	// Inner edge glow (purple/red wisp)
	var _wi = 0;
	repeat (8) {
		var _wa = 0.15 * (1.0 - _wi / 8) * (0.6 + 0.4 * dsin(game_time * 1.5 + _wi * 45));
		draw_set_alpha(_wa);
		draw_set_colour(make_colour_rgb(40 + _wi * 8, 0, 50 - _wi * 4));
		var _offset = _wi * 4;
		draw_rectangle(_vp_x, _vp_y, _vp_x + _offset + 2, _h - _vp_y, false);
		draw_rectangle(_w - _vp_x - _offset - 2, _vp_y, _w - _vp_x, _h - _vp_y, false);
		draw_rectangle(_vp_x, _vp_y, _w - _vp_x, _vp_y + _offset + 2, false);
		draw_rectangle(_vp_x, _h - _vp_y - _offset - 2, _w - _vp_x, _h - _vp_y, false);
		_wi++;
	}
}

// --- BIG BANG FLASH ---
if (bang_flash > 0) {
	draw_set_alpha(bang_flash);
	draw_set_colour(c_white);
	draw_rectangle(0, 0, _w, _h, false);
}

// --- VOID COUNTDOWN: PULSING BLACK BORDER ---
if (game_state == 1 && !void_active) {
	var _secs_left = ceil(void_grace_period / 60);
	var _border_pulse = 0;

	if (_secs_left <= 4) {
		// Intense pulsing thick black border
		_border_pulse = 0.5 + 0.5 * abs(dsin(game_time * 8));
		var _thickness = 8 + 12 * _border_pulse;
		draw_set_alpha(_border_pulse);
		draw_set_colour(c_black);
		draw_rectangle(0, 0, _w, _thickness, false);
		draw_rectangle(0, _h - _thickness, _w, _h, false);
		draw_rectangle(0, 0, _thickness, _h, false);
		draw_rectangle(_w - _thickness, 0, _w, _h, false);

		// Countdown number
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_alpha(0.7 + 0.3 * _border_pulse);
		draw_set_colour(make_colour_rgb(200, 30, 50));
		var _cs = 4.0 + 2.0 * abs(dsin(game_time * 5));
		draw_text_transformed(_w * 0.5, _h * 0.42, string(_secs_left), _cs, _cs, 0);

	} else {
		// Quiet countdown top center
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		draw_set_alpha(0.3);
		draw_set_colour(make_colour_rgb(100, 100, 150));
		draw_text_transformed(_w * 0.5, 12, string(_secs_left) + "s", 1.0, 1.0, 0);
	}
}

// --- UI (always on top) ---
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fnt_default);
draw_set_alpha(1);

// Energy
var _ei = 0;
repeat (energy) {
	var _ex = 20 + _ei * 28;
	draw_set_colour(c_yellow);
	draw_circle(_ex, 20, 8, false);
	draw_set_colour(c_white);
	draw_circle(_ex, 20, 4, false);
	_ei++;
}

// Points
draw_set_colour(c_white);
draw_set_halign(fa_right);
draw_text_transformed(_w - 20, 15, string(points), 2, 2, 0);

// --- BIG BANG TEXT ---
if (game_state == 0) {
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	var _bang_progress = big_bang_timer / big_bang_duration;
	var _text_alpha = 0;
	if (_bang_progress < 0.4) {
		_text_alpha = min(_bang_progress * 4, 1.0);
	} else {
		_text_alpha = max(1.0 - (_bang_progress - 0.4) * 2, 0);
	}
	draw_set_alpha(_text_alpha);
	draw_set_colour(c_white);
	draw_text_transformed(_w * 0.5, _h * 0.5, "LET THERE BE LIGHT", 2.5, 2.5, 0);
}

// --- GAME OVER ---
if (game_state == 2) {
	draw_set_alpha(0.85);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, _w, _h, false);

	draw_set_alpha(1);
	draw_set_colour(make_colour_rgb(80, 40, 120));
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_transformed(_w * 0.5, _h * 0.22, "THE VOID CONSUMES ALL", 2.5, 2.5, 0);

	draw_set_colour(c_white);
	draw_text_transformed(_w * 0.5, _h * 0.35, "But your light endured", 1.5, 1.5, 0);

	draw_set_colour(c_yellow);
	draw_text_transformed(_w * 0.5, _h * 0.48, string(points) + " points", 3, 3, 0);

	var _secs = floor(game_time / 60);
	draw_set_colour(make_colour_rgb(180, 180, 255));
	draw_set_alpha(0.8);
	draw_text_transformed(_w * 0.5, _h * 0.60, string(_secs) + "s survived", 1.5, 1.5, 0);

	draw_set_colour(c_white);
	draw_set_alpha(0.5 + 0.3 * dsin(game_time * 3));
	draw_text_transformed(_w * 0.5, _h * 0.75, "Tap to defy the void again", 1.8, 1.8, 0);
}

draw_set_alpha(1);
draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
