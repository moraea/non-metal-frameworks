// originally for Weather widget done button, but fixes a number of unresponsive Catalyst buttons
// TODO: does not solve the root issue

@interface UIWindowLite:NSObject
-(BOOL)isKeyWindow;
@end

UIWindowLite* (*real_WWCI)(UIWindowLite*,SEL,int);
UIWindowLite* fake_WWCI(UIWindowLite* self,SEL sel,int contextID)
{
	UIWindowLite* real=real_WWCI(self,sel,contextID);
	if(real)
	{
		return real;
	}
	
	UIWindowLite* window=nil;
	
	for(CAContext* context in CAContext.allContexts)
	{
		if([NSStringFromClass(context.layer.class) isEqualToString:@"UIWindowLayer"])
		{
			UIWindowLite* window2=*(UIWindowLite**)((char*)context.layer+0x20);
			if(window==nil||window2.isKeyWindow)
			{
				window=window2;
			}
		}
	}
	
	return window;
}

void doneSetup()
{
	swizzleImp(@"UIWindow",@"_windowWithContextId:",false,(IMP)fake_WWCI,(IMP*)&real_WWCI);
}