// WebKit, Activity Monitor refresh based on window visibility

// TODO: results in occlusionState 8194/8192 visible/occluded, NSWindowOcclusionStateVisible == 2
// first-party apps work, but docs don't specify it should be checked bitwise

void (*real_setWindowNumber)(id self,SEL selector,unsigned long windowID);

void fake_setWindowNumber(id self,SEL selector,unsigned long windowID)
{
	real_setWindowNumber(self,selector,windowID);
	
	if(windowID!=-1)
	{
		SLSPackagesEnableWindowOcclusionNotifications(SLSMainConnectionID(),windowID,1,0);
	}
}

// NSLocalSavePanel _updateOKButtonEnabledState
// TODO: not ideal

BOOL fake_isOccluded(id self,SEL selector)
{
	trace(@"fake_isOccluded");
	
	return false;
}

// Safari extensions

BOOL fake_validateNoOcclusionSinceToken(id self,SEL selector,void* rdx)
{
	trace(@"fake_validateNoOcclusionSinceToken");
	
	return true;
}

@interface SLSecureCursorAssertion(Shim)
@end

@implementation SLSecureCursorAssertion(Shim)

+(instancetype)assertion
{
	trace(@"SLSecureCursorAssertion assertion");
	
	return SLSecureCursorAssertion.alloc.init.autorelease;
}

-(BOOL)isValid
{
	trace(@"SLSecureCursorAssertion isValid");
	
	return true;
}

@end

// TODO: temporary hack

BOOL fake_canEnableExtensions()
{
	trace(@"fake_canEnableExtensions");
	
	return true;
}

void safariSetup()
{
	if([process containsString:@"Safari"])
	{
		swizzleImp(@"ExtensionsPreferences",@"canEnableExtensions",true,(IMP)fake_canEnableExtensions,NULL);
	}
}

void occlusionSetup()
{
	swizzleImp(@"NSWindow",@"_setWindowNumber:",true,(IMP)fake_setWindowNumber,(IMP*)&real_setWindowNumber);
	swizzleImp(@"NSOcclusionDetectionView",@"isOccluded",true,(IMP)fake_isOccluded,NULL);
	swizzleImp(@"NSOcclusionDetectionView",@"validateNoOcclusionSinceToken:",true,(IMP)fake_validateNoOcclusionSinceToken,NULL);
	safariSetup();
}