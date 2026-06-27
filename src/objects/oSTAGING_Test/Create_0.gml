show_debug_message("STAGING: Creating test stages");

sm = instance_create_depth(0, 0, 0, oSTAGING_Manager);
sm.debug = true;

// Basic Stage
new STAGING_Stage("STAGING: Seeding Randomness...", function() {
	random_set_seed(current_second+current_minute*60+current_hour*3600)
}, []);

// Repeating Stage
var _repeating_stage = sm.add_repeating("Testing repetition...", function(_stage) {
	_stage.label = $"Testing repetition {_stage.test_counter}..."
	if _stage.test_counter > 0 {
		_stage.test_counter -= 1;
		return STAGING_STATUS.WAIT;
	} else return STAGING_STATUS.DONE;
}, []);
_repeating_stage.test_counter = 60;
// Pass the function a reference to the stage, so we can change the label and get the counter
_repeating_stage.args = [_repeating_stage]; 

// Test async http get
var _http_stage = sm.add_async(STAGING_ASYNC_TYPE.HTTP, "Testing HTTP Get async...",
	function() {
		var _url = "https://gamemaker.io"
		show_debug_message($"STAGING: Starting HTTP Get of {_url}");
		var _async_id = http_get(_url);
		return _async_id;
	}, [],
	function() {
		var _status = async_load[? "status"];
		var _url = async_load[? "url"]
		if _status == 1 {
			// Downloading
			show_debug_message($"STAGING: Waiting on HTTP Get of {_url}");
			return STAGING_STATUS.WAIT;
		} else if _status == 0 {
			// Finished
			show_debug_message($"STAGING: Finished HTTP Get of {_url}");
			return STAGING_STATUS.DONE;
		} else if _status < 0 {
			// Error
			show_debug_message($"STAGING: Got error {_status} during HTTP Get of {_url}");
			return STAGING_STATUS.DONE;
		}
	}, []
);

// Test stop function
_http_stage.stop = function() {
	show_debug_message("STAGING: HTTP Get stage has stopped");	
}

// Test async image loading
var _image_load_stage = sm.add_async(STAGING_ASYNC_TYPE.IMAGE_LOADED, "Testing Image Load async...",
	function() {
		var _size = 1024;
		//var _url = $"https://picsum.photos/{_size}";
		var _url = "STAGING/staging.png"
		show_debug_message($"STAGING: Starting Image Load of {_url}");
		var _async_id = sprite_add_ext(_url, 0, 0, 0, true);
		return _async_id;
	}, [],
	function() {
		var _status = async_load[? "status"];
		var _url = async_load[? "filename"];
		var _id = async_load[? "id"];

		if _status < 0 {
			// Error
			show_debug_message($"STAGING: Got error {_status} during Image Load of {_url}");
		} else {
			// Finished
			show_debug_message($"STAGING: Finished Image Load of {_url} to sprite index {_id}");
			//layer_background_sprite(layer_background_get_id(layer_get_id("Background")), _id);
			global.STAGING_test_image = _id;
		}
		return STAGING_STATUS.DONE;
	}, []
);

// Test async save/load, with nested stages
sm.add_async(STAGING_ASYNC_TYPE.SAVE_LOAD, "Testing buffer save...",
	function() {
		show_debug_message($"STAGING: Starting buffer save");
		var _buff = buffer_create(1024, buffer_fast, 1);
		buffer_fill(_buff, 0, buffer_u8, 42, 1024);
		global.STAGING_test_buffer_A = _buff;
		var _async_id = buffer_save_async(_buff, "STAGING/test_buffer.sav", 0, 1024);
		return _async_id;
	}, [],
	function() {
		var _status = async_load[? "status"];
		if _status == false {
			show_debug_message($"STAGING: Buffer failed to save");
		} else {
			show_debug_message($"STAGING: Buffer saved successfully");
			manager.add_async(STAGING_ASYNC_TYPE.SAVE_LOAD, "Testing buffer load...",
				function() {
					show_debug_message($"STAGING: Starting buffer load");
					var _buff = buffer_create(1024, buffer_fast, 1);
					global.STAGING_test_buffer_B = _buff;
					var _async_id = buffer_load_async(_buff, "STAGING/test_buffer.sav", 0, 1024);
					return _async_id;
				}, [],
				function() {
					var _status = async_load[? "status"];
					if _status == false {
						show_debug_message($"STAGING: Buffer failed to load");
					} else {
						show_debug_message($"STAGING: Buffer loaded successfully");
						var _hash_A = buffer_md5(global.STAGING_test_buffer_A, 0, 1024);
						var _hash_B = buffer_md5(global.STAGING_test_buffer_B, 0, 1024);
						if _hash_A == _hash_B {
							show_debug_message("STAGING: Loaded buffer hash matches original");
						} else {
							show_debug_message("STAGING: ERROR: Loaded buffer hash does not match original!");
						}
					}
					buffer_delete(global.STAGING_test_buffer_A);
					buffer_delete(global.STAGING_test_buffer_B);
					variable_global_set(global.STAGING_test_buffer_A, undefined);
					variable_global_set(global.STAGING_test_buffer_B, undefined);
					if file_exists("STAGING/test_buffer.sav") file_delete("STAGING/test_buffer.sav");
				}, []
			)
			manager.prioritize();
		}
	}, []
);

// Basic stage that should run before prior async completes
sm.add("Doing stuff during async...", function() {
	show_debug_message("STAGING: Doing stuff during async");
}, []);


// Make sure a prior stage has completed before continuing to a stage that depends on it
sm.add_block(_image_load_stage, "Waiting until image load completes...");

// Pause Stage, with custom draw for image we loaded via async
var _pause_stage = sm.add_pause("Pausing for 100 frames...", 100)
_pause_stage.draw = function(self, _config=false) {
	if variable_global_exists("STAGING_test_image") {
		draw_sprite(global.STAGING_test_image, 0, 0, 0);
	}
}

// Test prioritization
sm.add("Testing prioritization (1)...", function() {
	show_debug_message("STAGING: This should happen before any other stages");
}, []);
sm.prioritize();

sm.add("Testing prioritization (3)...", function() {
	show_debug_message("STAGING: This should happen third");
}, []);
sm.prioritize(undefined, 1);

sm.add("Testing prioritization (2)...", function() {
	show_debug_message("STAGING: This should happen second");
}, []);
sm.prioritize(undefined, 1);

// Define what happens when finished
sm.on_finish = function() {
	room_goto(rSTAGING_Done);
}

// Test multiple managers running simultaneously
sm2 = instance_create_depth(0, 0, 0, oSTAGING_Manager);
sm2.debug = true;
var _stage2 = sm2.add_pause("Testing secondary manager...", 60);
sm2.add("Secondary manager finishing...", function(){
	show_debug_message("STAGING: Secondary manager finishing");	
});
_stage2.draw_config({"draw_y": 50});
sm2.on_finish = function(){};

// Start running stages
show_debug_message("STAGING: Starting test stages");
sm.start();
sm2.start();