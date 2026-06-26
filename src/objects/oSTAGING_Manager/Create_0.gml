// STAGING:
// Sequenced Task Automation for Game InitializiNG

debug = false;

var _me = id;
with (oSTAGING_Manager) {
	if id != _me {
		// There can only be one
		instance_destroy();
	}
}

global.STAGING_stages = [];
global.STAGING_async = [];
for (var i=0; i<STAGING_ASYNC_TYPE.LEN; i++) {
	global.STAGING_async[i] = [];
}
global.STAGING_async_count = 0;

stage = undefined;
started = false;

start = function() {
	started = true;
}

on_finish = function() {
	room_goto_next();
}

async_wait_draw = function() {
	draw_text(4, 4, $"Waiting on {global.STAGING_async_count} async tasks");	
}