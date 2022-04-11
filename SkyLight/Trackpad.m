// ASentientHedgehog's workaround for AppleEnableSwipeNavigateWithScrolls based on EduCovas's discoveries, incredibly cursed but functional

void trackpadSetup()
{
	if([process isEqualToString:@"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"])
	{
		[NSDistributedNotificationCenter.defaultCenter addObserverForName:@"AppleEnableSwipeNavigateWithScrollsDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			NSValue *returnValue = ((NSNumber*)note.userInfo[@"value"]).boolValue;
			if(returnValue){
				CFPreferencesSetValue(@"AppleEnableMouseSwipeNavigateWithScrolls", kCFBooleanTrue, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			} else{
				CFPreferencesSetValue(@"AppleEnableMouseSwipeNavigateWithScrolls", kCFBooleanFalse, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			}
		}];
	}
}
