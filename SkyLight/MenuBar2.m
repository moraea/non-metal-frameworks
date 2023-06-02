// new menu bar hacks (proper selections, auto text color)
// TODO: test thoroughly, then enable by default, then replace MenuBar entirely
// TODO: correct bar background on fullscreen windows

#define MENUBAR_DARK_FORMAT @"Amy.MenuBar2.DarkText.%d"
#define MENUBAR_DARK_NOTE @"Amy.MenuBar2.DarkTextChanged"
#define MENUBAR_KEY_BETA @"Amy.MenuBar2Beta"

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

BOOL menuBar2ReadDark(int display)
{
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
	
	NSMutableArray<NSMutableDictionary*>* array=menuBar2ArrayCache;
	NSMutableDictionary* dict=menuBar2DictCache;
	
	// prevent black background
	
	dict[kCGMenuBarActiveMaterialKey]=@"Light";
	
	// prevent blue material selection (Big Sur)
	
	dict[kCGMenuBarTitleMaterialKey]=nil;
	
	NSArray<NSDictionary*>* spaceInfo=SLSCopyManagedDisplaySpaces(cid);
	
	for(NSMutableDictionary* bar in array)
	{
		// TODO: some string keys i can't be bothered looking for right now
		
		NSNumber* key=bar[kCGMenuBarDisplayIDKey];
		if(!key)
		{
			int displayID=-1;
			for(NSDictionary* display in spaceInfo)
			{
				NSArray<NSDictionary*>* spaces=display[@"Spaces"];
				for(NSDictionary* space in spaces)
				{
					if([space[@"ManagedSpaceID"] isEqual:bar[kCGMenuBarSpaceIDKey]])
					{
						CFUUIDRef uuid=CFUUIDCreateFromString(NULL,(CFStringRef)display[@"Display Identifier"]);
						displayID=SLSGetDisplayForUUID(uuid);
						CFRelease(uuid);
						break;
					}
				}
				if(displayID!=-1)
				{
					break;
				}
			}
			
			if(displayID==-1)
			{
				displayID=CGMainDisplayID();
				trace(@"MenuBar2: failed finding display ID for space, fallback %d, bar: %@",displayID,bar);
			}
			
			key=[NSNumber numberWithInt:displayID];
		}
		
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
			
			SLSWindowSetShadowProperties(fakeWid,@{@"com.apple.WindowShadowRadiusInactive":@2.5,@"com.apple.WindowShadowDensityInactive":@0.3,@"com.apple.WindowShadowVerticalOffsetInactive":@1.75});
		}
		
		CGContextClearRect(fakeContext,realRect);
		
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
	
	spaceInfo.release;
	
	SLSSetMenuBar$(cid,array,dict);
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
		if(![name containsString:@"Desktop Picture"])
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
		
		int wid=((NSNumber*)info[(NSString*)kCGWindowNumber]).intValue;
		
		NSArray* screenshots=SLSHWCaptureWindowList(cid,&wid,1,0);
		if(screenshots.count!=1)
		{
			trace(@"MenuBar2 (server): failed capturing screenshot for wid %d",wid);
			continue;
		}
		
		CGImageRef screenshot=(CGImageRef)screenshots[0];
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
			trace(@"MenuBar2 (server): screenshot %@ violates bpp assumption",screenshot);
			continue;
		}
		
		int width=CGImageGetWidth(screenshot);
		if(CGImageGetHeight(screenshot)<MENUBAR_HEIGHT)
		{
			trace(@"MenuBar2 (server): screenshot %@ too short",screenshot);
			continue;
		}
		
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
	
	if([process containsString:@"Dock.app/Contents/MacOS/Dock"])
	{
		[NSNotificationCenter.defaultCenter addObserverForName:@"desktoppicturechanged" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			// TODO: handle the fade time in auto changing wallpapers... not ideal
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW,MENUBAR_WALLPAPER_DELAY*NSEC_PER_SEC),dispatch_get_main_queue(),^()
			{
				menuBar2DockRecalculate2();
			});
		}];
		
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