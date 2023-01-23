// hopefully temporary hack for Safari downloads race condition (ViewBridge weirdness..)
// see amys-hacking-tutorial for details

#define SAFARI_HACK_DELAY 0.2

void (*real_viewDidAdvanceToRunPhase)(NSObject*,SEL,void*);
void fake_viewDidAdvanceToRunPhase(NSObject* self,SEL sel,void* rdx)
{
	trace(@"SafariHack: viewDidAdvanceToRunPhase enter %@ %@",self,rdx);
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW,SAFARI_HACK_DELAY*NSEC_PER_SEC),dispatch_get_current_queue(),^()
	{
		trace(@"SafariHack: viewDidAdvanceToRunPhase complete %@ %@",self,rdx);
		
		real_viewDidAdvanceToRunPhase(self,sel,rdx);
	});
}

void safariHackSetup()
{
	if([process isEqual:@"/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/Contents/MacOS/Safari"])
	{
		swizzleImp(@"NSRemoteViewControllerAuxiliary",@"viewDidAdvanceToRunPhase:",true,(IMP)fake_viewDidAdvanceToRunPhase,(IMP*)&real_viewDidAdvanceToRunPhase);
	}
}