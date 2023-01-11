// ASentientHedgehog's workaround for AppleEnableSwipeNavigateWithScrolls based on EduCovas's discoveries, incredibly cursed but functional

void trackpadSetup()
{
	if([process isEqualToString:@"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"])
	{
		[NSDistributedNotificationCenter.defaultCenter addObserverForName:@"AppleEnableSwipeNavigateWithScrollsDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			BOOL returnValue = ((NSNumber*)note.userInfo[@"value"]).boolValue;
			if(returnValue){
				CFPreferencesSetValue((CFStringRef)@"AppleEnableMouseSwipeNavigateWithScrolls", kCFBooleanTrue, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			} else{
				CFPreferencesSetValue((CFStringRef)@"AppleEnableMouseSwipeNavigateWithScrolls", kCFBooleanFalse, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			}
		}];
	}
}
