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

// Ventura System Settings hover controls (Bluetooth button, dropdowns)

typedef void (^ContextV2Block)(int edi_contextID,int esi_flag);
NSMutableArray<ContextV2Block>* contextV2Blocks;
dispatch_once_t contextV2Once;

void contextV2Callback(int edi_type,long* rsi,int edx)
{
	int contextID=*rsi;
	int flag=(*rsi)>>0x20;
	
	// trace(@"contextV2Callback %x %x %x (%x blocks)",contextID,flag,edx,contextV2Blocks.count);
	
	for(ContextV2Block block in contextV2Blocks)
	{
		block(contextID,flag);
	}
}

void SLSInstallRemoteContextNotificationHandlerV2(NSString* rdi_key,ContextV2Block rsi_block)
{
	// trace(@"SLSInstallRemoteContextNotificationHandlerV2 %@ %p",rdi_key,rsi_block);
	ContextV2Block heapBlock=[rsi_block copy];
	dispatch_once(&contextV2Once,^()
	{
		contextV2Blocks=NSMutableArray.alloc.init;
		SLSRegisterConnectionNotifyProc(SLSMainConnectionID(),contextV2Callback,0x332,nil);
	});
	[contextV2Blocks addObject:heapBlock];
	[heapBlock release];
}