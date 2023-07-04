// TODO: the White Stuff Problem
// like the HD3000 Problem, this is "fixable" by changing colorspace to sRGB/Unknown Display

// monochrome widgets

extern const NSString* kCAFilterColorMatrix;
extern const NSString* kCAFilterVibrantColorMatrix;

NSObject* (*real_filterWithType)(id,SEL,NSString*);

NSObject* fake_filterWithType(id meta,SEL sel,NSString* type)
{
	if([type isEqual:kCAFilterVibrantColorMatrix])
	{
		type=kCAFilterColorMatrix;
	}
	
	return real_filterWithType(meta,sel,type);
}

// example for EduCovas - hooking to print the filters

void (*debugReal_setFilters)(CALayer*,SEL,NSArray*);
void debugFake_setFilters(CALayer* self,SEL sel,NSArray* filters)
{
	trace(@"debug hook - setFilters: self %@ filters %@ stack trace %@",self,filters,NSThread.callStackSymbols);
	
	debugReal_setFilters(self,sel,filters);
}

void sonomaSetup()
{
	if([process containsString:@"NotificationCenter.app"])
	{
		swizzleImp(@"CAFilter",@"filterWithType:",false,fake_filterWithType,&real_filterWithType);
	}
	
	// example
	
	// swizzleImp(@"CALayer",@"setFilters:",true,debugFake_setFilters,&debugReal_setFilters);
}

// fix speed up QuickTime videos
// ASB should look at this since i just copied the signatures from the Mojave QC shim

int CAImageQueueSetMediaTiming(void* rdi_queue,int esi,void* rdx_surface,int ecx,void* r8_function,void* r9,double xmm0);

int CAImageQueueSetMediaTimingClamped(void* rdi_queue,int esi,void* rdx,int ecx,int r8d,void* r9_function,double xmm0,void* stack)
{
	return CAImageQueueSetMediaTiming(rdi_queue,esi,rdx,ecx,r9_function,stack,xmm0);
}