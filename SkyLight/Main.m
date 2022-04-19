@import QuartzCore;
@import Darwin.POSIX.dlfcn;
@import Darwin.POSIX.dirent;

#import "Utils.h"

BOOL earlyBoot;
NSString* process;
BOOL isWindowServer;

#import "Extern.h"

#import "Appearance.m"
#import "Backlight.m"
#import "Cycle.m"
#import "Defenestrator.m"
#import "DisplayLink.m"
#import "Dock.m"
#import "Glyphs.m"
#import "Grey.m"
#import "Hidd.m"
#import "MenuBar.m"
#import "NightShift.m"
#import "Occlusion.m"
#import "Photos.m"
#import "Rim.m"
#import "Scroll.m"
#import "Session.m"
#import "Sleep.m"
#import "Todo.m"
#import "WindowFlags.m"
#import "Zoom.m"
#import "Trackpad.m"
#import "Plugins.m"

@interface Setup:NSObject
@end

@implementation Setup

+(void)load
{
	earlyBoot=getpid()<200;
	process=NSProcessInfo.processInfo.arguments[0];
	isWindowServer=[process isEqualToString:@"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer"];
	
	if(earlyBoot&&[process isEqualToString:@"/usr/sbin/kextcache"])
	{
		trace(@"Zoe <3");
		trace(@"\e[32mASentientBot, EduCovas, ASentientHedgehog");
	}
	
	traceLog=true;
	tracePrint=false;
	swizzleLog=false;
	
	cycleSetup();
	defenestratorSetup();
	glyphsSetup();
	hiddSetup();
	menuBarSetup();
	occlusionSetup();
	appearanceSetup();
	pluginsSetup();
	trackpadSetup();
	
#if MAJOR == 11
	photosSetup();
#endif
}

@end
