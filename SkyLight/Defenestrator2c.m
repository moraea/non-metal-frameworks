@interface Wrapper:NSObject<DefenestratorWrapper>

@property(assign) int wid;
@property(assign) int sid;
@property(assign) CAContext* context;

-(instancetype)initWithWid:(int)wid context:(CAContext*)context;

@end

BOOL disableValue;
dispatch_once_t disableOnce;
BOOL disableD2C()
{
	dispatch_once(&disableOnce,^()
	{
		disableValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Amy.D2C.Disable"];
	});
	
	return disableValue;
}

BOOL disableBatchingValue;
dispatch_once_t disableBatchingOnce;
BOOL disableBatching()
{
	dispatch_once(&disableBatchingOnce,^()
	{
		disableBatchingValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Amy.D2C.DisableBatching"];
	});
	
	return disableBatchingValue;
}

dispatch_once_t defenestratorOnce;

NSMutableDictionary<NSNumber*,Wrapper*>* wrappers;

Wrapper* defenestratorGetWrapper(int wid)
{
	return wrappers[[NSNumber numberWithInt:wid]];
}

void closeHandler(int rdi_type,char* rsi_window,int rdx,void* rcx_context)
{
	int wid=*(int*)rsi_window;
	wrappers[[NSNumber numberWithInt:wid]]=nil;
}

int SLSSetWindowLayerContext(int edi_cid,int esi_wid,CAContext* rdx_context)
{
	if(!disableD2C())
	{
		NSNumber* key=[NSNumber numberWithInt:esi_wid];
		Wrapper* wrapper=[Wrapper.alloc initWithWid:esi_wid context:rdx_context].autorelease;
		if(wrappers[key])
		{
			wrappers[key]=nil;
		}
		wrappers[key]=wrapper;
	}
	
	return 0;
}

typedef dispatch_block_t CommitBlock;
NSMutableDictionary<NSNumber*,NSMutableArray<CommitBlock>*>* commitBlocks;
NSMutableArray<CommitBlock>* fuckedBlocks;

// D2C - associates a block with a transaction, to be run at commit time
// this guarantees visual syncronization as is expected with transactions
// and can be used to implement SLSTransaction* softlinks

void pushCommitBlock(void* transaction,CommitBlock block)
{
	if(disableBatching())
	{
		block();
		return;
	}
	
	CommitBlock heapBlock=[block copy];
	NSNumber* key=[NSNumber numberWithLong:(long)transaction];
	if(!commitBlocks[key])
	{
		commitBlocks[key]=NSMutableArray.alloc.init.autorelease;
	}
	[commitBlocks[key] addObject:heapBlock];
	[heapBlock release];
}

// D2C - hack for cases when we don't have a transaction pointer
// runs the block next time ANY transaction is committed
// TODO: works reasonably well but is obviously terrible

void pushFuckedBlock(CommitBlock block)
{
	if(disableBatching())
	{
		block();
		return;
	}
	
	CommitBlock heapBlock=[block copy];
	[fuckedBlocks addObject:heapBlock];
	[heapBlock release];
}

// TODO: no change, undo

void SLSTransactionCommit(void* rdi,int esi)
{
	int ranBlockCount=0;
	int ranFBlockCount=0;
	
	NSNumber* key=[NSNumber numberWithLong:(long)rdi];
	NSArray<CommitBlock>* blocks=commitBlocks[key];
	if(blocks)
	{
		for(CommitBlock block in blocks)
		{
			block();
			ranBlockCount++;
		}
		commitBlocks[key]=nil;
	}
	
	for(CommitBlock block in fuckedBlocks)
	{
		block();
		ranFBlockCount++;
	}
	fuckedBlocks.removeAllObjects;
	
	SLSTransactionCommi$(rdi,esi);
}

void SLSTransactionCommitUsingMethod(void* rdi,int esi)
{
	SLSTransactionCommit(rdi,esi);
}

NSMutableArray<dispatch_block_t>* onceBlocks;
NSMutableArray<DefenestratorBlock>* creationBlocks;
NSMutableArray<DefenestratorBlock>* destructionBlocks;
NSMutableArray<DefenestratorBlock>* updateBlocks;
void defenestratorRegisterOnce(dispatch_block_t block)
{
	dispatch_block_t heapBlock=[block copy];
	[onceBlocks addObject:heapBlock];
	[heapBlock release];
}
void defenestratorRegisterCreation(DefenestratorBlock block)
{
	DefenestratorBlock heapBlock=[block copy];
	[creationBlocks addObject:heapBlock];
	[heapBlock release];
}
void defenestratorRegisterDestruction(DefenestratorBlock block)
{
	DefenestratorBlock heapBlock=[block copy];
	[destructionBlocks addObject:heapBlock];
	[heapBlock release];
}
void defenestratorRegisterUpdate(DefenestratorBlock block)
{
	DefenestratorBlock heapBlock=[block copy];
	[updateBlocks addObject:heapBlock];
	[heapBlock release];
}

void defenestratorSetup()
{
	wrappers=NSMutableDictionary.alloc.init;
	commitBlocks=NSMutableDictionary.alloc.init;
	fuckedBlocks=NSMutableArray.alloc.init;
	
	onceBlocks=NSMutableArray.alloc.init;
	creationBlocks=NSMutableArray.alloc.init;
	destructionBlocks=NSMutableArray.alloc.init;
	updateBlocks=NSMutableArray.alloc.init;
}

@implementation Wrapper

-(instancetype)initWithWid:(int)wid context:(CAContext*)context
{
	self=super.init;
	
	int cid=SLSMainConnectionID();
	
	int sid=0;
	SLSAddSurface(cid,wid,&sid);
	SLSBindSurface(cid,wid,sid,4,0,context.contextId);
	SLSOrderSurface(cid,wid,sid,1,0);
	
	_wid=wid;
	_sid=sid;
	_context=context.retain;
	
	[context.layer addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
	
	dispatch_once(&defenestratorOnce,^()
	{
		SLSRegisterConnectionNotifyProc(cid,closeHandler,kCGSWindowIsTerminated,NULL);
		
		for(dispatch_block_t block in onceBlocks)
		{
			block();
		}
	});
	SLSRequestNotificationsForWindows(cid,&_wid,1);
	
	self.queueUpdate;
	
	for(DefenestratorBlock block in creationBlocks)
	{
		block(self);
	}
	
	return self;
}

-(void)queueUpdate
{
	pushFuckedBlock(^()
	{
		SLSSetSurfaceBounds(SLSMainConnectionID(),self.wid,self.sid,self.context.layer.bounds);
		
		for(DefenestratorBlock block in updateBlocks)
		{
			block(self);
		}
	});
}

-(void)observeValueForKeyPath:(NSString*)path ofObject:(NSObject*)object change:(NSDictionary*)change context:(void*)context
{
	self.queueUpdate;
}

-(void)dealloc
{
	for(DefenestratorBlock block in destructionBlocks)
	{
		block(self);
	}
	
	[self.context.layer removeObserver:self forKeyPath:@"bounds"];
	
	self.context.release;
	
	// TODO: any other cleanup?
}

@end

// credit Edu - largely fixes window positioning

void SLSTransactionMoveWindowOnMatchingDisplayChangedSeed(void* rdi,int esi,int edx,double xmm0,double xmm1)
{	
	pushCommitBlock(rdi,^()
	{	
		int cid=SLSMainConnectionID();
		
		CGPoint thing=CGPointMake(xmm0,xmm1);
		SLSMoveWindowOnMatchingDisplayChangedSeed(cid,esi,&thing,edx);
	});
}

// forward Rim.m

void SLSWindowSetShadowProperties(unsigned int,NSDictionary*);

// TODO: check return value (here and Extern.h)

void SLSTransactionSetWindowShadowProperties(void* rdi,int esi,NSDictionary* rdx)
{
	pushCommitBlock(rdi,^()
	{
		SLSWindowSetShadowProperties(esi,rdx);
	});
}

// TODO: check return value

void SLSTransactionSetWindowActiveShadowLegacy(void* rdi,int esi,int edx)
{
	pushCommitBlock(rdi,^()
	{
		SLSWindowSetActiveShadowLegacy(esi,edx);
	});
}

// TODO: check return value

void SLSTransactionSetSurfaceLayerBackingOptions(void* rdi,int esi,int edx,double xmm0,double xmm1,double xmm2)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetSurfaceLayerBackingOptions(SLSMainConnectionID(),esi,edx,xmm0,xmm1,xmm2);
	});
}

// TODO: check return value

void SLSTransactionSetWindowEventShape(void* rdi,int esi,void* rdx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowEventShape(SLSMainConnectionID(),esi,rdx);
	});
}

// TODO: check return value

void SLSTransactionSetWindowDragRegion(void* rdi,int esi,void* rdx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowRegionsLegacy(esi,rdx,NULL,NULL,NULL);
	});
}

// TODO: return value

void SLSTransactionSetWindowActivationRegion(void* rdi,int esi,void* rdx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowRegionsLegacy(esi,NULL,rdx,NULL,NULL);
	});
}

// TODO: return value

void SLSTransactionSetWindowButtonRegion(void* rdi,int esi,void* rdx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowRegionsLegacy(esi,NULL,NULL,rdx,NULL);
	});
}

// TODO: return value

void SLSTransactionSetWindowSpecialCommandRegion(void* rdi,int esi,void* rdx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowRegionsLegacy(esi,NULL,NULL,NULL,rdx);
	});
}

// TODO: return value

void SLSTransactionSetWindowHasMainAppearance(void* rdi,int esi,int edx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowHasMainAppearance(SLSMainConnectionID(),esi,edx);
	});
}

void SLSTransactionSetWindowHasKeyAppearance(void* rdi,int esi,int edx)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowHasKeyAppearance(SLSMainConnectionID(),esi,edx);
	});
}

// TODO: return value
// note - Edu determined this somehow fixes CAPL

void SLSTransactionSetWindowCornerMask(void* rdi,int esi,void* rdx,int ecx,CGRect stack)
{
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowCornerMask(esi,rdx,ecx,stack);
	});
}

// TODO: return
// TODO: i don't think called at all

void SLSTransactionSetWindowOriginRelativeToWindow(void* rdi,int esi,int edx,int ecx,double xmm0,double xmm1)
{
	// trace(@"SLSTransactionSetWindowOriginRelativeToWindow shim %p %x %x %x %lf %lf",rdi,esi,edx,ecx,xmm0,xmm1);
	
	pushCommitBlock(rdi,^()
	{
		SLSSetWindowOriginRelativeToWindow(SLSMainConnectionID(),esi,edx,ecx,xmm0,xmm1);
	});
}

// TODO: return

void SLSTransactionAddWindowToWindowMovementGroup(void* rdi,int esi,int edx)
{
	// trace(@"SLSTransactionAddWindowToWindowMovementGroup shim %p %x %x",rdi,esi,edx);
	
	pushCommitBlock(rdi,^()
	{
		SLSAddWindowToWindowMovementGroup(SLSMainConnectionID(),esi,edx);
	});
}

// TODO: return

void SLSTransactionRemoveWindowFromWindowMovementGroup(void* rdi,int esi,int edx)
{
	// trace(@"SLSTransactionRemoveWindowFromWindowMovementGroup shim %p %x %x",rdi,esi,edx);
	
	pushCommitBlock(rdi,^()
	{
		SLSRemoveWindowFromWindowMovementGroup(SLSMainConnectionID(),esi,edx);
	});
}

// TODO: return
// TODO: no obvious equivalent in Mojave SL

void SLSTransactionSetWindowTransform3D(void* rdi,int esi,char stack[0x80])
{
	/*trace(@"SLSTransactionSetWindowTransform3D stub %p %x %@ (stack object follows)",rdi,esi,NSThread.callStackSymbols);
	NSMutableString* s=NSMutableString.alloc.init;
	for(int i=0;i<0x80;i++)
	{
		[s appendFormat:@"%02x",stack[i]];
	}
	trace(@"%@",s);
	s.release;*/
}

// CG inverted colors workaround

NSArray* SLSHWCaptureWindowList(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags)
{
	NSArray* result=SLSHWCaptureWindowLis$(edi_cid,rsi_list,edx_count,ecx_flags);
	// trace(@"SLSHWCaptureWindowList %d %p %d %d %@ -> %@",edi_cid,rsi_list,edx_count,ecx_flags,NSThread.callStackSymbols,result);
	
	for(id image in result)
	{
		// TODO: bruh
		
		int* flags=(int*)(((char*)image)+0xa8);
		// trace(@"flags %x",flags);
		*flags=0x2002;
	}
	
	return result;
}

// still softlinked 13.1 DP3
// TODO: may not be exhaustive

// nostub SLSTransactionSetMenuBars
// nostub SLSTransactionSetSurfaceColorSpace
// nostub SLSTransactionSpaceFinishedResizeForRect
// nostub SLSTransactionSetMenuBarCompanionWindow
// nostub SLSTransactionEnsureSpaceSwitchToActiveProcess
// nostub SLSTransactionSystemStatusBarSetItemPrivacyIndicator
// nostub SLSTransactionReorderWindows
// nostub SLSTransactionAddWindowToWindowOrderingGroup
// nostub SLSTransactionRemoveWindowFromWindowOrderingGroup
// nostub SLSTransactionClearWindowOrderingGroup
// nostub SLSTransactionOrderWindowGroupFrontConditionally
// nostub SLSTransactionGetTransactionID
// nostub SLSTransactionSetWindowTags
// nostub SLSTransactionRemoveSurfaces