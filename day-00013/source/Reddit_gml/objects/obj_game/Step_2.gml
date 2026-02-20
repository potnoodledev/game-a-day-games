
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

// Recalculate layout if window size changed
if (_w != window_width || _h != window_height) {
    window_width = _w;
    window_height = _h;
    layout_dirty = true;
}

if (layout_dirty) {
    layout_dirty = false;

    var _pad = max(8, _w * 0.03);

    // HUD area at top
    hud_h = max(50, _h * 0.08);

    // Button area at bottom — 3 buttons: UNDO, SHIP, CLEAR
    var _btn_h = max(50, _h * 0.07);
    button_area_y = _h - _btn_h - _pad;

    // Station area above buttons
    station_area_h = max(70, _h * 0.12);
    station_area_y = button_area_y - station_area_h - _pad * 0.5;

    // Belt area above stations
    belt_area_h = max(50, _h * 0.10);
    belt_area_y = station_area_y - belt_area_h - _pad * 0.5;

    // Order area fills remaining space between HUD and belt
    order_area_y = hud_h + _pad;
    order_area_h = belt_area_y - order_area_y - _pad;
    order_row_h = order_area_h / max_orders;

    // Build station button rects
    station_buttons = [];
    var _station_w = (_w - _pad * 2) / num_colors;
    var _btn_size = min(_station_w * 0.8, station_area_h * 0.85);
    var _si = 0;
    while (_si < num_colors) {
        var _cx = _pad + _station_w * _si + _station_w * 0.5;
        var _cy = station_area_y + station_area_h * 0.5;
        var _half = _btn_size * 0.5;
        array_push(station_buttons, {
            x1: _cx - _half,
            y1: _cy - _half,
            x2: _cx + _half,
            y2: _cy + _half,
            color_idx: _si
        });
        _si += 1;
    }

    // Three buttons: UNDO | SHIP | CLEAR
    var _btn_gap = _pad * 0.5;
    var _total_btn_w = _w - _pad * 2 - _btn_gap * 2;
    var _side_btn_w = _total_btn_w * 0.25;
    var _ship_btn_w = _total_btn_w * 0.5;

    undo_btn.x1 = _pad;
    undo_btn.y1 = button_area_y;
    undo_btn.x2 = _pad + _side_btn_w;
    undo_btn.y2 = button_area_y + _btn_h;

    ship_btn.x1 = _pad + _side_btn_w + _btn_gap;
    ship_btn.y1 = button_area_y;
    ship_btn.x2 = _pad + _side_btn_w + _btn_gap + _ship_btn_w;
    ship_btn.y2 = button_area_y + _btn_h;

    clear_btn.x1 = _pad + _side_btn_w + _btn_gap + _ship_btn_w + _btn_gap;
    clear_btn.y1 = button_area_y;
    clear_btn.x2 = _w - _pad;
    clear_btn.y2 = button_area_y + _btn_h;
}
