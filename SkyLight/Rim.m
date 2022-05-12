// window borders

BOOL rimBetaValue;
dispatch_once_t rimBetaOnce;
BOOL rimBeta()
{
	dispatch_once(&rimBetaOnce,^()
	{
		rimBetaValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_RimBeta"];
		if([process containsString:@"Folx.app"]||[process containsString:@".prefPane"]||[process containsString:@"Siri.app"]||[process containsString:@"PrivateFrameworks"])
		{
			rimBetaValue=0;
		}
	});
	return rimBetaValue;
}

void addFakeRim(unsigned int windowID)
{
	CALayer* layer=wrapperForWindow(windowID).context.layer;
	layer.borderWidth=1;
	CGColorRef color=CGColorCreateGenericRGB(1.0,1.0,1.0,0.2);
	layer.borderColor=color;
	CFRelease(color);
}

void removeFakeRim(unsigned int windowID)
{
	CALayer* layer=wrapperForWindow(windowID).context.layer;
	layer.borderWidth=0;
}

void SLSWindowSetShadowProperties(unsigned int edi_windowID,NSDictionary* rsi_properties)
{	
	NSNumber* value=rsi_properties[@"com.apple.WindowShadowRimStyleHardActive"];
	if(rimBeta()&&value&&value.doubleValue==1)
	{
		addFakeRim(edi_windowID);
	}
	else
	{
		removeFakeRim(edi_windowID);
	}
	SLSWindowSetShadowPropertie$(edi_windowID,rsi_properties);
}
