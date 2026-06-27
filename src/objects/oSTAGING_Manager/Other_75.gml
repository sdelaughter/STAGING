var stage_finder = function(_async_type) {
	// You should probably define something better here if you intend to use System events
    try {
		return async[_async_type][0][1];
	} catch(_){
		return undefined;
	};
}
async_event(STAGING_ASYNC_TYPE.SYSTEM, stage_finder);