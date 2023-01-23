#define DELAY 0.2

void (*r_viewDidAdvanceToRunPhase)(NSObject*,SEL,void*);
void f_viewDidAdvanceToRunPhase(NSObject* self,SEL sel,void* rdx)
{
	trace(@"viewDidAdvanceToRunPhase enter %@ %@",self,rdx);
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW,DELAY*NSEC_PER_SEC),dispatch_get_current_queue(),^()
	{
		trace(@"viewDidAdvanceToRunPhase complete %@ %@",self,rdx);
		
		r_viewDidAdvanceToRunPhase(self,sel,rdx);
	});
}

__attribute__((constructor)) void l()
{
	if([process isEqual:@"/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/Contents/MacOS/Safari"])
	{
		swizzleImp(@"NSRemoteViewControllerAuxiliary",@"viewDidAdvanceToRunPhase:",true,f_viewDidAdvanceToRunPhase,&r_viewDidAdvanceToRunPhase);
	}
}