// STAGING:
// Sequenced Task Automation for Game InitializiNG

debug = false;

stages = [];
async = [];
for (var i=0; i<STAGING_ASYNC_TYPE.LEN; i++) {
	async[i] = [];
}
async_count = 0;

stage = undefined;
started = false;

start = function() {
	started = true;
}

on_finish = function() {
	room_goto_next();
}

async_wait_draw = function() {
	draw_text(4, 4, $"Waiting on {async_count} async tasks");	
}

acquire = function(_stage, _slot=undefined) {
	_stage.manager = self;
	if is_undefined(_slot) array_push(stages, _stage);
	else array_insert(stages, _slot, _stage);
}

add = function(_label="", _f=undefined, _args=undefined) {
	var _stage = new STAGING_Stage(_label, _f, _args)
	acquire(_stage);
	return _stage;
}

add_repeating = function(_label="", _f=undefined, _args=undefined) {
	var _stage = new STAGING_Stage_Repeating(_label, _f, _args)
	acquire(_stage);
	return _stage;
}

add_pause = function(_label="", _pause_frames) {
	var _stage = new STAGING_Stage_Pause(_label, _pause_frames);
	acquire(_stage);
	return _stage;
}

add_async = function(_async_type, _label, _f, _args, _callback, _callback_args) {
	var _stage = new STAGING_Stage_Async(_async_type, _label, _f, _args, _callback, _callback_args);
	acquire(_stage);
	return _stage;
}

prioritize = function(_from=undefined, _to=0) {
// Move a stage from one slot to another.
// By default, do the last stage first
	if _to < 0 or _to >= array_length(stages) return;
	
	var _last;
	if is_undefined(_from) {
		_last = array_pop(stages);
		if is_undefined(_last) return;
	} else {
		if _last < 0 or _last >= array_length(stages) return;
		_last = array_get(stages, _from);
		array_delete(stages, _from, 1);
	}
	
	array_insert(stages, _to, _last);
}

async_event = function(_async_type, _stage_finder=undefined) {
	var _stage = undefined;
	if is_undefined(_stage_finder) {
		var _id_name = struct_get(global.STAGING_async_ids, _async_type);
		var _id = async_load[? _id_name];
		var _n_waiting = array_length(async[_async_type]);
		var _waiter;
		for (var i=0; i<_n_waiting; i++) {
			_waiter = async[_async_type][i];
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