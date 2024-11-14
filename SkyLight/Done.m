// fix a number of unresponsive Catalyst buttons
// TODO: still does not solve the root issue

void (*real_setContextId)(CALayer*,SEL,int);
void fake_setContextId(CALayer* self,SEL sel,int hostedContextID)
{
	real_setContextId(self,sel,hostedContextID);
	
	CAContext* hostedContext=[CAContext contextWithId:hostedContextID];
	CALayer* hostedLayer=hostedContext.layer;
	
	NSString* name=NSStringFromClass(hostedLayer.class);
	if([name isEqual:@"_NSViewBackingLayer"]||[name isEqual:@"NSViewBackingLayer"])
	{
		// TODO: not sure if this method is on NSViewBackingLayer or CALayer and im too lazy to check atm
		
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
		[hostedLayer setAllowsHitTesting:false];
#pragma clang diagnostic pop
	}
}

void doneSetup()
{
	swizzleImp(@"CALayerHost",@"setContextId:",true,(IMP)fake_setContextId,(IMP*)&real_setContextId);
}

// Ventura System Settings hover controls (Bluetooth button, dropdowns)

typedef void (^ContextV2Block)(int edi_contextID,int esi_flag);
NSMutableArray<ContextV2Block>* contextV2Blocks;
dispatch_once_t contextV2Once;

void contextV2Callback(int edi_type,long* rsi,int edx)
{
	int contextID=*rsi;
	int flag=(*rsi)>>0x20;
	
	for(ContextV2Block block in contextV2Blocks)
	{
		block(contextID,flag);
	}
}

void SLSInstallRemoteContextNotificationHandlerV2(NSString* rdi_key,ContextV2Block rsi_block)
{
	ContextV2Block heapBlock=[rsi_block copy];
	dispatch_once(&contextV2Once,^()
	{
		contextV2Blocks=NSMutableArray.alloc.init;
		SLSRegisterConnectionNotifyProc(SLSMainConnectionID(),contextV2Callback,0x332,nil);
	});
	[contextV2Blocks addObject:heapBlock];
	[heapBlock release];
}
