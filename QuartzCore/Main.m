#import "Utils.h"
@import IOSurface;
@import CoreGraphics;

NSString* process;

#import "Extern.h"

#import "Animations.m"
#import "Catalyst.m"
#import "Misc.m"

#ifdef CAT
#import "Glyphs.m"
#import "Siri.m"
#endif

#ifdef MOJ
#import "Siri.m"
#import "Videos.m"
#endif

#if MAJOR>=14
#import "Sonoma.m"
#endif

__attribute__((constructor)) void load(int argCount,char** argList)
{
	@autoreleasepool
	{
		traceLog=true;
		tracePrint=false;
		swizzleLog=false;
		
		process=[NSString stringWithUTF8String:argList[0]].retain;
		
		catalystSetup();
		miscSetup();
		
	#if defined(CAT) || defined(MOJ)
		animationsSetup();
	#endif
		
	#ifdef CAT
		glyphsSetup();
	#endif
		
	#if MAJOR>=14
		sonomaSetup();
	#endif
	}
}
