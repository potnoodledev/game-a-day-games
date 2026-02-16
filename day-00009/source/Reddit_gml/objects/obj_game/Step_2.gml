
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

window_width = _w;
window_height = _h;
