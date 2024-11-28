#define CLOCK_HACK_ALPHA 0.5

// monochrome widgets

extern const NSString* kCAFilterColorMatrix;
extern const NSString* kCAFilterVibrantColorMatrix;

NSObject* (*real_filterWithType)(id,SEL,NSString*);

NSObject* fake_filterWithType(id meta,SEL sel,NSString* type)
{
	if([type isEqual:kCAFilterVibrantColorMatrix])
	{
		type=(NSString*)kCAFilterColorMatrix;
	}
	
	return real_filterWithType(meta,sel,type);
}

void (*clockSetMaskReal)(CALayer*,SEL,CALayer*);
void clockSetMaskFake(CALayer* self,SEL sel,CALayer* mask)
{
	if(mask&&[NSStringFromClass(self.class) isEqual:@"CABackdropLayer"]&&self.sublayers.count==0)
	{
		CALayer* white=CALayer.layer;
		white.frame=CGRectMake(0,0,999,999);
		CGColorRef color=CGColorCreateGenericRGB(1,1,1,CLOCK_HACK_ALPHA);
		white.backgroundColor=color;
		CFRelease(color);
		[self addSublayer:white];
	}
	
	clockSetMaskReal(self,sel,mask);
}

// Workaround Weather app crash

long Fakeinit()
{
	return 0;
}

// Force full color desktop widgets

id (*real_objectForKey)(NSUserDefaults*,SEL,NSString*);

id fake_objectForKey(NSUserDefaults* self,SEL selector,NSString* key)
{
	if(![key isEqual:@"widgetAppearance"])
	{
		return real_objectForKey(self,selector,key);
	}
	
	return @1;
}

void sonomaSetup()
{
	if([process containsString:@"NotificationCenter.app"])
	{
		swizzleImp(@"CAFilter",@"filterWithType:",false,(IMP)fake_filterWithType,(IMP*)&real_filterWithType);

		if([NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_ColorWidgetDisabled"]!=1)
		{
			swizzleImp(@"NSUserDefaults",@"objectForKey:",true,(IMP)fake_objectForKey,(IMP*)&real_objectForKey);
		}
	}
	
	if([process containsString:@"SecurityAgent"]||[process containsString:@"loginwindow"])
	{
		swizzleImp(@"CALayer",@"setMask:",true,(IMP)clockSetMaskFake,(IMP*)&clockSetMaskReal);
	}
	
	if([process isEqualToString:@"/System/Applications/Weather.app/Contents/MacOS/Weather"])
	{
		swizzleImp(@"CAMetalLayer",@"init",true,(IMP)Fakeinit,NULL);
	}
}

// fix speed up QuickTime videos
// ASB should look at this since i just copied the signatures from the Mojave QC shim

#ifdef CAT
int CAImageQueueSetMediaTiming(void* rdi_queue,int esi,void* rdx_surface,int ecx,void* r8_function,void* r9,double xmm0);

int CAImageQueueSetMediaTimingClamped(void* rdi_queue,int esi,void* rdx,int ecx,int r8d,void* r9_function,double xmm0,void* stack)
{
	return CAImageQueueSetMediaTiming(rdi_queue,esi,rdx,ecx,r9_function,stack,xmm0);
}

#else

int CAImageQueueSetMediaTimingClamped()
{
	return 0;
}

#endif

// Safari blank

// softlinked; doesn't crash, but doesn't work
// no/stub CAIOSurfaceCreate

// returned object must be retain-able, and must be settable as CALayer.contents
// 14's QC implements a CF type
// but the actual IOSurface _already_ meets those requirements
// just need to retain it to prevent UAF since the arg is released ("Create rule")

id CAIOSurfaceCreate(IOSurface* rdi)
{
	rdi.retain;
	return rdi;
}
