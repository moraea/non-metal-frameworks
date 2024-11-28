// TODO: this is definitely enabling on non-TS2 gpus
// doesn't break anything since it's just the screencapture hack, but fix next time i'm on a TS2 system..

dispatch_once_t hasTS2Once;
BOOL hasTS2Value;
BOOL hasTS2()
{
	dispatch_once(&hasTS2Once,^()
	{
		CFDictionaryRef ts2Match=(CFDictionaryRef)@{@"CFBundleIdentifier":@"com.apple.kext.AMDRadeonX3000"}.retain;
		io_service_t ts2Service=IOServiceGetMatchingService(kIOMainPortDefault,ts2Match);
		hasTS2Value=ts2Service;
		IOObjectRelease(ts2Service);
	});
	
	return hasTS2Value;
}

// TODO: globally fix or disable OpenCL instead

void ts2Setup()
{
	if([process isEqualToString:@"/usr/sbin/screencapture"])
	{
		if(hasTS2())
		{
			NSUserDefaults* cmioDefaults=[NSUserDefaults.alloc initWithSuiteName:@"com.apple.cmio"];
			[cmioDefaults setBool:true forKey:@"CMIO_Unit_Input_ASC.DoNotUseOpenCL"];
			cmioDefaults.release;
		}
	}
}
