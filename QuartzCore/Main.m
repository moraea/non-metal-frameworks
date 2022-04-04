#import "Utils.h"

NSString* process;

#import "Extern.h"

#import "Animations.m"
#import "Catalyst.m"
#import "Misc.m"
#import "Siri.m"

#ifdef CAT
#import "Glyphs.m"
#else
#import "Videos.m"
#endif

__attribute__((constructor))
void load()
{
	traceLog=true;
	tracePrint=false;
	swizzleLog=false;
	
	process=NSProcessInfo.processInfo.arguments[0];
	
	animationsSetup();
	catalystSetup();
	miscSetup();
	
#ifdef CAT
	glyphsSetup();
#endif
}