// corrupted graphics in Big Sur photos

BOOL fake_deviceDisableOpenGL()
{
	return false;
}

void photosSetup()
{
	if([process isEqualToString:@"/System/Applications/Photos.app/Contents/MacOS/Photos"])
	{
		swizzleImp(@"NUGlobalSettings",@"deviceDisableOpenGL",false,(IMP)fake_deviceDisableOpenGL,NULL);
	}
}