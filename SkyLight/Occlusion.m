// WebKit, Activity Monitor refresh only when visible
// save panel, UNCAlert buttons, Safari extensions setting check for security

// fix NSWindow.occlusionState

// TODO: results in occlusionState 8194/8192 visible/occluded, NSWindowOcclusionStateVisible == 2
// first-party apps work, but docs don't specify it should be checked bitwise

void (*real__setWindowNumber)(id self,SEL selector,unsigned long windowID);
void fake__setWindowNumber(id self,SEL selector,unsigned long windowID)
{
	real__setWindowNumber(self,selector,windowID);
	
	if(windowID!=-1)
	{
		// from Cat -[NSWindow _setWindowNumber:]
		
		SLSPackagesEnableWindowOcclusionNotifications(SLSMainConnectionID(),windowID,1,0);
	}
}

// not present in old SkyLight

@interface SLSecureCursorAssertion(Shim)
@end

@implementation SLSecureCursorAssertion(Shim)

+(instancetype)assertion
{
	// trace(@"SLSecureCursorAssertion assertion");
	
	return SLSecureCursorAssertion.alloc.init.autorelease;
}

-(BOOL)isValid
{
	// trace(@"SLSecureCursorAssertion isValid");
	
	return true;
}

@end

// TODO: idk why 0x526/0x527 notifications aren't sent, so just override these for now

BOOL fake_validateNoOcclusionSinceToken(NSObject* rdi_self,SEL rsi_sel,NSNumber* rdx_token)
{
	return true;
}

BOOL fake_isOccluded(NSObject* rdi_self,SEL rsi_sel)
{
	return false;
}

void (*real_viewDidMoveToWindow)(NSObject*,SEL);
void fake_viewDidMoveToWindow(NSObject* rdi_self,SEL rsi_sel)
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1*NSEC_PER_SEC),dispatch_get_main_queue(),^()
	{
		[NSNotificationCenter.defaultCenter postNotificationName:@"NSOcclusionDetectionViewDidBecomeUnoccluded" object:rdi_self userInfo:@{@"validationToken":SLSecureCursorAssertion.assertion}];
	});
	
	real_viewDidMoveToWindow(rdi_self,rsi_sel);
}

void occlusionSetup()
{
	if(earlyBoot)
	{
		return;
	}
	
	BOOL appKitAvailable=swizzleImp(@"NSWindow",@"_setWindowNumber:",true,(IMP)fake__setWindowNumber,(IMP*)&real__setWindowNumber);
	
	if(appKitAvailable)
	{
		swizzleImp(@"NSOcclusionDetectionView",@"validateNoOcclusionSinceToken:",true,(IMP)fake_validateNoOcclusionSinceToken,NULL);
		swizzleImp(@"NSOcclusionDetectionView",@"isOccluded",true,(IMP)fake_isOccluded,NULL);
		swizzleImp(@"NSOcclusionDetectionView",@"viewDidMoveToWindow",true,(IMP)fake_viewDidMoveToWindow,(IMP*)&real_viewDidMoveToWindow);
	}
	else
	{
		[NSNotificationCenter.defaultCenter addObserverForName:@"NSApplicationWillFinishLaunchingNotification" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			// trace(@"retrying occlusion swizzles");
			
			occlusionSetup();
		}];
	}
}