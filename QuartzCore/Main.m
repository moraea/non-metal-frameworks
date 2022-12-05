#import "Utils.h"

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

__attribute__((constructor))
void load()
{
	traceLog=true;
	tracePrint=false;
	swizzleLog=false;
	
	process=NSProcessInfo.processInfo.arguments[0];

	catalystSetup();
	miscSetup();
	
#if defined(CAT) || defined(MOJ)
	animationsSetup();
#endif
	
#ifdef CAT
	glyphsSetup();
#endif
}