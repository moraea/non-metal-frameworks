// window borders

const double RIM_DEFAULT=0.3;

BOOL rimBetaValue;
dispatch_once_t rimBetaOnce;
BOOL rimBeta()
{
	dispatch_once(&rimBetaOnce,^()
	{
		if([[NSUserDefaults.standardUserDefaults stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"])
		{
			rimBetaValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_RimBeta"];
			//rimBetaValue=true;
		} else {
			rimBetaValue=false;
		}
		
		trace(@"ASB_RimBeta %d",rimBetaValue);
	});
	
	return rimBetaValue;
	
}

double rimOverrideValue;
dispatch_once_t rimOverrideOnce;
double rimOverride()
{
	dispatch_once(&rimOverrideOnce,^()
	{
		//rimOverrideValue=[NSUserDefaults.standardUserDefaults doubleForKey:@"ASB_RimOverride"];
		if(rimBetaValue&&[@[@"/System/Library/PrivateFrameworks/PaperKit.framework/Contents/LinkedNotesUIService.app/Contents/MacOS/LinkedNotesUIService",@"/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane/Contents/Resources/DesktopPictures.prefPane/Contents/XPCServices/com.apple.preference.desktopscreeneffect.desktop.remoteservice.xpc/Contents/MacOS/com.apple.preference.desktopscreeneffect.desktop.remoteservice",@"/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane/Contents/Resources/ScreenEffects.prefPane/Contents/XPCServices/com.apple.preference.desktopscreeneffect.screeneffects.remoteservice.xpc/Contents/MacOS/com.apple.preference.desktopscreeneffect.screeneffects.remoteservice",@"/System/Library/PrivateFrameworks/AOSUI.framework/Versions/A/XPCServices/AccountProfileRemoteViewService.xpc/Contents/MacOS/AccountProfileRemoteViewService",@"/System/Library/CoreServices/Siri.app/Contents/XPCServices/SiriNCService.xpc/Contents/MacOS/SiriNCService",@"/System/Library/PrivateFrameworks/LocalAuthenticationUI.framework/Versions/A/XPCServices/LocalAuthenticationRemoteService.xpc/Contents/MacOS/LocalAuthenticationRemoteService",@"/Applications/Blackmagic Disk Speed Test.app/Contents/MacOS/DiskSpeedTest",@"/System/iOSSupport/System/Library/PrivateFrameworks/WorkflowUI.framework/PlugIns/WidgetConfigurationExtension.appex/Contents/MacOS/WidgetConfigurationExtension"] containsObject:NSProcessInfo.processInfo.arguments[0]])
		{
			trace(@"blacklisted from fake rim");
			
			rimOverrideValue=-1;
		}
		
		trace(@"ASB_RimOverride %lf",rimOverrideValue);
	});
	
	return rimOverrideValue;
}

// TODO: refine

BOOL hasShadow(NSDictionary* properties)
{
	for(NSString* key in @[@"com.apple.WindowShadowDensity",@"com.apple.WindowShadowDensityActive",@"com.apple.WindowShadowDensityInactive"])
	{
		NSNumber* value=properties[key];
		if(value&&value.doubleValue!=0)
		{
			return true;
		}
	}
	
	return false;
}

void addFakeRim(unsigned int windowID)
{
	double lightness=RIM_DEFAULT;
	if(rimOverride()>0&&rimOverride()<=1)
	{
		lightness=rimOverride();
	}
	
	if(rimOverride()<0)
	{
		return;
	}
	
	CALayer* layer=wrapperForWindow(windowID).context.layer;
	layer.borderWidth=1;
	CGColorRef color=CGColorCreateGenericRGB(lightness,lightness,lightness,1.0);
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
	// trace(@"SLSWindowSetShadowProperties in %d %@",edi_windowID,rsi_properties);
	
	if(!rimBeta()||!hasShadow(rsi_properties))
	{
		// trace(@"SLSWindowSetShadowProperties passthrough");
		
		if(rimBeta())
		{
			removeFakeRim(edi_windowID);
		}
		
		SLSWindowSetShadowPropertie$(edi_windowID,rsi_properties);
		return;
	}
	
	// trace(@"SLSWindowSetShadowProperties override");
	
	NSMutableDictionary* newProperties=rsi_properties.mutableCopy;
	
	if([NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_DeleteRim"] == 1)
	{
		// hide rim
		newProperties[@"com.apple.WindowShadowRimDensityActive"]=@0;
		newProperties[@"com.apple.WindowShadowRimDensityInactive"]=@0;
		//rimBetaValue=true;
	}
	
	SLSWindowSetShadowPropertie$(edi_windowID,newProperties);
	
	newProperties.release;
	
	addFakeRim(edi_windowID);
}
