# STAGING Patch Notes

## 1.1.0 (2026-06-27)
- `oSTAGING_Manager` no longer relies on global variables to manage stages, allowing multiple instances to run simultaneously.
- Calling `new STAGING_Stage(_label, _f, _args)` no longer adds the stage to a queue automatically.  Instead, call `sm.add(_label, _f, _args)` where `sm` is an instance of `oSTAGING_Manager`.  This will also store a reference to the manager instance in the stage's `manager` variable.  Similary, use:
    - `sm.add_pause()` in place of `new STAGING_Stage_Pause()`
    - `sm.add_repeating()` in place of `new STAGING_Stage_Repeating()`
    - `sm.add_async()` in place of `new STAGING_Stage_Async()`
- Certain functions have been moved from the global scope to instead be methods of `oSTAGING_Manager`:
    - `STAGING_prioritize()` is now `sm.prioritize()`
    - `STAGING_async_event()` is now `sm.async_event()`
- Renamed `STAGING_EXIT_STATUS` enum to `STAGING_STATUS`

## 1.0.0 (2026-06-26)
- Initial release