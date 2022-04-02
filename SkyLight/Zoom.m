// accessibility zoom

CFMachPortRef SLSEventTapCreate(unsigned int edi_location,NSString* rsi_priority,unsigned int edx_placement,unsigned int ecx_options,unsigned long r8_eventsOfInterest,void* r9_callback,void* stack_info)
{
	// returns NULL unless it's this string
	rsi_priority=@"com.apple.coregraphics.eventTapPriority.accessibility";
	
	return SLSEventTapCreat$(edi_location,rsi_priority,edx_placement,ecx_options,r8_eventsOfInterest,r9_callback,stack_info);
}