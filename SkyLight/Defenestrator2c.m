@interface Wrapper:NSObject<DefenestratorWrapper>

@property(assign) int wid;
@property(assign) int sid;
@property(assign) CAContext* context;

-(instancetype)initWithWid:(int)wid context:(CAContext*)context;

@end

BOOL killValue;
dispatch_once_t killOnce;
BOOL d2cEnabled()
{
	dispatch_once(&killOnce,^()
	{
		killValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Amy_DisableD2C"];
	});
	
	return !killValue;
}

NSMutableDictionary<NSNumber*,Wrapper*>* wrappers;

Wrapper* defenestratorGetWrapper(int wid)
{
	return wrappers[[NSNumber numberWithInt:wid]];
}

dispatch_once_t closeHandlerOnce;
void closeHandler(int rdi_type,char* rsi_window,int rdx,void* rcx_context)
{
	int wid=*(int*)rsi_window;
	trace(@"D2C: destroy window %d",wid);
	wrappers[[NSNumber numberWithInt:wid]]=nil;
}

int SLSSetWindowLayerContext(int edi_cid,int esi_wid,CAContext* rdx_context)
{
	if(d2cEnabled())
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
	CommitBlock heapBlock=[block copy];
	[fuckedBlocks addObject:heapBlock];
	[heapBlock release];
}

// DP8 4ff80365371f - fallback case
// rdi transaction
// esi 1

void SLSTransactionCommit(void* rdi,int esi);

// DP8 4ff803653713 - softlink case
// rdi transaction
// esi bool or flag
// TODO: return

void SLSTransactionCommitUsingMethod(void* rdi,int esi)
{
	SLSTransactionCommit(rdi,esi);
	
	NSNumber* key=[NSNumber numberWithLong:(long)rdi];
	NSArray<CommitBlock>* blocks=commitBlocks[key];
	if(blocks)
	{
		for(CommitBlock block in blocks)
		{
			block();
		}
		commitBlocks[key]=nil;
	}
	
	for(CommitBlock block in fuckedBlocks)
	{
		block();
	}
	fuckedBlocks.removeAllObjects;
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
	
	dispatch_once(&closeHandlerOnce,^()
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

// credit Edu - nostub-ing this in DP1 almost wholly fixes window positioning

// DP1 4ff80414f8c6
// edi cid
// esi r12d - wid
// ecx r14d
// rdx something
// SL old - does not use xmm* and returns eax

// AppKit 12.5 DP3
// edi/esi right
// rdx - pointer to 2 doubles after each other (CGPoint/CGSize?)
// ecx - came from NSCGSDisplayConfiguration changeSeed

int SLSMoveWindowOnMatchingDisplayChangedSeed(int edi,int esi,void* rdx,int ecx);

// rdi transaction
// esi r12d - wid
// edx r14d
// xmm0
// xmm1
// TODO: return

void SLSTransactionMoveWindowOnMatchingDisplayChangedSeed(void* rdi,int esi,int edx,double xmm0,double xmm1)
{
	pushCommitBlock(rdi,^()
	{
		int cid=SLSMainConnectionID();
		
		// TODO: probably a CGPoint
		double thing[2]={xmm0,xmm1};
		SLSMoveWindowOnMatchingDisplayChangedSeed(cid,esi,thing,edx);
		
		/*Wrapper* wrapper=wrapperForWindow(esi);
		CGRect rect=wrapper.context.layer.bounds;
		SLSSetSurfaceBounds(cid,esi,wrapper.sid,rect);*/
	});
}

// TODO: debugging, remove

void* _NSSoftLinkingGetFrameworkFunction(NSString*,NSString*,char*,void*);

void* fake__NSSoftLinkingGetFrameworkFunction(NSString* rdi,NSString* rsi,char* rdx,void* rcx)
{
	void* result=_NSSoftLinkingGetFrameworkFunction(rdi,rsi,rdx,rcx);
	trace(@"softlink debug hook %@ %@ %s %p --> %p",rdi,rsi,rdx,rcx,result);
	return result;
}

DYLD_INTERPOSE(fake__NSSoftLinkingGetFrameworkFunction,_NSSoftLinkingGetFrameworkFunction)

// TODO: move any more of these to the D2C blocks system?
// slower but may fix some visual glitches

// forward Rim.m

void SLSWindowSetShadowProperties(unsigned int,NSDictionary*);

// DP8 7ff804061733
// rdi probably transaction
// esi probably wid
// rdx probably dictionary
// TODO: check return value

void SLSTransactionSetWindowShadowProperties(void* rdi,int esi,NSDictionary* rdx)
{
	SLSWindowSetShadowProperties(esi,rdx);
}

// 12.5 DP3 4ff8037d07a3
// edi probably wid
// esi probably bool or flags
// TODO: check return value
// TODO: move these all to Extern.h

void SLSWindowSetActiveShadowLegacy(int edi,int esi);

// DP8 7ff80406175a
// rdi probably transaction
// esi probably wid
// edx probably bool or flags
// TODO: check return value

void SLSTransactionSetWindowActiveShadowLegacy(void* rdi,int esi,int edx)
{
	SLSWindowSetActiveShadowLegacy(esi,edx);
}

// 12.5 DP3 4ff8037d0a66
// edi probably cid
// esi probably wid
// edx 0
// xmm0 0 sometimes, 1.05 sometimes, NSAutomaticFlatteningDelay sometimes...
// xmm1 -1
// xmm2 -1
// TODO: check return value

void SLSSetSurfaceLayerBackingOptions(int edi,int esi,int edx,double xmm0,double xmm1,double xmm2);

// DP8 7ff804061a28
// rdi probably transaction
// esi probably wid
// edx 0
// xmm0 0 sometimes, 1.05 sometimes, NSAutomaticFlatteningDelay sometimes
// xmm1 -1
// xmm2 -1
// TODO: check return value

void SLSTransactionSetSurfaceLayerBackingOptions(void* rdi,int esi,int edx,double xmm0,double xmm1,double xmm2)
{
	SLSSetSurfaceLayerBackingOptions(SLSMainConnectionID(),esi,edx,xmm0,xmm1,xmm2);
}

// DP8 7ff803766b2e
// edi cid (contextID)
// esi wid (windowNumber)
// rdx output parameter from CGSNewRegionWithRectList
// TODO: check return value

void SLSSetWindowEventShape(int edi,int esi,void* rdx);

// DP8 7ff804061718
// rdi probably transaction
// esi probably wid
// rdx ?
// TODO: check return value

void SLSTransactionSetWindowEventShape(void* rdi,int esi,void* rdx)
{
	SLSSetWindowEventShape(SLSMainConnectionID(),esi,rdx);
}

// 12.5 DP3 no obvious equivalent
// 4ff8037d092b
// edi probably wid
// rsi r13+0x70, jump based on bit 0x9 - 0x70 set by NSCGSWindow setDragShape:
// rdx r13+0x78, bit 0xa - setActivationShape:
// rcx r13+0x80, bit 0xb - setButtonShape:
// r8 r13+0x88, bit 0xc - setCommandModifierExclusionShape:
// TODO: check return value

void SLSSetWindowRegionsLegacy(int edi,void* rsi,void* rdx,void* rcx,void* r8);

// DP8 4ff8040618a1 (__NSCGSWindowMarkProperty__block_invoke_2)
// rdi probably transaction
// esi probably wid
// rdx r15+0x80, bit 0x9
// TODO: check return value

void SLSTransactionSetWindowDragRegion(void* rdi,int esi,void* rdx)
{
	SLSSetWindowRegionsLegacy(esi,rdx,NULL,NULL,NULL);
}

// DP8 4ff8040618c0
// rdi probably transaction
// esi probably wid
// rdx r15+0x88, bit 0xa
// TODO: return value

void SLSTransactionSetWindowActivationRegion(void* rdi,int esi,void* rdx)
{
	SLSSetWindowRegionsLegacy(esi,NULL,rdx,NULL,NULL);
}

// 0x90, bit 0xb
// TODO: return value

void SLSTransactionSetWindowButtonRegion(void* rdi,int esi,void* rdx)
{
	SLSSetWindowRegionsLegacy(esi,NULL,NULL,rdx,NULL);
}

// 0x98 - setCommandModifierExclusionShape, bit 0xc
// TODO: return value

void SLSTransactionSetWindowSpecialCommandRegion(void* rdi,int esi,void* rdx)
{
	SLSSetWindowRegionsLegacy(esi,NULL,NULL,NULL,rdx);
}

// 12.5 DP3 4ff8037d09d0
// edi cid
// esi wid
// edx bool or flags
// TODO: return value

void SLSSetWindowHasMainAppearance(int edi,int esi,int edx);

void SLSSetWindowHasKeyAppearance(int edi,int esi,int edx);

// DP8 4ff80406196c, 4ff804061963
// rdi probably transaction
// esi probably wid
// edx bool or flags
// TODO: return value

void SLSTransactionSetWindowHasMainAppearance(void* rdi,int esi,int edx)
{
	SLSSetWindowHasMainAppearance(SLSMainConnectionID(),esi,edx);
}

void SLSTransactionSetWindowHasKeyAppearance(void* rdi,int esi,int edx)
{
	SLSSetWindowHasKeyAppearance(SLSMainConnectionID(),esi,edx);
}

// 12.5 DP3
// edi probably wid
// rsi image
// edx 0xf
// same large stack thing
// TODO: return value

void SLSSetWindowCornerMask(int edi,void* rsi,int edx,CGRect stack);

// DP8 4ff804061882
// rdi transaction
// esi wid
// rdx [something image]
// ecx 0xf
// stack 16 * 2 bytes - CGRect?
// TODO: return value
// TODO: verify stack part
// note - Edu determined this somehow fixes CAPL

void SLSTransactionSetWindowCornerMask(void* rdi,int esi,void* rdx,int ecx,CGRect stack)
{
	SLSSetWindowCornerMask(esi,rdx,ecx,stack);
}

// 12.5 DP3 4ff8037d051c
// edi cid
// esi wid
// edx r13+0x10 - ?
// ecx 0
// xmm0 r13+0xb0 - ?
// xmm1 r13+0xb8 - ?
// TODO: return

void SLSSetWindowOriginRelativeToWindow(int edi,int esi,int edx,int ecx,double xmm0,double xmm1);

// DP8 4ff80406151f
// rdi transaction
// esi wid
// edx r15+0x10 - ?
// ecx 0
// xmm0 r15+0xc0 - ?
// xmm1 r15+0xc8 - ?
// TODO: return
// TODO: i don't think called at all

void SLSTransactionSetWindowOriginRelativeToWindow(void* rdi,int esi,int edx,int ecx,double xmm0,double xmm1)
{
	// trace(@"SLSTransactionSetWindowOriginRelativeToWindow shim %p %x %x %x %lf %lf",rdi,esi,edx,ecx,xmm0,xmm1);
	
	SLSSetWindowOriginRelativeToWindow(SLSMainConnectionID(),esi,edx,ecx,xmm0,xmm1);
}

// 12.5 DP3 4ff802f8561d
// edi rdi+0x20 - per crash message, cid
// esi rdi+0x24 - per crash message, wid
// edx wid - per crash message, "other window id"
// TODO: check return, i think int

int SLSAddWindowToWindowMovementGroup(int edi,int esi,int edx);

// DP8 4ff80405ccb4
// rdi rdi+0x20 - i think transaction
// esi rdi+0x28 - i think wid
// edx wid
// TODO: return

int SLSTransactionAddWindowToWindowMovementGroup(void* rdi,int esi,int edx)
{
	// trace(@"SLSTransactionAddWindowToWindowMovementGroup shim %p %x %x",rdi,esi,edx);
	
	return SLSAddWindowToWindowMovementGroup(SLSMainConnectionID(),esi,edx);
}

// 12.5 DP3 4ff802fc5221
// edi rdi+0x20 - i think cid
// esi rdi+0x24 - i think wid
// edx wid
// returns eax

int SLSRemoveWindowFromWindowMovementGroup(int edi,int esi,int edx);

// DP8 4ff80405cce7
// rdi rdi+0x20 - i think transaction
// esi rdi+0x28 - i think wid
// edx wid
// TODO: return

int SLSTransactionRemoveWindowFromWindowMovementGroup(void* rdi,int esi,int edx)
{
	// trace(@"SLSTransactionRemoveWindowFromWindowMovementGroup shim %p %x %x",rdi,esi,edx);
	
	return SLSRemoveWindowFromWindowMovementGroup(SLSMainConnectionID(),esi,edx);
}

// SLSTransactionSetWindowTransform3D - not referenced in DP8 AppKit
// DP8 WindowManager 10012407e
// rdi ?
// esi ?
// copies 0x80 bytes i think to the stack
// TODO: return
// TODO: no obvious equivalent in Mojave SL

void SLSTransactionSetWindowTransform3D(void* rdi,int esi,char stack[0x80])
{
	// trace(@"SLSTransactionSetWindowTransform3D stub %p %x %@ (stack object follows)",rdi,esi,NSThread.callStackSymbols);
	NSMutableString* s=NSMutableString.alloc.init;
	for(int i=0;i<0x80;i++)
	{
		[s appendFormat:@"%02x",stack[i]];
	}
	// trace(@"%@",s);
	s.release;
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
// nostub SLSTransactionRemoveSurface