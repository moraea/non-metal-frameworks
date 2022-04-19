// keyboard backlight

#define BACKLIGHT_INTERVAL 0.5
#define BACKLIGHT_MAX 30
#define BACKLIGHT_AFTER 10

BOOL CBALCKeyboardFeatureAvailable();

BOOL keyboardBetaValue;
dispatch_once_t keyboardBetaOnce;
BOOL keyboardBeta()
{
	dispatch_once(&keyboardBetaOnce,^()
	{
		keyboardBetaValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_BacklightHack"];
		
		trace(@"backlight: Moraea_BacklightHack %d",keyboardBetaValue);
	});
	
	return keyboardBetaValue;
}

BOOL fake_CBALCKeyboardFeatureAvailable()
{
	trace(@"backlight: fake_CBALCKeyboardFeatureAvailable");
	
	if(isWindowServer&&keyboardBeta())
	{
		for(NSTimeInterval wait=0;wait<BACKLIGHT_MAX;wait+=BACKLIGHT_INTERVAL)
		{
			if(CBALCKeyboardFeatureAvailable())
			{
				trace(@"backlight: als-lgp-version appeared");
				[NSThread sleepForTimeInterval:BACKLIGHT_AFTER];
				
				return true;
			}
			
			trace(@"backlight: sleeping (%lf)",wait);
			[NSThread sleepForTimeInterval:BACKLIGHT_INTERVAL];
		}
		
		trace(@"backlight: giving up");
	}
	
	trace(@"backlight: passing through");
	
	return CBALCKeyboardFeatureAvailable();
}

DYLD_INTERPOSE(fake_CBALCKeyboardFeatureAvailable,CBALCKeyboardFeatureAvailable)