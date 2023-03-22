// testing some new menu bar hacks (proper selections, auto text color)
// TODO: currently very pre-alpha quality, spaghetti-ed, slow, no support for dual monitors, etc

// forward Rim.m

void SLSWindowSetShadowProperties(unsigned int,NSDictionary*);

// TODO: per screen

int menuBar2Wid=0;
CGContextRef menuBar2Context=NULL;

// cheat at shared state using the session storage

void menuBar2WriteDark(BOOL value)
{
	NSMutableDictionary* dict=((NSMutableDictionary*)SLSCopyCurrentSessionDictionary().autorelease.mutableCopy).autorelease;
	dict[@"Amy.MenuBar2.DarkText"]=[NSNumber numberWithBool:value];
	SLSSetDictionaryForCurrentSession(dict);
}

BOOL menuBar2ReadDark()
{
	// TODO: cache, only update when receiving notification
	
	NSDictionary* dict=SLSCopyCurrentSessionDictionary().autorelease;
	return ((NSNumber*)dict[@"Amy.MenuBar2.DarkText"]).boolValue;
}

BOOL useMenuBar2Value;
dispatch_once_t useMenuBar2Once;
BOOL useMenuBar2()
{
	dispatch_once(&useMenuBar2Once,^()
	{
		useMenuBar2Value=[NSUserDefaults.standardUserDefaults boolForKey:@"Amy.MenuBar2Beta"];
	});
	
	return useMenuBar2Value;
}

NSMutableArray<NSMutableDictionary*>* menuBar2ArrayCache=nil;
NSMutableDictionary* menuBar2DictCache=nil;

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
		int realWid=((NSNumber*)bar[styleIsDark()?kSLMenuBarImageWindowDarkKey:kSLMenuBarImageWindowLightKey]).intValue;
		CGContextRef realContext=SLWindowContextCreate(SLSMainConnectionID(),realWid,0);
		CGImageRef realImage=SLWindowContextCreateImage(realContext);
		CFRelease(realContext);
		
		CGRect realRect=CGRectMake(0,0,CGImageGetWidth(realImage),CGImageGetHeight(realImage));
		
		if(menuBar2Wid==0)
		{
			void* realRegion;
			CGSNewRegionWithRect(&realRect,&realRegion);
			SLSNewWindow(cid,2,realRegion,&menuBar2Wid,0,0);
			CFRelease(realRegion);
			SLSSetWindowOpacity(cid,menuBar2Wid,false);
			
			// TODO: mimic rather than clearing?
			
			SLSWindowSetShadowProperties(menuBar2Wid,@{});
			
			menuBar2Context=SLWindowContextCreate(cid,menuBar2Wid,NULL);
		}
		
		CGContextClearRect(menuBar2Context,realRect);
		
		NSArray<NSData*>* titles=bar[kCGMenuBarMenuTitlesArrayKey];
		for(NSData* title in titles)
		{
			CALayer* layer=CALayer.layer;
			layer.bounds=*(CGRect*)title.bytes;
			
			CGColorRef color;
			if(styleIsDark())
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
			
			[layer renderInContext:menuBar2Context];
		}
		
		// prevent stock material-based title rects
		
		bar[kCGMenuBarMenuTitlesArrayKey]=nil;
		
		CGContextDrawImage(menuBar2Context,realRect,realImage);
		CFRelease(realImage);
		
		CGContextFlush(menuBar2Context);
		
		bar[kCGMenuBarImageWindowKey]=[NSNumber numberWithInt:menuBar2Wid];
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

void menuBar2DockRecalculate()
{
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
	trace(@"mb2 calculated brightness %f",brightness);
	BOOL darkText=brightness>MENUBAR_WALLPAPER_THRESHOLD;
	
	menuBar2WriteDark(darkText);
	[NSDistributedNotificationCenter.defaultCenter postNotificationName:@"Amy.MenuBar2.DarkTextChanged" object:nil userInfo:nil deliverImmediately:true];
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
	
	if([process containsString:@"Dock.app/Contents/MacOS/Dock"])
	{
		[NSNotificationCenter.defaultCenter addObserverForName:@"desktoppicturechanged" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			menuBar2DockRecalculate();
		}];
		
		return;
	}
	
	[NSDistributedNotificationCenter.defaultCenter addObserverForName:@"Amy.MenuBar2.DarkTextChanged" object:nil queue:nil usingBlock:^(NSNotification* note)
	{
		trace(@"mb2 got change notification");
		
		menuBar2SendCached();
		
		// TODO: hack to avoid code duplication with MB1
		
		statusBarSpaceCallback();
	}];
}