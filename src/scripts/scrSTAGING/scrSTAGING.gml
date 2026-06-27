#macro STAGING_VERSION "1.1.1"

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

enum STAGING_STATUS {
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
	
	static draw_config = function(_vars=undefined) {
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
	
	draw = function(_config=false) {
		if _config draw_config();
		draw_text(draw_x, draw_y, label);	
	}
	
	start = function() {
		if !is_callable(f) return;
		script_execute_ext(f, args);
	}
	
	stop = function(){}
	
	do_next = function() {
		array_insert(manager.stages, 0, self);
	}
	
	do_last = function() {
		array_push(manager.stages, self);
	}
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
		array_push(manager.async[async_type], [async_id, self]);
		manager.async_count += 1;
	}
	
	handle_async = function(self) {
		if !is_callable(callback) return;
		var _status = script_execute_ext(callback, callback_args);
		if _status == STAGING_STATUS.DONE {
			var _index = array_find_index(manager.async[async_type], function(_e, _i) {
				return _e[0] == async_id;	
			});
			if _index != -1 {
				stop();
				array_delete(manager.async[async_type], _index, 1);
				manager.async_count -= 1;
				array_push(manager.done, self);
			}
		}
	}
}

function STAGING_Stage_Repeating(_label="", _f=undefined, _args=undefined) : STAGING_Stage(_label, _f, _args) constructor {
	// Repeats every step as long as its function returns STAGING_STATUS.WAIT
	start = function(self) {
		if !is_callable(f) return;
		var _status = script_execute_ext(f, args);
		if _status == STAGING_STATUS.WAIT self.do_next();
	}
}

function STAGING_Stage_Pause(_label="", _pause_frames=1): STAGING_Stage(_label) constructor {
	pause_frames = _pause_frames;
	start = function(self) {
		pause_frames -= 1;
		if pause_frames > 0 self.do_next();
	}
}

function STAGING_Stage_Block(_wait_for_stage, _label=""): STAGING_Stage(_label) constructor {
	wait_for_stage = _wait_for_stage
	start = function(self) {
		if array_contains(manager.done, wait_for_stage) return;
		else self.do_next();
	}
}