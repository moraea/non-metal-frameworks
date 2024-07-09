#import "Utils.h"
@import IOSurface;
@import CoreGraphics;

NSString* process;

#import "Extern.h"

#import "Animations.m"
#import "Catalyst.m"
#import "Misc.m"

#if FRAMEWORK_DOWNGRADE == 101507
#import "Glyphs.m"
#import "Siri.m"
#endif

#if FRAMEWORK_DOWNGRADE == 101406
#import "Siri.m"
#import "Videos.m"
#endif

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 140000
#import "Sonoma.m"
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
	
#if FRAMEWORK_DOWNGRADE >= 101400 && FRAMEWORK_DOWNGRADE <= 101599
	animationsSetup();
#endif
	
#if FRAMEWORK_DOWNGRADE == 101507
	glyphsSetup();
#endif

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 140000
	sonomaSetup();
#endif
}