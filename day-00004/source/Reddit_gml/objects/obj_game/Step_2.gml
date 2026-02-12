
// Fixed camera — fills window, no scrolling
var _camera = view_camera[0];

var _w = window_get_width();
var _h = window_get_height();

if (surface_exists(application_surface)) {
    surface_resize(application_surface, _w, _h);
}

// Update view port to match actual window (room defaults are 1366x768)
view_set_wport(0, _w);
view_set_hport(0, _h);

// Camera centered at half screen
var _cx = _w * 0.5;
var _cy = _h * 0.5;
var _viewmat = matrix_build_lookat(_cx, _cy, -10, _cx, _cy, 0, 0, 1, 0);
camera_set_view_mat(_camera, _viewmat);

var _projmat = matrix_build_projection_ortho(_w, _h, 1.0, 32000.0);
camera_set_proj_mat(_camera, _projmat);

view_camera[0] = _camera;
