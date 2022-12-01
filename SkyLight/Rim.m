// window borders

BOOL rimBetaDisabledValue;
dispatch_once_t rimBetaOnce;
BOOL rimBetaDisabled()
{
	dispatch_once(&rimBetaDisabledOnce,^()
	{
		rimBetaDisabledValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_RimBetaDisabled"];
		if([process containsString:@"Folx.app"]||[process containsString:@"Blackmagic Disk Speed Test.app"]||[process containsString:@".prefPane"]||[process containsString:@"Siri.app"]||[process containsString:@"PrivateFrameworks"]||[process containsString:@"Simulator.app"])
		{
			rimBetaDisabledValue=1;
		}
	});
	return rimBetaDisabledValue;
}

void addFakeRim(unsigned int windowID)
{
	CALayer* layer=wrapperForWindow(windowID).context.layer;
	layer.borderWidth=1;
	layer.cornerRadius=10;
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
	if(rimBetaDisabled()==0&&value&&value.doubleValue==1)
	{
		addFakeRim(edi_windowID);
	}
	else
	{
		removeFakeRim(edi_windowID);
	}
	NSMutableDictionary* newProperties=rsi_properties.mutableCopy;
	
	newProperties[@"com.apple.WindowShadowInnerRimDensityActive"]=@0;
	newProperties[@"com.apple.WindowShadowInnerRimDensityInactive"]=@0;
	
	SLSWindowSetShadowPropertie$(edi_windowID,newProperties);
	
	newProperties.release;
}

