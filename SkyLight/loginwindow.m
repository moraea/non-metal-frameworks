// no clue what's happening

id fake_invalidate()
{
	return nil;
}

void loginwindowSetup()
{
	if([process isEqualToString:@"/System/Library/CoreServices/loginwindow.app/Contents/MacOS/loginwindow"])
	{
		swizzleImp(@"NSMachPort",@"invalidate",true,(IMP)fake_invalidate,NULL);
	}
}