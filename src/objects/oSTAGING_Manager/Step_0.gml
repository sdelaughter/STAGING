if !started exit;

if !is_undefined(stage) {
	if !is_instanceof(stage, STAGING_Stage_Async) {
		stage.stop();
		array_push(done, stage);
	}
}

if array_length(stages) > 0 {
	stage = array_shift(stages);
	if is_instanceof(stage, STAGING_Stage) {
		stage.start();
		stage.draw_config();
	}
	else stage = undefined;
} else {
	if async_count > 0 {
		if debug show_debug_message($"STAGING: Waiting on {async_count} async tasks...")
	} else {
		if debug show_debug_message($"STAGING: All stages finished, including async wait")
		on_finish();
		instance_destroy(); exit;
	}
}