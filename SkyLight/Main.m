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

#if MAJOR>=13
#import "DefenestratorInterface.h"
#import "Defenestrator2c.m"
#import "DefenestratorAgnosticBlurs.m"
#import "SafariHack.m"
#import "Spin.m"
#import "Books.m"
#else
#import "Defenestrator.m"
#endif

#import "Discord.m"
#import "DisplayLink.m"
#import "Dock.m"
#import "EnableTransparency.m"
#import "FullScreen.m"
#import "Glyphs.m"
#import "Grey.m"
#import "Hidd.m"
#import "MenuBar.m"
#import "Occlusion.m"
#import "Rim.m"
#import "Scroll.m"
#import "Session.m"
#import "Sleep.m"
#import "Split.m"
#import "Todo.m"
#import "WindowFlags.m"
#import "Zoom.m"
#import "Trackpad.m"
#import "Plugins.m"

#if MAJOR==11
#import "Photos.m"
#else
#import "Cycle.m"
#import "Done.m"
#endif

#ifdef SENTIENT_PATCHER
#import "NightShift.m"
#endif

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
	
	defenestratorSetup();

	glyphsSetup();
	hiddSetup();
	menuBarSetup();
	occlusionSetup();
	appearanceSetup();
	pluginsSetup();
	trackpadSetup();
	
#if MAJOR==11
	photosSetup();
#else
	cycleSetup();
	doneSetup();
#endif
#if MAJOR>=13
	blursSetupNew();
	safariHackSetup();
	booksHackSetup();
#endif
}

@end
