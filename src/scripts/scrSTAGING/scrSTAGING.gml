#macro STAGING_VERSION "1.0.0"

enum STAGING_ASYNC_TYPE {
	AUDIO_PLAYBACK,
	AUDIO_PLAYBACK_ENDED,
	AUDIO_RECORDING,
	CLOUD,
	DIALOG,	
	HTTP,
	IN_APP_PURCHASE,
	IMAGE_LOADED,
	NETWORKING,
	PUSH_NOTIFICATION,
	SAVE_LOAD,
	SOCIAL,
	STEAM,
	SYSTEM,
	LEN
}

global.STAGING_async_ids = {}
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.AUDIO_PLAYBACK,			"queue");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.AUDIO_PLAYBACK_ENDED,	"sound_id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.AUDIO_RECORDING,		"channel_index");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.CLOUD,					"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.DIALOG,					"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.HTTP,					"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.IN_APP_PURCHASE,		"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.IMAGE_LOADED,			"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.NETWORKING,				"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.PUSH_NOTIFICATION,		"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.SAVE_LOAD,				"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.SOCIAL,					"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.STEAM,					"id");
struct_set(global.STAGING_async_ids, STAGING_ASYNC_TYPE.SYSTEM,					undefined);

enum STAGING_EXIT_STATUS {
	DONE,
	WAIT,
	LEN
}

function STAGING_Stage(_label="", _f=undefined, _args=undefined) constructor {
	label = _label;
	
	if is_undefined(_f) _f = function(){};
	f = _f;
	
	if is_undefined(_args) _args = [];
	args = _args;
	
	draw_x = 4;
	draw_y = 4;
	draw_font = fntSTAGING;
	draw_color = c_white;
	draw_alpha = 1.0;
	draw_halign = fa_left;
	draw_valign = fa_top;
	
	static draw_config = function(self, _vars=undefined) {
		if !is_undefined(_vars) {
			struct_foreach(_vars, function(_k, _v) {
				variable_instance_set(self, _k, _v)
			});
		}
		draw_set_font(draw_font);
		draw_set_color(draw_color);
		draw_set_alpha(draw_alpha);
		draw_set_halign(draw_halign);
		draw_set_valign(draw_valign);
	}
	
	draw = function(self, _config=false) {
		if _config draw_config();
		draw_text(draw_x, draw_y, label);	
	}
	
	start = function(self) {
		if !is_callable(f) return;
		script_execute_ext(f, args);
	}
	
	stop = function(self){}
	
	do_next = function(self) {
		array_insert(global.STAGING_stages, 0, self);
	}
	
	do_last = function(self) {
		array_push(global.STAGING_stages, self);
	}
	
	do_last();
}

function STAGING_Stage_Async(_async_type, _label="",
	_f=undefined, _args=undefined,
	_callback=undefined, _callback_args=undefined
) : STAGING_Stage(_label, _f, _args) constructor {
	if is_undefined(_callback) _callback = function(_args_async, _async_load){};
	if is_undefined(_callback_args) _callback_args = [];
	callback = _callback;
	callback_args = _callback_args;
	async_type = _async_type;
	async_id = undefined;
	staging_id = undefined;

	start = function(self) {
		if !is_callable(f) return;
		async_id = script_execute_ext(f, args);
		if async_id == -1 {
			show_debug_message($"STAGING Failed to start async task '{label}'");
			return
		}
		array_push(global.STAGING_async[async_type], [async_id, self]);
		global.STAGING_async_count += 1;
	}
	
	handle_async = function(self) {
		if !is_callable(callback) return;
		var _status = script_execute_ext(callback, callback_args);
		if _status == STAGING_EXIT_STATUS.DONE {
			var _index = array_find_index(global.STAGING_async[async_type], function(_e, _i) {
				return _e[0] == async_id;	
			});
			if _index != -1 {
				array_delete(global.STAGING_async[async_type], _index, 1);
				global.STAGING_async_count -= 1;
			}
		}
	}
}

function STAGING_Stage_Repeating(_label="", _f=undefined, _args=undefined) : STAGING_Stage(_label, _f, _args) constructor {
	// Repeats every step as long as its function returns STAGING_EXIT_STATUS.WAIT
	start = function(self) {
		if !is_callable(f) return;
		var _status = script_execute_ext(f, args);
		if _status == STAGING_EXIT_STATUS.WAIT self.do_next();
	}
}

function STAGING_Stage_Pause(_label="", _pause_frames=1): STAGING_Stage(_label) constructor {
	pause_frames = _pause_frames;
	start = function(self) {
		pause_frames -= 1;
		if pause_frames > 0 self.do_next();
	}
}

function STAGING_async_event(_async_type, _stage_finder=undefined) {
	var _stage = undefined;
	if is_undefined(_stage_finder) {
		var _id_name = struct_get(global.STAGING_async_ids, _async_type);
		var _id = async_load[? _id_name];
		var _n_waiting = array_length(global.STAGING_async[_async_type]);
		var _waiter;
		for (var i=0; i<_n_waiting; i++) {
			_waiter = global.STAGING_async[_async_type][i];
			if _waiter[0] == _id {
				_stage = _waiter[1];
				break;
			}
		}
	} else {
		_stage = _stage_finder(_async_type);
	}
	if !is_undefined(_stage) _stage.handle_async();
}


function STAGING_prioritize(_from=undefined, _to=0) {
// Move a stage from one slot to another.
// By default, do the last stage first
	var _stages = global.STAGING_stages
	if _to < 0 or _to >= array_length(_stages) return;
	
	var _last;
	if is_undefined(_from) {
		_last = array_pop(_stages);
		if is_undefined(_last) return;
	} else {
		if _last < 0 or _last >= array_length(_stages) return;
		_last = array_get(_stages, _from);
		array_delete(_stages, _from, 1);
	}
	
	array_insert(_stages, _to, _last);
}