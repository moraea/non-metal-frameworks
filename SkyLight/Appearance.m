// called in Appearance.prefPane, saves/loads the setting from defaults
// Hedge's code will run under WindowServer and read it!

// TODO: put that in

#define SWITCH_DEFAULTS @"moraea.appearance"

void SLSSetAppearanceThemeSwitchesAutomatically(BOOL edi)
{
	trace(@"SLSSetAppearanceThemeSwitchesAutomatically %d",edi);
	
	[NSUserDefaults.standardUserDefaults setBool:edi forKey:SWITCH_DEFAULTS];
}

BOOL SLSGetAppearanceThemeSwitchesAutomatically()
{
	BOOL result=[NSUserDefaults.standardUserDefaults boolForKey:SWITCH_DEFAULTS];
	
	trace(@"SLSGetAppearanceThemeSwitchesAutomatically %d",result);
	
	return result;
}