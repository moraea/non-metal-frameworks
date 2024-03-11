// no clue what's happening

id fake_invalidate()
{
	return nil;
}


id (*real_information)(id,SEL,int);

id fake_information(id rdi_self,SEL rsi_sel,int edx_pid)
{
	if(edx_pid==0)
	{
		// bruh

		edx_pid=getpid();
	}

	return real_information(rdi_self,rsi_sel,edx_pid);
}

void loginwindowSetup()
{
	if([process isEqualToString:@"/System/Library/CoreServices/loginwindow.app/Contents/MacOS/loginwindow"])
	{
		swizzleImp(@"NSMachPort",@"invalidate",true,(IMP)fake_invalidate,NULL);
		swizzleImp(@"PKManager",@"informationForPlugInWithPid:",true,(IMP)fake_information,(IMP*)&real_information);
	}
}