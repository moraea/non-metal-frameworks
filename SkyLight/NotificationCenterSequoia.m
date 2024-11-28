// disable blur behind widgets for now

void (*real_setFilters)(CALayer*,SEL,NSArray*);

void fake_setFilters(CALayer* self,SEL sel,NSArray* filters)
{
	if([self.name isEqual:@"blurLayer"])
	{
		return;
	}
	
	real_setFilters(self,sel,filters);
}

void notificationCenterSetup()
{
	if([process isEqual:@"/System/Library/CoreServices/NotificationCenter.app/Contents/MacOS/NotificationCenter"])
	{
		swizzleImp(@"CALayer",@"setFilters:",true,(IMP)fake_setFilters,(IMP*)&real_setFilters);
	}
}
