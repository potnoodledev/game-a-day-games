
// ============================================================
// AUTO CHESS — Step_2 (Responsive Layout)
// ============================================================

var _camera = view_camera[0];
var _w = window_get_width();
var _h = window_get_height();

if (surface_exists(application_surface)) {
	surface_resize(application_surface, _w, _h);
}

var _viewmat = matrix_build_lookat(_w * 0.5, _h * 0.5, -10, _w * 0.5, _h * 0.5, 0, 0, 1, 0);
camera_set_view_mat(_camera, _viewmat);
var _projmat = matrix_build_projection_ortho(_w, _h, 1.0, 32000.0);
camera_set_proj_mat(_camera, _projmat);
view_camera[0] = _camera;

display_set_gui_size(_w, _h);

// --- Recalculate layout on resize ---
if (_w != window_width || _h != window_height) {
	window_width = _w;
	window_height = _h;
	layout_dirty = true;
}

if (layout_dirty) {
	layout_dirty = false;

	var _pad = max(8, _w * 0.02);
	hud_h = max(40, _h * 0.06);
	var _syn_h = max(20, _h * 0.03);

	// Grid area: between HUD+synergy bar and shop panel
	// Shop takes bottom ~35% in shop phase, but grid should be consistent
	var _grid_area_top = hud_h + _syn_h + _pad;
	var _shop_height = _h * 0.32;
	shop_y = _h - _shop_height;
	var _grid_area_bottom = shop_y - _pad;

	var _grid_area_h = _grid_area_bottom - _grid_area_top;
	var _grid_area_w = _w - _pad * 2;

	// Cell size: fit grid into available space
	var _cell_by_w = floor(_grid_area_w / grid_cols);
	var _cell_by_h = floor(_grid_area_h / grid_rows);
	cell_size = min(_cell_by_w, _cell_by_h);
	cell_size = max(cell_size, 32); // minimum cell size

	// Center grid horizontally
	var _grid_total_w = cell_size * grid_cols;
	var _grid_total_h = cell_size * grid_rows;
	grid_x = floor((_w - _grid_total_w) * 0.5);
	grid_y = floor(_grid_area_top + (_grid_area_h - _grid_total_h) * 0.5);

	// Initialize sell_btn if not set
	sell_btn = { x1: 0, y1: 0, x2: 0, y2: 0 };
	go_btn = { x1: 0, y1: 0, x2: 0, y2: 0 };
}
