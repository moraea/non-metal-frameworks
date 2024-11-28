// accessibility zoom

CFMachPortRef SLSEventTapCreate(unsigned int edi_location,NSString* rsi_priority,unsigned int edx_placement,unsigned int ecx_options,unsigned long r8_eventsOfInterest,void* r9_callback,void* stack_info)
{
	// returns NULL unless it's this string
	rsi_priority=@"com.apple.coregraphics.eventTapPriority.accessibility";
	
	return SLSEventTapCreat$(edi_location,rsi_priority,edx_placement,ecx_options,r8_eventsOfInterest,r9_callback,stack_info);
}

// new "zoom each display independently" setting (default on) breaks it entirely
// just overwrite the setting for now lol

void zoomHackSetup()
{
	// based on Nate's trackpad fix
	
	if([process isEqualToString:@"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"])
	{
		NSUserDefaults* defaults=[NSUserDefaults.alloc initWithSuiteName:@"com.apple.universalaccess"];
		[defaults setBool:false forKey:@"closeViewZoomIndividualDisplays"];
		defaults.release;
	}
}
