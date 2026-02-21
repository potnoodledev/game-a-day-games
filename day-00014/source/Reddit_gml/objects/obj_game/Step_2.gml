
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

    hud_h = max(50, _h * 0.07);
    sub_area_y = hud_h + _pad;

    // Post card area
    post_card_y = sub_area_y + max(40, _h * 0.06) + _pad;
    post_card_h = max(80, _h * 0.15);

    // Choice buttons area
    choices_y = post_card_y + post_card_h + _pad * 2;
    var _remaining_h = _h - choices_y - _pad;
    choice_btn_h = min(max(40, _remaining_h * 0.18), 60);

    // 4 choice buttons
    choice_btns = [];
    var _btn_w = _w - _pad * 2;
    var _gap = _pad * 0.5;
    var _bi = 0;
    while (_bi < 4) {
        var _by = choices_y + _bi * (choice_btn_h + _gap);
        array_push(choice_btns, {
            x1: _pad,
            y1: _by,
            x2: _pad + _btn_w,
            y2: _by + choice_btn_h,
            type_idx: 0
        });
        _bi += 1;
    }

    // POST IT button
    var _post_y = choices_y + 4 * (choice_btn_h + _gap) + _gap;
    var _post_h = min(max(45, _remaining_h * 0.2), 65);
    post_btn.x1 = _pad;
    post_btn.y1 = _post_y;
    post_btn.x2 = _w - _pad;
    post_btn.y2 = _post_y + _post_h;
}

// Update choice_btns type indices from choice_options
var _bi2 = 0;
while (_bi2 < 4 && _bi2 < array_length(choice_btns)) {
    choice_btns[_bi2].type_idx = choice_options[_bi2];
    _bi2 += 1;
}
