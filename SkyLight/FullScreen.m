// credit EduCovas - implementation is required for fullscreen animation
// AppKit "screenshots" the window to animate smoothly, similar to light/dark transition

NSArray* SLSHWCaptureWindowList(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags)
{
	NSArray* result=SLSHWCaptureWindowLis$(edi_cid,rsi_list,edx_count,ecx_flags);

#if MAJOR>=13
	result=uninvertScreenshots(result);
#endif
	
	return result;
}

NSArray* SLSHWCaptureWindowListInRect(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,CGRect stack)
{
	// TODO: hack, still don't fully understand what AppKit is doing here
	
	#define SHADOW 1
	#define JUST_WINDOW 8
	
	if(ecx_flags&1)
	{
		ecx_flags=SHADOW|JUST_WINDOW;
	}
	else
	{
		ecx_flags=0;
	}
	
	NSArray* result=SLSHWCaptureWindowLis$InRect(edi_cid,rsi_list,edx_count,ecx_flags,stack);

#if MAJOR>=13
	result=uninvertScreenshots(result);
#endif

	return result;
}

NSArray* SLSHWCaptureWindowListInRectWithSeed(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,int r8,CGRect stack)
{
	// supposed to snapshot an in-progress CATransaction
	// still no idea how to do that, so just forcibly commit all (can be multiple nested)
	
#if MAJOR>=14
	
	while(CATransaction.currentState)
	{
		CATransaction.commit;
	}
	
	// TODO: ew, but occasionally breaks without this
	
	[NSThread sleepForTimeInterval:0.01];
	
#else
	CATransaction.commit;
	CATransaction.flush;
#endif
	
	return SLSHWCaptureWindowListInRect(edi_cid,rsi_list,edx_count,ecx_flags,stack);
}
