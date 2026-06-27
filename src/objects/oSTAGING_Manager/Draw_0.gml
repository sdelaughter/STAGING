if !is_undefined(stage) {
	stage.draw(true);
} else {
	if array_length(stages) < 1 {
		async_wait_draw();
	}
}