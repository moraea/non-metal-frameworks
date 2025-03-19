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
#import "Defenestrator3.m"
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
#import "Spin.m"
#import "Done.m"
#import "Preflight.m"
#import "TS2.m"

#if MAJOR==11
#import "PhotosBigSur.m"
#endif

#if MAJOR>=12
#import "Cycle.m"
#import "Books.m"
#endif

#if MAJOR>=13
#import "DefenestratorAgnosticBlurs.m"
#import "SafariHack.m"
#import "Logic.m"
#endif

#if MAJOR>=14
#import "loginwindow.m"
#endif

#if MAJOR>=15
#import "PhotosSequoia.m"
#import "NotificationCenterSequoia.m"
#endif

#define processDenylist @[@"/usr/sbin/sshd",@"/usr/libexec/cryptexd",@"/System/Library/Frameworks/GSS.framework/Helpers/GSSCred",@"/usr/sbin/cfprefsd",@"/usr/libexec/watchdog",@"/usr/sbin/gssd",@"/usr/libexec/sshd-session"]

__attribute__((constructor)) void load(int argCount,char** argList)
{
	@autoreleasepool
	{
		NSObject.load;
		process=NSProcessInfo.processInfo.arguments[0];
		
		if([processDenylist containsObject:process])
		{
			// entirely disable SL shims initializers for these processes
			// this will completely break anything graphical!
		
			return;
		}
	
		earlyBoot=getpid()<200;
		isWindowServer=[process isEqualToString:@"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/Resources/WindowServer"];
		
		if(isWindowServer)
		{
			int handle=open("/dev/console",O_WRONLY);
			dprintf(handle,"\e[35mZoe <3\n\e[32mASentientBot, EduCovas, ASentientHedgehog\e[0m\n");
			close(handle);
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
		ts2Setup();
		doneSetup();
	
#if MAJOR==11
		photosSetup();
#endif
	
#if MAJOR>=12
#if MAJOR<14
		cycleSetup();
#endif
		booksHackSetup();
#endif
	
#if MAJOR>=13
		blursSetupNew();
		safariHackSetup();
		logicHackSetup();
#endif
	
#if MAJOR>=14
		loginwindowSetup();
		zoomHackSetup();
#endif

#if MAJOR>=15
		photosSetup();
		notificationCenterSetup();
#endif
	}
}
