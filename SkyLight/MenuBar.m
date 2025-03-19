// MARK: defaults and dark state

BOOL menuBarManualDark()
{
	return [NSUserDefaults.standardUserDefaults boolForKey:@"Moraea.MenuBar.DarkText"]||[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_DarkMenuBar"];
}

BOOL menuBarAutoDarkEnabled()
{
	return [NSUserDefaults.standardUserDefaults boolForKey:@"Moraea.MenuBar2Beta"]||[NSUserDefaults.standardUserDefaults boolForKey:@"Amy.MenuBar2Beta"];
}

NSString* menuBarAutoDarkKeyWithDisplay(int display)
{
	return [NSString stringWithFormat:@"Moraea.MenuBar2.DarkText.%d",display];
}

void menuBarAutoDarkWrite(BOOL value,int display)
{
	NSMutableDictionary* dict=((NSMutableDictionary*)SLSCopyCurrentSessionDictionary().autorelease.mutableCopy).autorelease;
	dict[menuBarAutoDarkKeyWithDisplay(display)]=[NSNumber numberWithBool:value];
	SLSSetDictionaryForCurrentSession(dict);
}

BOOL menuBarKeepTransparency()
{
	if(_AXInterfaceGetReduceTransparencyEnabled()||_AXInterfaceGetIncreaseContrastEnabled())
	{
		return [NSUserDefaults.standardUserDefaults boolForKey:@"MB2_KeepTransparency"];
	}
	
	return true;
}

BOOL menuBarAutoDarkRead(int display)
{
	if(!menuBarAutoDarkEnabled())
	{
		return menuBarManualDark();
	}
	
	if(!menuBarKeepTransparency())
	{
		// SLSGetAppearanceThemeLegacy true = dark
		
		return !SLSGetAppearanceThemeLegacy();
	}
	
	NSDictionary* dict=SLSCopyCurrentSessionDictionary().autorelease;
	return ((NSNumber*)dict[menuBarAutoDarkKeyWithDisplay(display)]).boolValue;
}

// MARK: right side shims

void SLSTransactionSystemStatusBarRegisterSortedWindow(unsigned long rdi_transaction,unsigned int esi_windowID,unsigned int edx_priority,unsigned long rcx_displayID,unsigned int r8d_flags,unsigned int r9d_insertOrder,float xmm0_preferredPosition,unsigned int stack_appearance)
{
	unsigned int connection=SLSMainConnectionID();
	
	// TODO: null space ID
	
	SLSSystemStatusBarRegisterSortedWindow(connection,esi_windowID,edx_priority,0,rcx_displayID,r8d_flags,xmm0_preferredPosition);
	SLSAdjustSystemStatusBarWindows(connection);
}

// greyed copies on inactive display

void SLSTransactionSystemStatusBarRegisterReplicantWindow(unsigned long rdi_transaction,unsigned int esi_windowID,unsigned int edx_parent,unsigned long rcx_displayID,unsigned int r8d_flags,unsigned int r9d_appearance)
{
	unsigned int connection=SLSMainConnectionID();
	SLSSystemStatusBarRegisterReplicantWindow(connection,esi_windowID,edx_parent,rcx_displayID,r8d_flags);
	SLSAdjustSystemStatusBarWindows(connection);
}

void SLSTransactionSystemStatusBarUnregisterWindow(unsigned long rdi_transaction,unsigned int esi_windowID)
{
	unsigned int connection=SLSMainConnectionID();
	SLSUnregisterWindowWithSystemStatusBar(connection,esi_windowID);
	SLSOrderWindow(connection,esi_windowID,0,0);
	SLSAdjustSystemStatusBarWindows(connection);
}

// shared pill drawing between left and right

void menuBarConfigurePillLayer(CALayer* layer,BOOL dark)
{
	CGColorRef color;
	if(dark)
	{
		color=CGColorCreateGenericRGB(0,0,0,0.1);
	}
	else
	{
		color=CGColorCreateGenericRGB(1,1,1,0.25);
	}
	layer.backgroundColor=color;
	CFRelease(color);
	layer.cornerCurve=kCACornerCurveContinuous;
	layer.cornerRadius=4;
}

// right side selections

void SLSTransactionSystemStatusBarSetSelectedContentFrame(void* rdi_transaction,int esi_wid,CGRect stack_rect)
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
		
		menuBarConfigurePillLayer(layer,menuBarAutoDarkRead(display));
	}
	CATransaction.commit;
}

// replicants and appearance

NSDictionary* SLSCopySystemStatusBarMetrics()
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
		
		NSNumber* appearance=menuBarAutoDarkRead(ids[index])?@0:@1;
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

// MARK: left side shims

// auto-generated work in Monterey, but hardcoded elsewhere without "Key" suffix in Big Sur

const NSString* kSLMenuBarImageWindowDarkKey=@"kSLMenuBarImageWindowDark";
const NSString* kSLMenuBarImageWindowLightKey=@"kSLMenuBarImageWindowLight";
const NSString* kSLMenuBarInactiveImageWindowDarkKey=@"kSLMenuBarInactiveImageWindowDark";
const NSString* kSLMenuBarInactiveImageWindowLightKey=@"kSLMenuBarInactiveImageWindowLight";

NSMutableArray<NSMutableDictionary*>* menuBarArrayCache=nil;
NSMutableDictionary* menuBarDictCache=nil;
NSMutableDictionary<NSNumber*,NSNumber*>* menuBarWids;
NSMutableDictionary<NSNumber*,NSObject*>* menuBarContexts;

// forward Rim.m

void SLSWindowSetShadowProperties(unsigned int,NSDictionary*);

void menuBarSendCached()
{
	if(!menuBarArrayCache)
	{
		return;
	}

	int cid=SLSMainConnectionID();
	
	// prevent black background
	
	menuBarDictCache[kCGMenuBarActiveMaterialKey]=@"Light";
	
	// prevent blue material selection (Big Sur)
	
	menuBarDictCache[kCGMenuBarTitleMaterialKey]=nil;
	
	for(NSMutableDictionary* bar in menuBarArrayCache)
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
		BOOL displayDark=menuBarAutoDarkRead(key.intValue);
		
		int realWid=((NSNumber*)bar[displayDark?kSLMenuBarImageWindowDarkKey:kSLMenuBarImageWindowLightKey]).intValue;
		CGContextRef realContext=SLWindowContextCreate(SLSMainConnectionID(),realWid,0);
		if(!realContext)
		{
			// trying to release this when NULL crashed talagent on ventura after OTA?
			
			trace(@"MenuBar2 (client): failed SLWindowContextCreate real, giving up");
			return;
		}
		CGImageRef realImage=SLWindowContextCreateImage(realContext);
		CFRelease(realContext);
		
		if(!realImage)
		{
			trace(@"MenuBar2 (client): failed SLWindowContextCreateImage real, giving up");
			return;
		}
		
		CGRect realRect=CGRectMake(0,0,CGImageGetWidth(realImage),CGImageGetHeight(realImage));
		
		int fakeWid;
		CGContextRef fakeContext;
		if(menuBarWids[key])
		{
			fakeWid=menuBarWids[key].intValue;
			fakeContext=(CGContextRef)menuBarContexts[key];
		}
		else
		{
			void* realRegion;
			CGSNewRegionWithRect(&realRect,&realRegion);
			SLSNewWindow(cid,2,realRegion,&fakeWid,0,0);
			CFRelease(realRegion);
			SLSSetWindowOpacity(cid,fakeWid,false);
			
			fakeContext=SLWindowContextCreate(cid,fakeWid,NULL);
			
			if(!fakeContext)
			{
				trace(@"MenuBar2 (client): failed SLWindowContextCreate fake, giving up");
				return;
			}
			
			menuBarWids[key]=[NSNumber numberWithInt:fakeWid];
			menuBarContexts[key]=(NSObject*)fakeContext;
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
		
		if(!menuBarKeepTransparency())
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
			
			menuBarConfigurePillLayer(layer,displayDark);
			
			[layer renderInContext:fakeContext];
		}
		
		CGContextDrawImage(fakeContext,realRect,realImage);
		CFRelease(realImage);
		
		CGContextFlush(fakeContext);
		
		bar[kCGMenuBarImageWindowKey]=[NSNumber numberWithInt:fakeWid];
		bar[kCGMenuBarInactiveImageWindowKey]=bar[displayDark?kSLMenuBarInactiveImageWindowDarkKey:kSLMenuBarInactiveImageWindowLightKey];
	}
	
	SLSSetMenuBar$(cid,menuBarArrayCache,menuBarDictCache);
}

int SLSSetMenuBars(int edi_cid,NSMutableArray<NSMutableDictionary*>* rsi_array,NSMutableDictionary* rdx_dict)
{
	if(menuBarArrayCache)
	{
		menuBarArrayCache.release;
		menuBarDictCache.release;
	}
	
	menuBarArrayCache=rsi_array.retain;
	menuBarDictCache=rdx_dict.retain;
	
	menuBarSendCached();
	
	return 0;
}

// MARK: misc notifications

// move replicants between screens

void statusBarSpaceCallback()
{
	// TODO: not how it's officially done
	
	NSDictionary* dict=SLSCopySystemStatusBarMetrics();
	[NSNotificationCenter.defaultCenter postNotificationName:kSLSCoordinatedSystemStatusBarMetricsChangedNotificationName object:nil userInfo:dict];
	dict.release;
}

// update app toolbars

void menuBarRevealCommon(NSNumber* amount)
{
	// based on -[_NSFullScreenSpace wallSpaceID]
	
	unsigned int connection=SLSMainConnectionID();
	unsigned long spaceID=SLSGetActiveSpace(connection);
	NSDictionary* spaceDict=SLSSpaceCopyValues(SLSMainConnectionID(),spaceID);
	NSNumber* wallID=spaceDict[kCGSWorkspaceWallSpaceKey][kCGSWorkspaceSpaceIDKey];
	
	NSMutableDictionary* output=NSMutableDictionary.alloc.init;
	output[@"space"]=wallID;
	output[@"reveal"]=amount;
	
	spaceDict.release;
	
	[NSNotificationCenter.defaultCenter postNotificationName:kSLSCoordinatedSpaceMenuBarRevealChangedNotificationName object:nil userInfo:output];
	
	output.release;
}

void menuBarRevealCallback()
{
	menuBarRevealCommon(@1.0);
}

void menuBarHideCallback()
{
	menuBarRevealCommon(@0.0);
}

dispatch_once_t notifyOnce;
NSNotificationCenter* SLSCoordinatedLocalNotificationCenter()
{
	dispatch_once(&notifyOnce,^()
	{
		int connection=SLSMainConnectionID();
		
		SLSRegisterConnectionNotifyProc(connection,statusBarSpaceCallback,kCGSPackagesStatusBarSpaceChanged,nil);
		
		// not in WSLogStringForNotifyType
		SLSRegisterConnectionNotifyProc(connection,menuBarRevealCallback,0x524,nil);
		SLSRegisterConnectionNotifyProc(connection,menuBarHideCallback,0x525,nil);
	});
	
	return NSNotificationCenter.defaultCenter;
}

// AppKit callbacks crash

dispatch_block_t SLSCopyCoordinatedDistributedNotificationContinuationBlock()
{
	dispatch_block_t result=SLSCopyCoordinatedDistributedNotificationContinuationBloc$();
	if(result)
	{
		return result;
	}
	
	// TODO: ownership?
	return ^()
	{
	};
}

// refresh layout on status bar length changes

void (*real_setLength)(NSObject* rdi_self,SEL rsi_sel,double xmm0_length);
void fake_setLength(NSObject* rdi_self,SEL rsi_sel,double xmm0_length)
{
	real_setLength(rdi_self,rsi_sel,xmm0_length);
	
	SLSAdjustSystemStatusBarWindows(SLSMainConnectionID());
}

// MARK: auto dark server

#define MENUBAR_HEIGHT 24
#define MENUBAR_WALLPAPER_THRESHOLD 0.57
#define MENUBAR_WALLPAPER_DELAY 2
#define MENUBAR_DARK_NOTE @"Moraea.MenuBar2.DarkTextChanged"
#define MENUBAR_DARK_NOTE_2 @"Moraea.MenuBar2.DarkTextChanged.Sonoma"

// taken from SkyLight, slightly differs from values found online
	
#define LUMINANCE_RED 0.212648
#define LUMINANCE_GREEN 0.715200
#define LUMINANCE_BLUE 0.072200

CGImageRef (*soft_CGWindowListCreateImageFromArray)(CGRect,CFArrayRef,CGWindowImageOption);

void menuBarServerRecalculate()
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
		
#if MAJOR>=15
		CGImageRef screenshot=soft_CGWindowListCreateImageFromArray(rect,array,kCGWindowImageDefault);
#else
		CGImageRef screenshot=CGWindowListCreateImageFromArray(rect,array,kCGWindowImageDefault);
#endif

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
		
		// trace(@"MenuBar2 (server): calculated brightness %f, display %d, dark text %d",brightness,display,darkText);
		
		menuBarAutoDarkWrite(darkText,display);
	}
	
	CFRelease(windows);
	
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
}

void menuBarServerRecalculateAfterDelay()
{
	// TODO: handle the fade time in auto changing wallpapers... not ideal
			
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW,MENUBAR_WALLPAPER_DELAY*NSEC_PER_SEC),dispatch_get_main_queue(),^()
	{
		menuBarServerRecalculate();
	});
}

void menuBarServerReduceTransparencyCallback(CFNotificationCenterRef center,void* observer,CFNotificationName name,const void* object,CFDictionaryRef userInfo)
{
	trace(@"MenuBar2 (server): forwarding Reduce Transparency/Increase Contrast to clients");
	
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
}

void menuBarServerAppearanceCallback(CFNotificationCenterRef center,void* observer,CFNotificationName name,const void* object,CFDictionaryRef userInfo)
{
	if(!menuBarKeepTransparency())
	{
		trace(@"MenuBar2 (server): forwarding appearance toggle to clients because Reduce Transparency/Increase Contrast is on");
		
		[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
	}
}

id (*real_encodeWithCoder)(id,SEL,id);
id fake_encodeWithCoder(id self,SEL sel,id coder)
{
	// trace(@"MenuBar2 (server 2): changed wallpaper");
	
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE_2 object:nil userInfo:nil deliverImmediately:true];
	
	return real_encodeWithCoder(self,sel,coder);
}

void menuBarSetup()
{
	swizzleImp(@"NSStatusItem",@"setLength:",true,(IMP)fake_setLength,(IMP*)&real_setLength);
	
	if(earlyBoot)
	{
		return;
	}
	
	if(isWindowServer)
	{
		return;
	}
	
	// we used to link this directly, but it's marked unavailable for 15+ in CGWindow.h
	// because Foundation imports CoreGraphics, i don't how how to work around this with #define?
	// im almost certainly missing something.. -A
	
	soft_CGWindowListCreateImageFromArray=dlsym(RTLD_DEFAULT,"CGWindowListCreateImageFromArray");
	
	// ≥ Sonoma
	
	if([process containsString:@"WallpaperAgent.app"])
	{
		swizzleImp(@"WallpaperIDXPC",@"encodeWithCoder:",true,(IMP)fake_encodeWithCoder,(IMP*)&real_encodeWithCoder);
		
		return;
	}
	
	if([process isEqual:@"/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"])
	{
		// ≤ Ventura
		
		[NSNotificationCenter.defaultCenter addObserverForName:@"desktoppicturechanged" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			// trace(@"MenuBar2 (server): changed wallpaper");
			
			menuBarServerRecalculateAfterDelay();
		}];
		
		// ≥ Sonoma
		
		[NSDistributedNotificationCenter.defaultCenter addObserverForName:MENUBAR_DARK_NOTE_2 object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			// trace(@"MenuBar2 (server): woken by server 2");
			
			menuBarServerRecalculateAfterDelay();
		}];
		
		// ≥ Sequoia
		
		[NSDistributedNotificationCenter.defaultCenter addObserverForName:@"com.apple.desktop.ready" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			// trace(@"MenuBar2 (server): desktop ready");
			
			menuBarServerRecalculateAfterDelay();
		}];
		
		menuBarServerRecalculateAfterDelay();
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),NULL,menuBarServerReduceTransparencyCallback,CFSTR("AXInterfaceReduceTransparencyStatusDidChange"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),NULL,menuBarServerReduceTransparencyCallback,CFSTR("AXInterfaceIncreaseContrastStatusDidChange"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),NULL,menuBarServerAppearanceCallback,CFSTR("AppleInterfaceThemeChangedNotification"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
		
		dispatch_async(dispatch_queue_create(NULL,NULL),^()
		{
			BOOL oldManualValue=menuBarManualDark();
			BOOL oldAutoSetting=menuBarAutoDarkEnabled();
			while(true)
			{
				[NSThread sleepForTimeInterval:1];
				
				BOOL newManualValue=menuBarManualDark();
				BOOL newAutoSetting=menuBarAutoDarkEnabled();
				if(newManualValue!=oldManualValue||newAutoSetting!=oldAutoSetting)
				{
					oldManualValue=newManualValue;
					oldAutoSetting=newAutoSetting;
					
					[NSDistributedNotificationCenter.defaultCenter postNotificationName:MENUBAR_DARK_NOTE object:nil userInfo:nil deliverImmediately:true];
				}
			}
		});
		
		return;
	}
	
	menuBarWids=NSMutableDictionary.alloc.init;
	menuBarContexts=NSMutableDictionary.alloc.init;
	
	[NSDistributedNotificationCenter.defaultCenter addObserverForName:MENUBAR_DARK_NOTE object:nil queue:nil usingBlock:^(NSNotification* note)
	{
		menuBarSendCached();
		
		// TODO: hack to avoid code duplication with MB1
		
		statusBarSpaceCallback();
	}];
}
