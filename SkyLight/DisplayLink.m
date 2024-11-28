// AppKit scrolling crashes +[NSDisplayTiming displayTimingForScreenNumber:targetUpdateInterval:]
// just returning NULL worked in Monterey, but Ventura requires actual values

char* SLSDisplayGetTiming(char* rdi_structOut,unsigned long rsi,unsigned int edx_screenID)
{
	long* prevUpdateTime=(long*)(rdi_structOut+0x18);
	long* interval=(long*)rdi_structOut;
	long* submissionInterval=(long*)(rdi_structOut+0x20);
	
	*prevUpdateTime=0;
	*interval=1.0/60*NSEC_PER_SEC;
	*submissionInterval=0;
	
	return rdi_structOut;
}

// fix Catalyst scrolling
// credit: EduCovas

long SLSDisplayGetCurrentVBLDeltaInNanoseconds()
{
	return 1.0/60*NSEC_PER_SEC;
}

// fix missing Photos previews on Sequoia
// TODO: i can't see how to get a CADisplay's CGDirectDisplayID..?

#if MAJOR>=15
CADisplayLink* SLSGetDisplayLink(CGDirectDisplayID display,id target,SEL action)
{
	return [CADisplayLink displayLinkWithDisplay:CADisplay.mainDisplay target:target selector:action];
}
#else
id SLSGetDisplayLink(CGDirectDisplayID display,id target,SEL action)
{
	return nil;
}
#endif
