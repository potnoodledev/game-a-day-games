/// @description Responsive sizing

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

// Update layout
window_width = _w;
window_height = _h;

// Calculate grid layout — fit 6x6 grid with padding
var _pad = 16;
var _top_bar = 100; // timer + score area
var _bottom_bar = 80; // word display + stats
var _avail_w = _w - _pad * 2;
var _avail_h = _h - _top_bar - _bottom_bar - _pad;
cell_size = min(_avail_w / COLS, _avail_h / ROWS);
cell_size = min(cell_size, 80); // cap max size

grid_x = (_w - cell_size * COLS) / 2;
grid_y = _top_bar + (_avail_h - cell_size * ROWS) / 2;
