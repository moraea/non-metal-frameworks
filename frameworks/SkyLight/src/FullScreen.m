// credit EduCovas - implementation is required for fullscreen animation
// AppKit "screenshots" the window to animate smoothly, similar to light/dark transition

NSArray* SLSHWCaptureWindowList(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags)
{
	NSArray* result=SLSHWCaptureWindowLis$(edi_cid,rsi_list,edx_count,ecx_flags);

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 130000
	uninvertScreenshots(result);
#endif
	
	return result;
}

NSArray* SLSHWCaptureWindowListInRect(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,CGRect stack)
{
	// trace(@"SLSHWCaptureWindowListInRect flags %x",ecx_flags);
	
	// TODO: hack, not sure why AppKit is messing up the flags
	// works, but we might sometimes want others... look at this again soon
	
	#define SHADOW 1
	#define JUST_WINDOW 8
	
	if(ecx_flags&SHADOW)
	{
		ecx_flags=SHADOW|JUST_WINDOW;
	}
	else
	{
		ecx_flags=0;
	}
	
	NSArray* result=SLSHWCaptureWindowLis$InRect(edi_cid,rsi_list,edx_count,ecx_flags,stack);

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 130000
	uninvertScreenshots(result);
#endif

	return result;
}

NSArray* SLSHWCaptureWindowListInRectWithSeed(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,int r8,CGRect stack)
{
	// i think *WithSeed is supposed to snapshot the window with the current in-progress transaction
	// but i have no idea how to do that, and this works
	// (otherwise the snapshot used for the animation looks a bit weird)
	
	CATransaction.commit;
	CATransaction.flush;
	
	return SLSHWCaptureWindowListInRect(edi_cid,rsi_list,edx_count,ecx_flags,stack);
}