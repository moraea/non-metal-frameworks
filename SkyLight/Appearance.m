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