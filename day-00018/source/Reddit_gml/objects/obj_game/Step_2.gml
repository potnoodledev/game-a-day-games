
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

// Update display vars
window_width = _w;
window_height = _h;

// Compute cell size: fit 10 columns, ensure at least 12 rows visible
hud_h = max(50, floor(_h * 0.08));
var _avail_h = _h - hud_h;
cell_size = floor(_w / grid_cols);
if (cell_size * 12 > _avail_h) cell_size = floor(_avail_h / 12);
cell_size = max(cell_size, 8);
bevel = max(2, floor(cell_size * 0.15));
visible_rows = ceil(_avail_h / cell_size) + 1;

// Center grid horizontally
grid_ox = floor((_w - grid_cols * cell_size) * 0.5);
grid_oy = hud_h;
