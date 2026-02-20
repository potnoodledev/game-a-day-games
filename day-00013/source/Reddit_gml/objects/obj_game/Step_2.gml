
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

if (_w != window_width || _h != window_height) {
    window_width = _w;
    window_height = _h;
    layout_dirty = true;
}

if (layout_dirty) {
    layout_dirty = false;

    var _pad = max(8, _w * 0.03);

    hud_h = max(50, _h * 0.08);

    var _btn_h = max(50, _h * 0.07);
    button_area_y = _h - _btn_h - _pad;

    station_area_h = max(70, _h * 0.12);
    station_area_y = button_area_y - station_area_h - _pad * 0.5;

    belt_area_h = max(50, _h * 0.10);
    belt_area_y = station_area_y - belt_area_h - _pad * 0.5;

    order_area_y = hud_h + _pad;
    order_area_h = belt_area_y - order_area_y - _pad;
    order_row_h = order_area_h / max_orders;

    // Station buttons (square)
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

    // Power-up cards
    var _card_w = (_w - _pad * 3) * 0.45;
    var _card_h = _h * 0.28;
    var _card_y = _h * 0.38;
    powerup_card_1.x1 = _w * 0.5 - _card_w - _pad * 0.5;
    powerup_card_1.y1 = _card_y;
    powerup_card_1.x2 = _w * 0.5 - _pad * 0.5;
    powerup_card_1.y2 = _card_y + _card_h;

    powerup_card_2.x1 = _w * 0.5 + _pad * 0.5;
    powerup_card_2.y1 = _card_y;
    powerup_card_2.x2 = _w * 0.5 + _card_w + _pad * 0.5;
    powerup_card_2.y2 = _card_y + _card_h;
}
