// auto light/dark appearance

#define SWITCH_DOMAIN @"moraea"
#define SWITCH_KEY @"switches"
BOOL SLSGetAppearanceThemeLegacy();

NSUserDefaults* moraeaDefaults()
{
	return [NSUserDefaults.alloc initWithSuiteName:SWITCH_DOMAIN].autorelease;
}

void setAppearance()
{
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wobjc-method-access"
	Class Transition=NSClassFromString(@"NSGlobalPreferenceTransition");
	dispatch_async(dispatch_get_main_queue(),^()
	{
		if(!SLSGetAppearanceThemeLegacy())
		{
			SLSSetAppearanceThemeLegacy(YES);
		}
		else
		{
			SLSSetAppearanceThemeLegacy(NO);
		}
		id idOfTransition=[Transition transition];
		[idOfTransition postChangeNotification:0 completionHandler:^(){}];
		
		if([idOfTransition respondsToSelector:@selector(waitForTransitionWithCompletionHandler:)])
		{
			[idOfTransition waitForTransitionWithCompletionHandler:^()
			{
			}];
		}
	});
	#pragma clang diagnostic pop
}

void checkMode(){

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH.mm"];
	NSString *strCurrentTime = [dateFormatter stringFromDate:[NSDate date]];	
	
	if([strCurrentTime floatValue] >= 18.00 || [strCurrentTime floatValue]  <= 6.00){
		if(!SLSGetAppearanceThemeLegacy()){
			setAppearance();
		}
 	} 
	else{
		if(SLSGetAppearanceThemeLegacy()){
			setAppearance();
		}
 	}
	[dateFormatter release];
}

// Writes default and immediately sets
void SLSSetAppearanceThemeSwitchesAutomatically(BOOL edi)
{	
	[moraeaDefaults() setBool:edi forKey:SWITCH_KEY];
	
	//return if auto-appearance isn't enabled
	if (edi == 0)
	{
		return;
	} 
	else
	{
		checkMode();
	}
}

// Reads default
BOOL SLSGetAppearanceThemeSwitchesAutomatically()
{
	BOOL result=[moraeaDefaults() boolForKey:SWITCH_KEY];
	
	return result;
}

// ASentientHedgehog's timer
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
			}
			else
			{
				checkMode();
			}
		}];
		[NSRunLoop.currentRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
	}
}
