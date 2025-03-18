#import "Utils.h"
@import IOSurface;

#ifdef CAT

// TODO: downgrading IOSurface to 10.14.6 (TS2 patchset) fixes the underlying issue for me
// but Edu can't replicate this on his identical Zoe... should reverse IOSurface.kext

size_t IOSurfaceGetPropertyMaximu$(CFStringRef);

size_t IOSurfaceGetPropertyMaximum(CFStringRef property)
{
	size_t real=IOSurfaceGetPropertyMaximu$(property);
	if(real==INT_MAX)
	{
		// TODO: actually fetch the value somehow?
		// returned by working IOSurface on Zoe, but could vary on different GPUs
		
		return 0x2000;
	}
	return real;
}

#endif

NSString* process=nil;

id doNothing()
{
	return nil;
}

void weatherSetup()
{
	if([process isEqual:@"/System/Applications/Weather.app/Contents/MacOS/Weather"])
	{
		// TODO: downgrading ImageIO actually fixes it; not sure the cause but it's definitely between that and IOSurface
		
		swizzleImp(@"CAMLLoader",@"loadCAMLFile:",true,(IMP)doNothing,NULL);
	}
}

__attribute__((constructor)) void load(int argCount,char** argList)
{
	@autoreleasepool
	{
		traceLog=true;
		tracePrint=false;
		swizzleLog=false;
		
		process=[NSString stringWithUTF8String:argList[0]].retain;
		
#if MAJOR>=15
		weatherSetup();
#endif
	}
}


@interface _IOSurfaceDebugDescription:NSObject
@end
@interface _IOSurfaceDebugDescription(Stub)
@end
@implementation _IOSurfaceDebugDescription(Stub)

-(id)pixelFormatString
{
	return nil;
}

-(id)dirtySize
{
	return nil;
}

-(id)residentSize
{
	return nil;
}

-(id)traceID
{
	return nil;
}
@end
