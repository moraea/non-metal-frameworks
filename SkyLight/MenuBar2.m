// testing replacements for some old menu bar hacks, so far just proper selections
// TODO: auto light/dark next...

// forward Rim.m

void SLSWindowSetShadowProperties(unsigned int,NSDictionary*);

int menuBar2Wid=0;
CGContextRef menuBar2Context=NULL;

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

int menuBar2Set(int edi_cid,NSMutableArray<NSMutableDictionary*>* rsi_array,NSMutableDictionary* rdx_dict)
{
	// prevent black background
	
	rdx_dict[kCGMenuBarActiveMaterialKey]=@"Light";
	
	for(NSMutableDictionary* bar in rsi_array)
	{
		int realWid=((NSNumber*)bar[styleIsDark()?kSLMenuBarImageWindowDarkKey:kSLMenuBarImageWindowLightKey]).intValue;
		CGContextRef realContext=SLWindowContextCreate(SLSMainConnectionID(),realWid,0);
		CGImageRef realImage=SLWindowContextCreateImage(realContext);
		CFRelease(realContext);
		
		CGRect realRect=CGRectMake(0,0,CGImageGetWidth(realImage),CGImageGetHeight(realImage));
		
		// TODO: probably need separate ones for screens?
		
		if(menuBar2Wid==0)
		{
			int cid=SLSMainConnectionID();
			
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
		
		NSArray<NSData*>* titles=bar[@"menuBarMenuTitlesArray"];
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
		
		CGContextDrawImage(menuBar2Context,realRect,realImage);
		CFRelease(realImage);
		
		CGContextFlush(menuBar2Context);
		
		bar[kCGMenuBarImageWindowKey]=[NSNumber numberWithInt:menuBar2Wid];
	}
	
	return SLSSetMenuBar$(edi_cid,rsi_array,rdx_dict);
}