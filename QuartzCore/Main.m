#import "Utils.h"

NSString* process;

#import "Extern.h"

#import "Animations.m"
#import "Catalyst.m"
#import "Misc.m"
#import "Siri.m"
#import "Videos.m"

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
}