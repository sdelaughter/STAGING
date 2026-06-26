if !started exit;

if !is_undefined(stage) stage.stop();	

if array_length(global.STAGING_stages) > 0 {
	stage = array_shift(global.STAGING_stages);
	if is_instanceof(stage, STAGING_Stage) {
		stage.start();
		stage.draw_config();
	}
	else stage = undefined;
} else {
	if global.STAGING_async_count > 0 {
		if debug show_debug_message($"STAGING: Waiting on {global.STAGING_async_count} async tasks...")
	} else {
		if debug show_debug_message($"STAGING: All stages finished, including async wait")
		on_finish();
		instance_destroy(); exit;
	}
}