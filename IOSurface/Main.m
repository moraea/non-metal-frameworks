#import "Utils.h"
@import IOSurface;

#ifdef CAT

size_t IOSurfaceGetPropertyMaximu$(CFStringRef);

size_t IOSurfaceGetPropertyMaximum(CFStringRef property)
{
	size_t real=IOSurfaceGetPropertyMaximu$(property);
	if(real==INT_MAX)
	{
		// TODO: actually fetch this somehow?
		// returned by working IOSurface on Zoe
		
		return 0x2000;
	}
	return real;
}

#endif