/// Editing operations on SAMPLE assets. Each one decodes the signed 8-bit
/// data, changes it and stores the asset again under the same name. A range
/// [_start, _end) with _end <= _start means the whole sample.

/// Signed 8-bit values of a SAMPLE asset as an array.
function scr_audio_sample_values(_asset) {
    var _bytes = scr_audio_asset_bytes(_asset);
    if (_bytes == -1) return [];
    var _length = _asset.length;
    var _values = array_create(_length, 0);
    buffer_seek(_bytes, buffer_seek_start, 0);
    var _i = 0;
    while (_i < _length) {
        _values[_i] = buffer_read(_bytes, buffer_s8);
        _i += 1;
    }
    buffer_delete(_bytes);
    return _values;
}

/// Stores _values (even length is enforced by padding with 0) back into a
/// SAMPLE asset, keeping its other settings. Returns the new struct.
function scr_audio_sample_store(_asset, _values, _loop, _loop_start, _loop_length) {
    var _length = min(array_length(_values), AUDIO_MAX_SAMPLE_BYTES);
    var _padded = _length + (_length mod 2);
    _padded = max(2, _padded);
    var _buffer = buffer_create(_padded, buffer_fixed, 1);
    buffer_fill(_buffer, 0, buffer_u8, 0, _padded);
    var _i = 0;
    while (_i < _length) {
        buffer_write(_buffer, buffer_s8, clamp(round(_values[_i]), -128, 127));
        _i += 1;
    }
    var _stored = scr_audio_define_sample(_asset.name, scr_audio_buffer_b64(_buffer, _padded), _padded, _asset.period,
        _asset.volume, _loop, _loop_start, _loop_length, _asset.source_name);
    buffer_delete(_buffer);
    return _stored;
}

/// Clamps a range to the sample; an empty range selects everything.
function scr_audio_sample_range(_asset, _start, _end) {
    var _a = clamp(floor(min(_start, _end)), 0, _asset.length);
    var _b = clamp(floor(max(_start, _end)), 0, _asset.length);
    if (_b <= _a) return [0, _asset.length];
    return [_a, _b];
}

/// Keeps only [_start, _end) (rounded out to even bytes). The loop is moved
/// with the data and dropped when it no longer fits.
function scr_audio_sample_trim(_asset, _start, _end) {
    var _range = scr_audio_sample_range(_asset, _start, _end);
    var _a = _range[0] - (_range[0] mod 2);
    var _b = min(_asset.length, _range[1] + (_range[1] mod 2));
    if (_b - _a < 2) return _asset;
    var _values = scr_audio_sample_values(_asset);
    var _out = array_create(_b - _a, 0);
    array_copy(_out, 0, _values, _a, _b - _a);
    var _ls = _asset.loop_start - _a;
    var _le = _asset.loop_start + _asset.loop_length - _a;
    _ls = max(0, _ls);
    _le = min(_b - _a, _le);
    var _loop = _asset.loop && _le - _ls >= 2;
    return scr_audio_sample_store(_asset, _out, _loop, _ls, _le - _ls);
}

/// Scales the range so its loudest value reaches full scale.
function scr_audio_sample_normalise(_asset, _start, _end) {
    var _range = scr_audio_sample_range(_asset, _start, _end);
    var _values = scr_audio_sample_values(_asset);
    var _peak = 0;
    var _i = _range[0];
    while (_i < _range[1]) {
        _peak = max(_peak, abs(_values[_i]));
        _i += 1;
    }
    if (_peak <= 0) return _asset;
    var _gain = 127 / _peak;
    _i = _range[0];
    while (_i < _range[1]) {
        _values[_i] = _values[_i] * _gain;
        _i += 1;
    }
    return scr_audio_sample_store(_asset, _values, _asset.loop, _asset.loop_start, _asset.loop_length);
}

/// Reverses the order of the bytes in the range.
function scr_audio_sample_reverse(_asset, _start, _end) {
    var _range = scr_audio_sample_range(_asset, _start, _end);
    var _values = scr_audio_sample_values(_asset);
    var _a = _range[0];
    var _b = _range[1] - 1;
    while (_a < _b) {
        var _swap = _values[_a];
        _values[_a] = _values[_b];
        _values[_b] = _swap;
        _a += 1;
        _b -= 1;
    }
    return scr_audio_sample_store(_asset, _values, _asset.loop, _asset.loop_start, _asset.loop_length);
}

/// Linear fade over the range: _fade_in true ramps 0 -> 1, else 1 -> 0.
function scr_audio_sample_fade(_asset, _start, _end, _fade_in) {
    var _range = scr_audio_sample_range(_asset, _start, _end);
    var _values = scr_audio_sample_values(_asset);
    var _span = max(1, _range[1] - _range[0] - 1);
    var _i = _range[0];
    while (_i < _range[1]) {
        var _t = (_i - _range[0]) / _span;
        _values[_i] = _values[_i] * (_fade_in ? _t : 1 - _t);
        _i += 1;
    }
    return scr_audio_sample_store(_asset, _values, _asset.loop, _asset.loop_start, _asset.loop_length);
}

/// Min / max per column for drawing a waveform of _values over _columns.
/// Returns [mins, maxs] (values -128..127).
function scr_audio_sample_minmax(_values, _columns) {
    var _mins = array_create(_columns, 0);
    var _maxs = array_create(_columns, 0);
    var _length = array_length(_values);
    if (_length <= 0) return [_mins, _maxs];
    var _c = 0;
    while (_c < _columns) {
        var _a = floor(_c * _length / _columns);
        var _b = max(_a + 1, floor((_c + 1) * _length / _columns));
        _b = min(_b, _length);
        var _lo = 127;
        var _hi = -128;
        var _i = _a;
        while (_i < _b) {
            var _v = _values[_i];
            if (_v < _lo) _lo = _v;
            if (_v > _hi) _hi = _v;
            _i += 1;
        }
        if (_hi < _lo) {
            _lo = 0;
            _hi = 0;
        }
        _mins[_c] = _lo;
        _maxs[_c] = _hi;
        _c += 1;
    }
    return [_mins, _maxs];
}
