// auto light/dark appearance

#define SWITCH_DOMAIN @"moraea"
#define SWITCH_KEY @"switches"

NSUserDefaults* moraeaDefaults()
{
	return [NSUserDefaults.alloc initWithSuiteName:SWITCH_DOMAIN].autorelease;
}

// called in Appearance.prefPane, writes default

void SLSSetAppearanceThemeSwitchesAutomatically(BOOL edi)
{
	trace(@"SLSSetAppearanceThemeSwitchesAutomatically %d",edi);
	
	[moraeaDefaults() setBool:edi forKey:SWITCH_KEY];
}

// called below, reads default

BOOL SLSGetAppearanceThemeSwitchesAutomatically()
{
	BOOL result=[moraeaDefaults() boolForKey:SWITCH_KEY];
	
	trace(@"SLSGetAppearanceThemeSwitchesAutomatically %d",result);
	
	return result;
}

// ASentientHedgehog's reimplementation of switching

void appearanceSetup()
{
	if([process isEqualToString:@"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"])
	{
		NSDate* fire=[NSDate dateWithTimeIntervalSinceNow:5]; // time until timer start
		NSTimeInterval repeat=10; // checking interval
		NSTimer* timer=[NSTimer.alloc initWithFireDate:fire interval:repeat repeats:true block:^(NSTimer* timer)
		{
			if(!SLSGetAppearanceThemeSwitchesAutomatically()){
				return;
			}
			//get date formatted
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			    [dateFormatter setDateFormat:@"HH.mm"];
			    NSString *strCurrentTime = [dateFormatter stringFromDate:[NSDate date]];

			//if its past 6pm, dark mode - otherwise light
			if ([strCurrentTime floatValue] >= 18.00 || [strCurrentTime floatValue]  <= 6.00){
				//SLSSetAppearanceThemeLegacy(YES);
				SLSSetAppearanceThemeLegacy(YES);
		    } else{
				SLSSetAppearanceThemeLegacy(NO);
		    }
		}];
		[NSRunLoop.currentRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
	}
}