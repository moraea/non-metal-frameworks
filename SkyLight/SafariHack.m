// hopefully temporary hack for Safari downloads race condition (ViewBridge weirdness..)
// see amys-hacking-tutorial for details

#define SAFARI_HACK_DELAY 0.2

void (*real_viewDidAdvanceToRunPhase)(NSObject*,SEL,void*);
void fake_viewDidAdvanceToRunPhase(NSObject* self,SEL sel,void* rdx)
{
	// trace(@"SafariHack: viewDidAdvanceToRunPhase enter %@ %@",self,rdx);
	
	// TODO: pretty sure we can use main queue but i don't want to break something
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW,SAFARI_HACK_DELAY*NSEC_PER_SEC),dispatch_get_current_queue(),^()
	{
		// trace(@"SafariHack: viewDidAdvanceToRunPhase complete %@ %@",self,rdx);
		
		real_viewDidAdvanceToRunPhase(self,sel,rdx);
	});

#pragma clang diagnostic pop

}

long disable()
{
	return 0;
}

void safariHackSetup()
{
	// TODO: i don't think this is necessary on Sequoia? but it doesn't break it either..
	
	if([process isEqual:@"/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/Contents/MacOS/Safari"])
	{
		swizzleImp(@"NSRemoteViewControllerAuxiliary",@"viewDidAdvanceToRunPhase:",true,(IMP)fake_viewDidAdvanceToRunPhase,(IMP*)&real_viewDidAdvanceToRunPhase);
		
		// disable hide distracting items animation
#if MAJOR>=15
		swizzleImp(@"WBSScribbleEffectView",@"_prewarmSceneAndEffect",false,(IMP)disable,NULL);
#endif
	}
}
