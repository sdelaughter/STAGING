var stage_finder = function(_async_type) {
	// You should probably define something better here if you intend to use System events
    try {
		return global.STAGING_async[_async_type][0][1];
	} catch(_){
		return undefined;
	};
}
STAGING_async_event(STAGING_ASYNC_TYPE.SYSTEM, stage_finder);