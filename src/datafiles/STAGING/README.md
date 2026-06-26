# STAGING
### Sequenced Task Automation for Game InitializiNG

## Overview
STAGING is a GameMaker Library for game initialization.  It helps you split startup tasks into discrete chunks to be run in sequence, rather than trying to run your entire initialization script in a single frame (which can cause very bad things to happen, especially on console platforms).

It also provides support for asynchronous tasks, by waiting for the appropriate async event to trigger and executing a callback function when it does.

## Setup
You can look at the `create` event of the `oSTAGING_Test` object for an example of how to use this library, but here are the basic steps:

### 1. Create a Manager
Create an instance of the `oSTAGING_Manager` object by calling:
```
stage_manager = instance_create_depth(0, 0, 0, oSTAGING_Manager);
```

Only one manager instance can exist at a time, since it relies on global variables.  If you create a new manager instance it will destroy any old ones that still exist and reset the global variables, erasing any stages that may have been pending.

### 2. Add Stages
A standard stage creation looks like:
```
var _stage = new STAGING_Stage(_label, _f, _args);
```

Note that we don't pass any reference to the stage manager here.  The manager relies on a global array of stages, and this constructor will add its stage to that array automatically.  You also don't need to store a reference to the stage in a variable as shown here, unless you want to adjust it as discussed below.

The arguments are as follows:
- `_label` is a string that will be displayed on the top-left of the screen while the stage is running.  You can adjust the font/color/alpha/alignment/position of this text by calling `_stage.draw_conf(vars)` where `vars` is a struct containing any of the following keys with relevant values: `"draw_font", "draw_color", "draw_alpha", "draw_halign", "draw_valign", "draw_x", "draw_y"`.  You can also redefine the stage's `draw` method if you'd like to display something entirely different while it runs, or display nothing by defining it as `_stage.draw = function(){}`
- `_f` is a function that will be called when the stage is run.
- `_args` is an optional array of arguments that will be passed to the function `_f`.  In most cases this is unnecessary, but it can be useful for passing the function a reference to the stage that is calling it (among other things).

#### Special Stages
In addition to the standard `STAGING_Stage`, there are three other specialized stage constructors.

First is `STAGING_Stage_Repeating`, designed to perform some task repeatedly every step until some condition is met.  It takes the same three arguments as the regular `STAGING_Stage`.  The only difference is that its function `_f` must return `STAGING_EXIT_STATUS.WAIT` to continue running, or `STAGING_EXIT_STATUS.DONE` once finished.

Second is `STAGING_Stage_Pause`, which simply waits a fixed number of frames.  A good use case for this is waiting the recommended 10 frames after changing from fullscreen to windowed mode before resizing the window.  For example:

```
new STAGING_Stage("Switching to windowed mode...", function() {
    window_set_fullscreen(false);
});

new STAGING_Stage_Pause("Waiting to exit fullscreen...", 10);

new STAGING_Stage("Resizing window...", function() {
    window_set_size(1920, 1080);
});
```

Third is `STAGING_Stage_Async`, designed to run tasks which trigger asynchronous events.  It takes a different set of arguments, and is constructed as follows:
```
var _async_stage = new STAGING_Stage_Async(_async_type, _label, _f, _args, _callback, _callback_args);
```

The arguments are as follows:
- `_async_type` is a member of the `STAGING_ASYNC_TYPES` enum, indicating which type of async event will be triggered to handle the callback.
- `_label` is the same as for the standard `STAGING_Stage`
- `_f` is the same as for the standard `STAGING_Stage`, except that it must return the id value output by the async function being run.  For example, if `_f` includes a call to `http_get`, its definition might look like:
```
function() {
    var _async_id = http_get("https://gamemaker.io");
    return _async_id;
}
```
- `_args` is the same as for the standard `STAGING_Stage`.
- `_callback` is a function that will be executed when the corresponding async event triggers for the async id value returned by `_f`.  This is where you should handle data found in the `async_load` DS_Map, such as the status of the operation.  In some cases, your `_callback` function may need to trigger multiple times before you're ready to stop waiting on it.  For example, when downloading a file with `http_get`, you may see a status of `1` (downloading) several times before finally seeing a status of `0` (complete) or something less than `0` (error).  Your `_callback` function must return `STAGING_ASYNC_STATUS.WAIT` as long as the task is still in progress, and return `STAGING_ASYNC_STATUS.DONE` once it's finished.
- `_callback_args` is an optional array of arguments that will be passed to `_callback`.

### 3. Define `on_finish()`
Make sure to define the manager's `on_finish()` function.  This will be run once all stages are complete and all async tasks triggered by stages have finished.  By default it simply calls `room_goto_next()`, which might be enough, but you can do something more complicated like:
```
stage_manager.on_finish = function() {
    show_debug_message("STAGING finished, hooray!");
	room_goto(rMenuMain);
}
```

Note that you cannot simply define this behavior as a final stage, since that will cause it to execute *before* the manager has finished waiting on async tasks.

### 4. Start
Start executing stages by calling `stage_manager.start()`

## Supported Async Events

When constructing an `STAGING_Stage_Async`, you'll need to pass it an `_async_type` value, from the `ASYNC_EVENT_TYPES` enum.  Enum members are: `AUDIO_PLAYBACK, AUDIO_PLAYBACK_ENDED, AUDIO_RECORDING, CLOUD, DIALOG, HTTP, IN_APP_PURCHASE, IMAGE_LOADED, NETWORKING, PUSH_NOTIFICATION, SAVE_LOAD, SOCIAL, STEAM, SYSTEM`

Note that certain async functions will require some additional effort to handle.  These include functions related to the `Async - System` Event, as well as any other async functions that do not return some sort of unique ID value.  In these cases, the function you pass to `STAGING_Stage_Async` must create some other ID value to return.  And you must modify the relevant event definition of `oSTAGING_Manager` by defining and passing some `stage_finder` function as a second argument to `STAGING_async_event`.  This `stage_finder` function should accept an `_async_type` as an argument (a member of `ASYNC_EVENT_TYPES`), and should return a reference to the instance of `STAGING_Stage_Async` whose callback function is to be triggered.  This reference can be found in `global.STAGING_async[_async_type]`, which holds a list of tuples in which the first element is an ID and the second is a corresponding `STAGING_Stage_Async` instance.  Determining a good way to locate the correct ID from your `stage_finder` function is left as an exercise for the developer.  If you feel confident that only a single event of the given type will be triggered, or that events will always trigger in the order they are initialized, this could be as simple as:
```
var stage_finder = function(_async_type) {
    return global.STAGING_async[_async_type][0][1];
}
async_event(STAGING_ASYNC_TYPE.SYSTEM, stage_finder);
```

This is what's currently implemented for the `Async - System` event, but relying on it is not recommended.


## Misc.

### Prioritization
When constructing a new stage with `new oSTAGING_Stage()` or one of the special constructors described above, it will automatically be added to the end of the `global.STAGING_stages` array, to be executed after all other stages that have been added so far.  In certain cases, you may want to prioritize stages differently.  For example, if the callback function of an asynchronous buffer save stage creates a new buffer load stage, you may want to do that immediately.

In this case, you can call `STAGING_prioritize(_from, _to)` after constructing the new stage, and it will move the stage in slot number `_from` to slot number `_to`.  By default, `_from` will be set to the last slot, and `_to` will be set to the first slot.