// auto light/dark appearance

#define SWITCH_DOMAIN @"moraea"
#define SWITCH_KEY @"switches"

NSUserDefaults* moraeaDefaults()
{
	return [NSUserDefaults.alloc initWithSuiteName:SWITCH_DOMAIN].autorelease;
}

//the actual auto appearance "logic"
int setAppearance(){
	//format time
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH.mm"];
	NSString *strCurrentTime = [dateFormatter stringFromDate:[NSDate date]];	
	
	if ([strCurrentTime floatValue] >= 18.00 || [strCurrentTime floatValue]  <= 6.00){
		if([[NSUserDefaults.standardUserDefaults stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"])
		{
		}
		else{
		Class Transition=NSClassFromString(@"NSGlobalPreferenceTransition");
		dispatch_async(dispatch_get_main_queue(),^()
	{
		id idOfTransition=[Transition transition];
		trace(@"%@",idOfTransition);
		[idOfTransition postChangeNotification:0 completionHandler:^(){}];
		SLSSetAppearanceThemeLegacy(YES);
		[idOfTransition waitForTransitionWithCompletionHandler:^()
		{
			return;
		}];
	});
	}
 	} else{
		if([[NSUserDefaults.standardUserDefaults stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"])
		{
		Class Transition=NSClassFromString(@"NSGlobalPreferenceTransition");
		dispatch_async(dispatch_get_main_queue(),^()
	{
		id idOfTransition=[Transition transition];
		trace(@"%@",idOfTransition);
		[idOfTransition postChangeNotification:0 completionHandler:^(){}];
		SLSSetAppearanceThemeLegacy(NO);
		[idOfTransition waitForTransitionWithCompletionHandler:^()
		{
			return;
		}];
	});
	}
 	}	
}


// called in Appearance.prefPane, writes default and immediately sets
void SLSSetAppearanceThemeSwitchesAutomatically(BOOL edi)
{
	trace(@"SLSSetAppearanceThemeSwitchesAutomatically %d",edi);
	
	[moraeaDefaults() setBool:edi forKey:SWITCH_KEY];
	
	//return if auto-appearance isn't enabled
	if (edi == 0){
		return;
	} else{
		setAppearance();
	}
}

// called below, reads default
BOOL SLSGetAppearanceThemeSwitchesAutomatically()
{
	BOOL result=[moraeaDefaults() boolForKey:SWITCH_KEY];
	
	return result;
}

// ASentientHedgehog's reimplementation of switching
void appearanceSetup()
{
	if([process isEqualToString:@"/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter"])
	{
		NSDate* fire=[NSDate dateWithTimeIntervalSinceNow:0.1]; // time until timer start
		NSTimeInterval repeat=60; // checking interval
		NSTimer* timer=[NSTimer.alloc initWithFireDate:fire interval:repeat repeats:true block:^(NSTimer* timer)
		{
			if(!SLSGetAppearanceThemeSwitchesAutomatically())
			{
				return;
			} else{
				setAppearance();
			}
		}];
		[NSRunLoop.currentRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
	}
}
