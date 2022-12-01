// TODO: bad

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
	
	NSMutableArray<UIWindowLite*>* windows=NSMutableArray.alloc.init.autorelease;
	
	for(CAContext* context in CAContext.allContexts)
	{
		if([NSStringFromClass(context.layer.class) isEqualToString:@"UIWindowLayer"])
		{
			UIWindowLite* window=*(UIWindowLite**)((char*)context.layer+0x20);
			if(window.isKeyWindow||windows.count==0)
			{
				[windows addObject:window];
			}
		}
	}
	
	return windows.lastObject;
}

void doneSetup()
{
	swizzleImp(@"UIWindow",@"_windowWithContextId:",false,(IMP)fake_WWCI,(IMP*)&real_WWCI);
}