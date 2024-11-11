// new menu bar hacks (proper selections, auto text color)
// TODO: test thoroughly, then enable by default, then replace MenuBar entirely
// TODO: black bar background on fullscreen windows

#define MENUBAR_DARK_FORMAT @"Amy.MenuBar2.DarkText.%d"
#define MENUBAR_DARK_NOTE @"Amy.MenuBar2.DarkTextChanged"
#define MENUBAR_KEY_BETA @"Amy.MenuBar2Beta"
#define MENUBAR_NOTE_2 @"DO IT"

CGImageRef (*soft_CGWindowListCreateImageFromArray)(CGRect,CFArrayRef,CGWindowImageOption);

// forward Rim.m

void SLSWindowSetShadowProperties(unsigned int,NSDictionary*);

// cheat at shared state using the session storage

NSString* menuBar2KeyWithDisplay(int display)
{
	return [NSString stringWithFormat:MENUBAR_DARK_FORMAT,display];
}

void menuBar2WriteDark(BOOL value,int display)
{
	NSMutableDictionary* dict=((NSMutableDictionary*)SLSCopyCurrentSessionDictionary().autorelease.mutableCopy).autorelease;
	dict[menuBar2KeyWithDisplay(display)]=[NSNumber numberWithBool:value];
	SLSSetDictionaryForCurrentSession(dict);
}

BOOL keepTransparencyValue;
dispatch_once_t keepTransparencyOnce;
BOOL menuBar2KeepTransparency()
{
	if(_AXInterfaceGetReduceTransparencyEnabled()||_AXInterfaceGetIncreaseContrastEnabled())
	{
		dispatch_once(&keepTransparencyOnce,^()
		{
			keepTransparencyValue=[NSUserDefaults.standardUserDefaults boolForKey:@"MB2_KeepTransparency"];
		});
	
		return keepTransparencyValue;
	}
	
	return true;
}

BOOL menuBar2ReadDark(int display)
{
	if(!menuBar2KeepTransparency())
	{
		// SLSGetAppearanceThemeLegacy true = dark
		
		return !SLSGetAppearanceThemeLegacy();
	}
	
	// TODO: cache, only update when receiving notification
	
	NSDictionary* dict=SLSCopyCurrentSessionDictionary().autorelease;
	return ((NSNumber*)dict[menuBar2KeyWithDisplay(display)]).boolValue;
}

BOOL useMenuBar2Value;
dispatch_once_t useMenuBar2Once;
BOOL useMenuBar2()
{
	dispatch_once(&useMenuBar2Once,^()
	{
		useMenuBar2Value=[NSUserDefaults.standardUserDefaults boolForKey:MENUBAR_KEY_BETA];
	});
	
	return useMenuBar2Value;
}

void menuBar2ConfigurePillLayer(CALayer* layer,BOOL dark)
{
	CGColorRef color;
	if(dark)
	{
		color=CGColorCreateGenericRGB(0,0,0,MENUBAR_PILL_ALPHA_DARK);
	}
	else
	{
		color=CGColorCreateGenericRGB(1,1,1,MENUBAR_PILL_ALPHA_LIGHT);
	}
	layer.backgroundColor=color;
	CFRelease(color);
	layer.cornerCurve=kCACornerCurveContinuous;
	layer.cornerRadius=MENUBAR_PILL_RADIUS;
}

NSMutableArray<NSMutableDictionary*>* menuBar2ArrayCache=nil;
NSMutableDictionary* menuBar2DictCache=nil;

NSMutableDictionary<NSNumber*,NSNumber*>* menuBar2Wids;
NSMutableDictionary<NSNumber*,NSObject*>* menuBar2Contexts;

void menuBar2SendCached()
{
	if(!menuBar2ArrayCache)
	{
		return;
	}

	int cid=SLSMainConnectionID();
	
	// prevent black background
	
	menuBar2DictCache[kCGMenuBarActiveMaterialKey]=@"Light";
	
	// prevent blue material selection (Big Sur)
	
	menuBar2DictCache[kCGMenuBarTitleMaterialKey]=nil;
	
	for(NSMutableDictionary* bar in menuBar2ArrayCache)
	{
		// a hack. Big Sur uses the old keys when Reduce Transparency is on
		
		if(!bar[kSLMenuBarImageWindowDarkKey])
		{
			bar[kSLMenuBarImageWindowDarkKey]=bar[kCGMenuBarImageWindowKey];
			bar[kSLMenuBarImageWindowLightKey]=bar[kCGMenuBarImageWindowKey];
			bar[kSLMenuBarInactiveImageWindowDarkKey]=bar[kCGMenuBarInactiveImageWindowKey];
			bar[kSLMenuBarInactiveImageWindowLightKey]=bar[kCGMenuBarInactiveImageWindowKey];
		}
		
		int aWid=((NSNumber*)bar[kSLMenuBarImageWindowDarkKey]).intValue;
		
		CGRect aRect=CGRectZero;
		SLSGetWindowBounds(SLSMainConnectionID(),aWid,&aRect);
		
		unsigned int display=-1;
		unsigned int displayCount=0;
		CGGetDisplaysWithRect(aRect,1,&display,&displayCount);
		if(display==-1||displayCount!=1)
		{
			display=CGMainDisplayID();
			trace(@"MenuBar2 (client): failed finding display for rect %@, count %d, fallback %d, bar: %@",NSStringFromRect(aRect),displayCount,display,bar);
		}
		
		// trace(@"MenuBar2 (client): got display %d for rect %@",display,NSStringFromRect(aRect));
		
		NSNumber* key=key=[NSNumber numberWithInt:display];
		BOOL displayDark=menuBar2ReadDark(key.intValue);
		
		int realWid=((NSNumber*)bar[displayDark?kSLMenuBarImageWindowDarkKey:kSLMenuBarImageWindowLightKey]).intValue;
		CGContextRef realContext=SLWindowContextCreate(SLSMainConnectionID(),realWid,0);
		CGImageRef realImage=SLWindowContextCreateImage(realContext);
		CFRelease(realContext);
		
		CGRect realRect=CGRectMake(0,0,CGImageGetWidth(realImage),CGImageGetHeight(realImage));
		
		int fakeWid;
		CGContextRef fakeContext;
		if(menuBar2Wids[key])
		{
			fakeWid=menuBar2Wids[key].intValue;
			fakeContext=(CGContextRef)menuBar2Contexts[key];
		}
		else
		{
			void* realRegion;
			CGSNewRegionWithRect(&realRect,&realRegion);
			SLSNewWindow(cid,2,realRegion,&fakeWid,0,0);
			CFRelease(realRegion);
			SLSSetWindowOpacity(cid,fakeWid,false);
			
			fakeContext=SLWindowContextCreate(cid,fakeWid,NULL);
			
			menuBar2Wids[key]=[NSNumber numberWithInt:fakeWid];
			menuBar2Contexts[key]=(NSObject*)fakeContext;
			CFRelease(fakeContext);
		}
		
		if(displayDark)
		{
			SLSWindowSetShadowProperties(fakeWid,@{});
		}
		else
		{
			// values from NSStatusBarContentView setHasCAShadow:
			// TODO: with greyLayer, ofc this doesn't work...
			
			SLSWindowSetShadowProperties(fakeWid,@{@"com.apple.WindowShadowRadiusInactive":@2.5,@"com.apple.WindowShadowDensityInactive":@0.3,@"com.apple.WindowShadowVerticalOffsetInactive":@1.75});
		}
		
		CGContextClearRect(fakeContext,realRect);
		
		if(!menuBar2KeepTransparency())
		{
			CALayer* greyLayer=CALayer.layer;
			greyLayer.bounds=realRect;
			
			// Digital Color Meter-ed on M1 Air lol
			
			CGColorRef greyColor;
			if(_AXInterfaceGetIncreaseContrastEnabled())
			{
				if(SLSGetAppearanceThemeLegacy())
				{
					// yes, this is backwards (IC results in lower contrast than RT)
					// this is Apple's mistake and i am just mimicking it
					
					greyColor=CGColorCreateGenericRGB(0.175,0.175,0.175,1);
				}
				else
				{
					greyColor=CGColorCreateGenericRGB(0.9,0.9,0.9,1);
				}
			}
			else
			{
				if(SLSGetAppearanceThemeLegacy())
				{
					greyColor=CGColorCreateGenericRGB(0.125,0.125,0.125,1);
				}
				else
				{
					greyColor=CGColorCreateGenericRGB(0.85,0.85,0.85,1);
				}
			}
			greyLayer.backgroundColor=greyColor;
			CFRelease(greyColor);
			
			[greyLayer renderInContext:fakeContext];
		}
		
		NSArray<NSData*>* titles=bar[kCGMenuBarMenuTitlesArrayKey];
		for(NSData* title in titles)
		{
			CALayer* layer=CALayer.layer;
			layer.bounds=*(CGRect*)title.bytes;
			
			menuBar2ConfigurePillLayer(layer,displayDark);
			
			[layer renderInContext:fakeContext];
		}
		
		CGContextDrawImage(fakeContext,realRect,realImage);
		CFRelease(realImage);
		
		CGContextFlush(fakeContext);
		
		bar[kCGMenuBarImageWindowKey]=[NSNumber numberWithInt:fakeWid];
		bar[kCGMenuBarInactiveImageWindowKey]=bar[displayDark?kSLMenuBarInactiveImageWindowDarkKey:kSLMenuBarInactiveImageWindowLightKey];
	}
	
	SLSSetMenuBar$(cid,menuBar2ArrayCache,menuBar2DictCache);
}

int menuBar2Set(int edi_cid,NSMutableArray<NSMutableDictionary*>* rsi_array,NSMutableDictionary* rdx_dict)
{
	if(menuBar2ArrayCache)
	{
		menuBar2ArrayCache.release;
		menuBar2DictCache.release;
	}
	
	menuBar2ArrayCache=rsi_array.retain;
	menuBar2DictCache=rdx_dict.retain;
	
	menuBar2SendCached();
	
	return 0;
}

void menuBar2DockRecalculate2()
{
	int cid=SLSMainConnectionID();
	
	CFArrayRef windows=CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly,kCGNullWindowID);
	
	for(int index=0;index<CFArrayGetCount(windows);index++)
	{
		NSDictionary* info=(NSDictionary*)CFArrayGetValueAtIndex(windows,index);
		
		int pid=((NSNumber*)info[(NSString*)kCGWindowOwnerPID]).intValue;
		if(pid!=getpid())
		{
			continue;
		}
		
		NSString* name=info[(NSString*)kCGWindowName];
		if(![name containsString:@"Wallpaper"]&&![name containsString:@"Desktop Picture"])
		{
			continue;
		}
		
		CGRect rect;
		if(!CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)info[(NSString*)kCGWindowBounds],&rect))
		{
			trace(@"MenuBar2 (server): failed parsing rect, info %@",info);
			continue;
		}
		
		unsigned int display;
		unsigned int displayCount=0;
		if(CGGetDisplaysWithRect(rect,1,&display,&displayCount)!=kCGErrorSuccess)
		{
			trace(@"MenuBar2 (server): error matching display, info %@",info);
			continue;
		}
		if(displayCount!=1)
		{
			trace(@"MenuBar2 (server): matched the wrong amount (%d) of displays, info %@",displayCount,info);
			continue;
		}
		CGRect displayRect=CGDisplayBounds(display);
		if(!CGRectEqualToRect(displayRect,rect))
		{
			trace(@"MenuBar2 (server): matched display %d, but bounds %@ ≠ wallpaper bounds %@",display,NSStringFromRect(displayRect),NSStringFromRect(rect));
			continue;
		}
		
		int wid=((NSNumber*)info[(NSString*)kCGWindowNumber]).intValue;
		
		long longWid=wid;
		CFArrayRef array=CFArrayCreate(NULL,(const void**)&longWid,1,NULL);
		CGImageRef screenshot=soft_CGWindowListCreateImageFromArray(rect,array,kCGWindowImageDefault);
		if(!screenshot)
		{
			trace(@"MenuBar2 (server): failed capturing screenshot for wid %d",wid);
			continue;
		}
		
		CFRelease(array);
		
		NSData* data=(NSData*)CGDataProviderCopyData(CGImageGetDataProvider(screenshot));
		if(!data)
		{
			trace(@"MenuBar2 (server): failed copying image data");
			continue;
		}
		
		// TODO: will break on some displays?
		
		int bytesPerPixel=CGImageGetBitsPerPixel(screenshot)/8;
		if(bytesPerPixel!=4)
		{
			trace(@"MenuBar2 (server): screenshot %@ unexpected bpp %d",screenshot,bytesPerPixel);
			continue;
		}
		
		int width=CGImageGetWidth(screenshot);
		if(CGImageGetHeight(screenshot)<MENUBAR_HEIGHT)
		{
			trace(@"MenuBar2 (server): screenshot %@ too short",screenshot);
			continue;
		}
		
		CFRelease(screenshot);
		
		long redSum=0;
		long greenSum=0;
		long blueSum=0;
		
		int* pixels=(int*)data.bytes;
		for(int index=0;index<MENUBAR_HEIGHT*width;index++)
		{
			long pixel=pixels[index];
			redSum+=(pixel>>16)&0xff;
			greenSum+=(pixel>>8)&0xff;
			blueSum+=pixel&0xff;
		}
		
		data.release;
		
		int redMean=redSum/MENUBAR_HEIGHT/width;
		int greenMean=greenSum/MENUBAR_HEIGHT/width;
		int blueMean=blueSum/MENUBAR_HEIGHT/width;
		
		// TODO: doesn't quite match Metal still...
		
		float brightness=(LUMINANCE_RED*redMean+LUMINANCE_GREEN*greenMean+LUMINANCE_BLUE*blueMean)/0xff;
		BOOL darkText=brightness>MENUBAR_WALLPAPER_THRESHOLD;
		
		trace(@"MenuBar2 (server): calculated brightness %f, display %d, dark text %d",brightness,display,darkText);
		
		menuBar2WriteDark(darkText,display);
	}
	
	CFRelease(windows);
	
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
}

void menuBar2DockReduceTransparencyCallback(CFNotificationCenterRef center,void* observer,CFNotificationName name,const void* object,CFDictionaryRef userInfo)
{
	trace(@"MenuBar2 (server): forwarding Reduce Transparency/Increase Contrast to clients");
	
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
}

void menuBar2DockAppearanceCallback(CFNotificationCenterRef center,void* observer,CFNotificationName name,const void* object,CFDictionaryRef userInfo)
{
	if(!menuBar2KeepTransparency())
	{
		trace(@"MenuBar2 (server): forwarding appearance toggle to clients because Reduce Transparency/Increase Contrast is on");
		
		[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
	}
}

id (*real_EWC)(id,SEL,id);
id fake_EWC(id self,SEL sel,id coder)
{
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_NOTE_2 object:nil userInfo:nil deliverImmediately:true];
	
	return real_EWC(self,sel,coder);;
}

void recalculateAfterFade()
{
	// TODO: handle the fade time in auto changing wallpapers... not ideal
			
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW,MENUBAR_WALLPAPER_DELAY*NSEC_PER_SEC),dispatch_get_main_queue(),^()
	{
		menuBar2DockRecalculate2();
	});
}

void menuBar2UnconditionalSetup()
{
	if(earlyBoot)
	{
		return;
	}
	
	if(isWindowServer)
	{
		return;
	}
	
	if(!useMenuBar2())
	{
		return;
	}
	
	// we used to link this directly, but it's marked unavailable for 15+ in CGWindow.h
	// because Foundation imports CoreGraphics, i don't how how to work around this with #define?
	// im almost certainly missing something.. -A
	
	soft_CGWindowListCreateImageFromArray=dlsym(RTLD_DEFAULT,"CGWindowListCreateImageFromArray");
	
	if([process containsString:@"WallpaperAgent.app"])
	{
		swizzleImp(@"WallpaperIDXPC",@"encodeWithCoder:",true,(IMP)fake_EWC,(IMP*)&real_EWC);
		return;
	}
	
	if([process containsString:@"Dock.app/Contents/MacOS/Dock"])
	{
		// Ventura
		
		[NSNotificationCenter.defaultCenter addObserverForName:@"desktoppicturechanged" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			recalculateAfterFade();
		}];
		
		// Sonoma
		
		[NSDistributedNotificationCenter.defaultCenter addObserverForName:MENUBAR_NOTE_2 object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			recalculateAfterFade();
		}];
		
		recalculateAfterFade();
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),NULL,menuBar2DockReduceTransparencyCallback,CFSTR("AXInterfaceReduceTransparencyStatusDidChange"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),NULL,menuBar2DockReduceTransparencyCallback,CFSTR("AXInterfaceIncreaseContrastStatusDidChange"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),NULL,menuBar2DockAppearanceCallback,CFSTR("AppleInterfaceThemeChangedNotification"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
		
		return;
	}
	
	menuBar2Wids=NSMutableDictionary.alloc.init;
	menuBar2Contexts=NSMutableDictionary.alloc.init;
	
	[NSDistributedNotificationCenter.defaultCenter addObserverForName:MENUBAR_DARK_NOTE object:nil queue:nil usingBlock:^(NSNotification* note)
	{
		menuBar2SendCached();
		
		// TODO: hack to avoid code duplication with MB1
		
		statusBarSpaceCallback();
	}];
}

// TODO: a lot of code duplication, but only until MB2 replaces MB1

NSDictionary* menuBar2CopyMetrics()
{
	NSMutableDictionary* result=NSMutableDictionary.alloc.init;
	
	NSString* activeID=SLSCopyActiveMenuBarDisplayIdentifier(SLSMainConnectionID());
	result[@"activeDisplayIdentifier"]=activeID;
	activeID.release;
	
	int count;
	SLSGetDisplayList(0,NULL,&count);
	int* ids=malloc(sizeof(int)*count);
	SLSGetDisplayList(count,ids,&count);
	
	NSMutableArray<NSDictionary*>* displays=NSMutableArray.alloc.init;
	
	for(int index=0;index<count;index++)
	{
		NSMutableDictionary* display=NSMutableDictionary.alloc.init;
		
		NSNumber* appearance=menuBar2ReadDark(ids[index])?@0:@1;
		display[@"appearances"]=@[appearance];
		display[@"currentAppearance"]=appearance;
		
		CFUUIDRef uuid;
		SLSCopyDisplayUUID(ids[index],&uuid);
		NSString* uuidString=(NSString*)CFUUIDCreateString(NULL,uuid);
		CFRelease(uuid);
		display[@"identifier"]=uuidString;
		uuidString.release;
		
		[displays addObject:display];
		display.release;
	}
	
	free(ids);
	
	result[@"displays"]=displays;
	displays.release;
	
	// don't autorelease because *Copy*
	
	return result;
}

void menuBar2SetRightSideSelection(void* rdi_transaction,int esi_wid,CGRect stack_rect)
{
	CALayer* layer=wrapperForWindow(esi_wid).context.layer;
	
	CATransaction.begin;
	CATransaction.animationDuration=0;
	if(NSIsEmptyRect(stack_rect))
	{
		layer.backgroundColor=CGColorGetConstantColor(kCGColorClear);
	}
	else
	{
		CGRect frame=CGRectZero;
		SLSGetWindowBounds(SLSMainConnectionID(),esi_wid,&frame);
		int display=0;
		int count=0;
		SLSGetDisplaysWithRect(&frame,1,&display,&count);
		
		menuBar2ConfigurePillLayer(layer,menuBar2ReadDark(display));
	}
	CATransaction.commit;
}
