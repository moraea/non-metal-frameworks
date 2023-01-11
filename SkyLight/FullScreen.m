// credit EduCovas - implementation is required for fullscreen animation
// AppKit "screenshots" the window to animate smoothly, similar to light/dark transition

// 13.1 DP3 SkyLight - functions are wrappers around hw_capture_window_list_common
// same except for r8d zeroed in SLSHWCaptureWindowListInRect

// 13.1 DP3 AppKit 4ff80407bea9
// edi cid
// rsi pointer to some unsigned int
// edx 1 - likely count
// ecx 0x10900
// pushes likely CGRect on the stack
// returns rax

// 4ff804092b8a
// edi - same as passed to SLSHWCaptureWindowListInRectWithSeed
// rsi - same
// edx - same
// ecx - same
// stack - same

// 10.13.6 AppKit 91dcc9
// edi cid
// rsi list
// rcx flags - 0x2901 in this case
// stack rect

// TODO: working around a Renamer bug

#if MAJOR>=13

NSArray* SLSHWCaptureWindowLis$InRect(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,CGRect stack);
NSArray* SLSHWCaptureWindowListInRect(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,CGRect stack)
{
	return SLSHWCaptureWindowLis$InRect(edi_cid,rsi_list,edx_count,ecx_flags,stack);
}

#else

void* SLSHWCaptureWindowListInRect(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,CGRect stack);

#endif

void* SLSHWCaptureWindowListInRectWithSeed(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,int r8,CGRect stack)
{
	// i think *WithSeed is supposed to snapshot the window with the current in-progress transaction
	// but i have no idea how to do that, and this works
	// (otherwise the snapshot used for the animation looks a bit weird)
	
	CATransaction.commit;
	CATransaction.flush;
	
	return SLSHWCaptureWindowListInRect(edi_cid,rsi_list,edx_count,ecx_flags,stack);
}