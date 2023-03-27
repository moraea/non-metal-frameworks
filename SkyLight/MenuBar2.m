// testing some new menu bar hacks (proper selections, auto text color)
// TODO: currently very pre-alpha quality!

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
	
	for(NSMutableDictionary* bar in array)
	{
		NSNumber* key=bar[kCGMenuBarDisplayIDKey];
		
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
			SLSWindowSetShadowProperties(fakeWid,@{});
			
			fakeContext=SLWindowContextCreate(cid,fakeWid,NULL);
			
			menuBar2Wids[key]=[NSNumber numberWithInt:fakeWid];
			menuBar2Contexts[key]=(NSObject*)fakeContext;
			CFRelease(fakeContext);
		}
		
		CGContextClearRect(fakeContext,realRect);
		
		NSArray<NSData*>* titles=bar[kCGMenuBarMenuTitlesArrayKey];
		for(NSData* title in titles)
		{
			CALayer* layer=CALayer.layer;
			layer.bounds=*(CGRect*)title.bytes;
			
			CGColorRef color;
			if(displayDark)
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
			
			[layer renderInContext:fakeContext];
		}
		
		// prevent stock material-based title rects (Big Sur)
		
		bar[kCGMenuBarMenuTitlesArrayKey]=nil;
		
		CGContextDrawImage(fakeContext,realRect,realImage);
		CFRelease(realImage);
		
		CGContextFlush(fakeContext);
		
		bar[kCGMenuBarImageWindowKey]=[NSNumber numberWithInt:fakeWid];
		bar[kCGMenuBarInactiveImageWindowKey]=bar[displayDark?kSLMenuBarInactiveImageWindowDarkKey:kSLMenuBarInactiveImageWindowLightKey];
	}
	
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

void menuBar2DockRecalculateWithDisplay(CGDirectDisplayID display)
{
	CGRect displayFrame=CGDisplayBounds(display);
	
	int cid=SLSMainConnectionID();
	
	void* query=SLSWindowQueryCreate(0);
	void* result=SLSWindowQueryRun(cid,query,0);
	void* iterator=SLSWindowQueryResultCopyWindows(result);
	long iteratorCount=SLSWindowIteratorGetCount(iterator);
	
	int wid=-1;
	for(int index=0;index<iteratorCount;index++)
	{
		// TODO: experimentally determined, probably dumb but seems to work consistently
		
		if(SLSWindowIteratorGetTags(iterator,index)!=0x6200000011200)
		{
			continue;
		}
		
		if(SLSWindowIteratorGetPID(iterator,index)!=getpid())
		{
			continue;
		}
		
		if(SLSWindowIteratorGetSpaceAttributes(iterator,index)!=5)
		{
			continue;
		}
		
		CGRect windowRect;
		SLSWindowIteratorGetScreenRect(&windowRect,iterator,index);
		if(!CGRectEqualToRect(windowRect,displayFrame))
		{
			continue;
		}
		
		wid=SLSWindowIteratorGetWindowID(iterator,index);
		
		break;
	}
	
	assert(wid!=-1);
	
	CFRelease(query);
	CFRelease(iterator);
	
	NSArray* screenshots=SLSHWCaptureWindowList(cid,&wid,1,0);
	assert(screenshots.count==1);
	CGImageRef screenshot=(CGImageRef)screenshots[0];
	
	NSData* data=(NSData*)CGDataProviderCopyData(CGImageGetDataProvider(screenshot));
	assert(data);
	
	// TODO: will break on some displays...
	// TODO: check byte ordering as well as size
	
	int bytesPerPixel=CGImageGetBitsPerPixel(screenshot)/8;
	assert(bytesPerPixel==4);
	
	int width=CGImageGetWidth(screenshot);
	assert(CGImageGetHeight(screenshot)>MENUBAR_HEIGHT);
	
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
	
	// TODO: i think it's supposed to be weighted by color based on perception?
	
	float brightness=(float)(redMean+greenMean+blueMean)/3/0xff;
	trace(@"MenuBar2 calculated brightness %f for display %d (%@)",brightness,display,NSStringFromRect(displayFrame));
	BOOL darkText=brightness>MENUBAR_WALLPAPER_THRESHOLD;
	
	menuBar2WriteDark(darkText,display);
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
				menuBar2DockRecalculateWithDisplay(((NSNumber*)note.userInfo[@"did"]).intValue);
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