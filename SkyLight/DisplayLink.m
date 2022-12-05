// AppKit scrolling crashes +[NSDisplayTiming displayTimingForScreenNumber:targetUpdateInterval:]
// just returning NULL worked in Monterey, but Ventura requires actual values

char* SLSDisplayGetTiming(char* rdi_structOut,unsigned long rsi,unsigned int edx_screenID)
{
	long* prevUpdateTime=rdi_structOut+0x18;
	long* interval=rdi_structOut;
	long* submissionInterval=rdi_structOut+0x20;
	
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