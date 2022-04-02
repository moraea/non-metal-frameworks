// Monterey display timing

// AppKit +[NSDisplayTiming displayTimingForScreenNumber:targetUpdateInterval:]
// returns early if structOut is null
// otherwise crashes with assertions on structOut members
char** SLSDisplayGetTiming(char** rdi_structOut,unsigned long rsi,unsigned int edi_screenID)
{
	*rdi_structOut=NULL;
	return rdi_structOut;
}

// fix Catalyst scrolling
// credit: EduCovas

long SLSDisplayGetCurrentVBLDeltaInNanoseconds()
{
	return 1.0/60*NSEC_PER_SEC;
}