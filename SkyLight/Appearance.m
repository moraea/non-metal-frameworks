// called in Appearance.prefPane, saves/loads the setting from defaults
// Hedge's code will run under Dock and read it!

// TODO: put that in

#define SWITCH_DOMAIN @"moraea"
#define SWITCH_KEY @"switches"

NSUserDefaults* moraeaDefaults()
{
	return [NSUserDefaults.alloc initWithSuiteName:SWITCH_DOMAIN].autorelease;
}

void SLSSetAppearanceThemeSwitchesAutomatically(BOOL edi)
{
	trace(@"SLSSetAppearanceThemeSwitchesAutomatically %d",edi);
	
	[moraeaDefaults() setBool:edi forKey:SWITCH_KEY];
}


BOOL SLSGetAppearanceThemeSwitchesAutomatically()
{
	BOOL result=[moraeaDefaults() boolForKey:SWITCH_KEY];
	
	trace(@"SLSGetAppearanceThemeSwitchesAutomatically %d",result);
	
	return result;
}


void appearanceSetup()
{
	if([NSProcessInfo.processInfo.arguments[0] isEqualToString:@"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"])
	{
		NSDate* fire=[NSDate dateWithTimeIntervalSinceNow:5]; // time until timer start
		NSTimeInterval repeat=10; // checking interval
		NSTimer* timer=[NSTimer.alloc initWithFireDate:fire interval:repeat repeats:true block:^(NSTimer* timer)
		{
			//define SLSSetAppearanceThemeLegacy as boolean, get value of SLSGetAppearanceThemeSwitchesAutomatically
			void SLSSetAppearanceThemeLegacy(BOOL);
			BOOL SLSGetAppearanceThemeSwitchesAutomatically();
		
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