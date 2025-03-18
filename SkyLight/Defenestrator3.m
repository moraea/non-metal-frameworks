@interface Wrapper:NSObject<DefenestratorWrapper>

@property(assign) int wid;
@property(assign) int sid;
@property(assign) CAContext* context;
@property(assign) CALayer* trackedLayer;

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

NSLock* arraysLock=nil;
dispatch_once_t arraysLockOnce;

void lockArrays()
{
	dispatch_once(&arraysLockOnce,^()
	{
		arraysLock=NSLock.alloc.init;
	});
	
	arraysLock.lock;
}

void unlockArrays()
{
	arraysLock.unlock;
}

// D2C - associates a block with a transaction, to be run at commit time
// this guarantees visual syncronization as is expected with transactions
// and can be used to implement SLSTransaction* softlinks

// TODO: may be able to use _SLSTransactionCommitAction instead

void pushCommitBlock(void* transaction,CommitBlock block)
{
	if(disableBatching())
	{
		block();
		return;
	}
	
	lockArrays();
	
	CommitBlock heapBlock=[block copy];
	NSNumber* key=[NSNumber numberWithLong:(long)transaction];
	if(!commitBlocks[key])
	{
		commitBlocks[key]=NSMutableArray.alloc.init.autorelease;
	}
	[commitBlocks[key] addObject:heapBlock];
	[heapBlock release];
	
	unlockArrays();
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
	
	lockArrays();
	
	CommitBlock heapBlock=[block copy];
	[fuckedBlocks addObject:heapBlock];
	[heapBlock release];
	
	unlockArrays();
}

// TODO: move back to SLSTransactionCommitUsingMethod?

void SLSTransactionCommit(void* rdi,int esi)
{
	lockArrays();
	
	NSNumber* key=[NSNumber numberWithLong:(long)rdi];
	NSArray<CommitBlock>* blocks=commitBlocks[key];
	if(blocks)
	{
		NSArray<CommitBlock>* blocksTemp=blocks.copy;
		for(CommitBlock block in blocksTemp)
		{
			block();
		}
		blocksTemp.release;
		commitBlocks[key]=nil;
	}
	
	NSArray<CommitBlock>* fuckedTemp=fuckedBlocks.copy;
	for(CommitBlock block in fuckedTemp)
	{
		block();
	}
	fuckedTemp.release;
	fuckedBlocks.removeAllObjects;
	
	SLSTransactionCommi$(rdi,esi);
	
	unlockArrays();
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

void defenestrator3Setup(); // TODO

void defenestratorSetup()
{
	wrappers=NSMutableDictionary.alloc.init;
	commitBlocks=NSMutableDictionary.alloc.init;
	fuckedBlocks=NSMutableArray.alloc.init;
	
	onceBlocks=NSMutableArray.alloc.init;
	creationBlocks=NSMutableArray.alloc.init;
	destructionBlocks=NSMutableArray.alloc.init;
	updateBlocks=NSMutableArray.alloc.init;
	
#if MAJOR>=14
	defenestrator3Setup();
#endif
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
	
	[context addObserver:self forKeyPath:@"layer" options:0 context:NULL];
	
	if(context.layer)
	{
		[context.layer addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
		_trackedLayer=context.layer;
	}
	
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
	// sometimes context.layer now gets changed (Dock)
	// so we have to do extra bookkeeping to avoid KVO crashes...
	
	if([path isEqual:@"layer"])
	{
		if(_trackedLayer)
		{
			[_trackedLayer removeObserver:self forKeyPath:@"bounds"];
		}
		
		[_context.layer addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
		_trackedLayer=_context.layer;
	}
	
	self.queueUpdate;
}

-(void)dealloc
{
	for(DefenestratorBlock block in destructionBlocks)
	{
		block(self);
	}
	
	[self.context removeObserver:self forKeyPath:@"layer"];
	
	if(_trackedLayer)
	{
		[_trackedLayer removeObserver:self forKeyPath:@"bounds"];
	}
	
	self.context.release;
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

NSArray* uninvertScreenshots(NSArray* images)
{
	/*
	
	hw_capture_window_list_common sets kCGImageProviderIsARGB8888 when making CGImage
	new CG doesn't check for this flag, so byte order is wrong
	previously we had a hack to clobber CGImage flags in-place, but this was brittle and broke on Sequoia
	this time, just use public APIs unless it's noticeably slower?
	
	*/
	
	NSMutableArray* newImages=NSMutableArray.alloc.init;
	
	for(long index=0;index<images.count;index++)
	{
		CGImageRef image=(CGImageRef)images[index];
		
		CGDataProviderRef data=CGImageGetDataProvider(image);
		long width=CGImageGetWidth(image);
		long height=CGImageGetHeight(image);
		long bitsPerComponent=CGImageGetBitsPerComponent(image);
		long bitsPerPixel=CGImageGetBitsPerPixel(image);
		long bytesPerRow=CGImageGetBytesPerRow(image);
		CGColorSpaceRef space=CGImageGetColorSpace(image);
		BOOL interpolate=CGImageGetShouldInterpolate(image);
		CGColorRenderingIntent intent=CGImageGetRenderingIntent(image);
		
		CGBitmapInfo fixedBitmapInfo=kCGImageAlphaFirst|kCGImageByteOrder32Little;
		
		CGImageRef newImage=CGImageCreate(width,height,bitsPerComponent,bitsPerPixel,bytesPerRow,space,fixedBitmapInfo,data,NULL,interpolate,intent);
		[newImages addObject:(id)newImage];
		CFRelease(newImage);
	}
	
	images.release;
	
	return newImages;
}

// TODO: return

void SLSTransactionWait(void* rdi)
{
	// TODO: doesn't work (hangs) because block runs at commit time
	// and this is supposed to return when it's destroyed, not committed
	// have to hook 2c9d28?
	
	/*dispatch_semaphore_t semaphore=dispatch_semaphore_create(0);
	pushCommitBlock(rdi,^()
	{
		trace(@"SLSTransactionWait signal %p %p",rdi,semaphore);
		dispatch_semaphore_signal(semaphore);
	});
	trace(@"SLSTransactionWait wait %p %p",rdi,semaphore);
	dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);
	trace(@"SLSTransactionWait resume %p %p",rdi,semaphore);
	semaphore.release;*/
}

// disabled (Ventura)

// no/stub SLSTransactionSetMenuBars
// no/stub SLSTransactionSetSurfaceColorSpace
// no/stub SLSTransactionSpaceFinishedResizeForRect
// no/stub SLSTransactionSetMenuBarCompanionWindow
// no/stub SLSTransactionEnsureSpaceSwitchToActiveProcess
// no/stub SLSTransactionSystemStatusBarSetItemPrivacyIndicator
// no/stub SLSTransactionReorderWindows
// no/stub SLSTransactionAddWindowToWindowOrderingGroup
// no/stub SLSTransactionRemoveWindowFromWindowOrderingGroup
// no/stub SLSTransactionClearWindowOrderingGroup
// no/stub SLSTransactionOrderWindowGroupFrontConditionally
// no/stub SLSTransactionGetTransactionID
// no/stub SLSTransactionSetWindowTags
// no/stub SLSTransactionRemoveSurfaces

// Sonoma DP1 softlinks (AppKit)

// no/stub SLSStatusBarCopyItemLayout
// no/stub SLSTransactionSystemStatusBarResetLayout
// no/stub SLSTransactionSystemStatusBarSetLayoutIndex
// no/stub SLSTransactionClearWindowCornerRadius
// no/stub SLSTransactionSetWindowBoundsPath

// TODO: workaround, Renamer-ed for Defenestrator1

unsigned int SLSShapeWindowInWindowCoordinates(unsigned int edi_connectionID,unsigned int esi_windowID,char* rdx_region,unsigned int ecx,unsigned int r8d,unsigned int r9d,unsigned int stack)
{
	return SLSShapeWindowInWindowCoordinate$(edi_connectionID,esi_windowID,rdx_region,ecx,r8d,r9d,stack);
}

// forward WindowFlags.m

unsigned int SLSNewWindowWithOpaqueShape(unsigned int edi_connectionID,unsigned int esi,char* rdx_region,char* rcx_region,unsigned int r8d,char* r9,unsigned long stack1_windowID,unsigned long stack2,double xmm0,double xmm1);

// existed for a while but only used in Dock as of Sonoma

void* SLSNewWindowWithOpaqueShapeAndContext(int edi_cid,int esi_5,void* rdx_region,void* rcx_region,int r8d_1,void* r9,double xmm0,double xmm1,int stack_0x40,int* stack_widOut,CAContext* stack_context)
{
	int myWid=0;
	SLSNewWindowWithOpaqueShape(edi_cid,esi_5,rdx_region,rcx_region,r8d_1,r9,stack_0x40,(unsigned long)&myWid,xmm0,xmm1);
	SLSSetWindowLayerContext(edi_cid,myWid,stack_context);
	
	*stack_widOut=myWid;
	
	return NULL;
}

void SLSEnsureSpaceSwitchToActiveProcess();

void SLSTransactionEnsureSpaceSwitchToActiveProcess(void* rdi_trans)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSEnsureSpaceSwitchToActiveProcess();
	});
}

void SLSAddWindowToWindowOrderingGroup(int edi_cid,int esi_wid,int edx_relativeWid,int ecx_above);

void SLSTransactionAddWindowToWindowOrderingGroup(void* rdi_trans,int edx_relativeWid,int ecx_above,int esi_wid)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSAddWindowToWindowOrderingGroup(SLSMainConnectionID(),esi_wid,edx_relativeWid,ecx_above);
	});
}

void SLSTransactionOrderWindowGroup(void* rdi_trans,int esi_wid,int edx_op,int ecx_relativeWid);

void SLSOrderFrontConditionally(int edi_cid,int esi_wid,void* rdx_timestamp);

void SLSTransactionOrderWindowGroupFrontConditionally(void* rdi_trans,int esi_wid,void* rdx_timestamp)
{
	// TODO: should use the other function (per Ventura softlink) but doesn't work?
	
	SLSTransactionOrderWindowGroup(rdi_trans,esi_wid,1,0);
	
	/*pushCommitBlock(rdi_trans,^()
	{
		SLSOrderFrontConditionally(SLSMainConnectionID(),esi_wid,rdx_timestamp);
	});*/
}

void SLSRemoveFromOrderingGroup(int edi_cid,int esi_wid);

void SLSTransactionRemoveWindowFromWindowOrderingGroup(void* rdi_trans,int esi_wid)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSRemoveFromOrderingGroup(SLSMainConnectionID(),esi_wid);
	});
}

void SLSClearWindowOrderingGroup(int edi_cid,int esi_wid);

void SLSTransactionClearWindowOrderingGroup(void* rdi_trans,int esi_wid)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSClearWindowOrderingGroup(SLSMainConnectionID(),esi_wid);
	});
}

void SLSReorderWindows(int edi_cid);

void SLSTransactionReorderWindows(void* rdi_trans)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSReorderWindows(SLSMainConnectionID());
	});
}

void SLSPostCoordinatedDistributedNotification(int edi_cid,int esi_note,void* rdx_block);

// softlinked in loginwindow

// nostub SLSPostCoordinatedDistributedNotificationFenced

/*void SLSPostCoordinatedDistributedNotificationFenced(int edi_cid,int esi_note,int edx_port,void* rcx_block)
{
	SLSPostCoordinatedDistributedNotification(edi_cid,esi_note,rcx_block);
}*/

// hack for blank wallpaper

CAContext* (*real_contextWithCGSConnection)(id,SEL,int,NSDictionary*);

CAContext* fake_contextWithCGSConnection(id meta,SEL sel,int cid,NSDictionary* options)
{
	if(cid==0)
	{
		// TODO: this shouldn't be necessary. where is WallpaperAgent getting the cid?
		
		cid=SLSMainConnectionID();
	}
	
	return real_contextWithCGSConnection(meta,sel,cid,options);
}

// Sonoma-specific stuff

void dockHackDisplayReconfigured(CGDirectDisplayID display,CGDisplayChangeSummaryFlags flags,void* userInfo)
{
	if((flags&kCGDisplaySetModeFlag)!=0)
	{
		// trace(@"Dock Hack: reconfigured %ld x %ld",CGDisplayPixelsWide(display),CGDisplayPixelsHigh(display));
		
		for(Wrapper* wrapper in wrappers.allValues)
		{
			// trace(@"Dock Hack: force window update %@",wrapper);
			
			wrapper.queueUpdate;
		}
	}
}

#if MAJOR>=14
void defenestrator3Setup()
{
	if(earlyBoot)
	{
		return;
	}
	
	swizzleImp(@"CAContext",@"contextWithCGSConnection:options:",false,(IMP)fake_contextWithCGSConnection,(IMP*)&real_contextWithCGSConnection);
	
	// TODO: the infamous Dock Hack, kill asap...
	// at least it's not hardcoded 1440x900 and uses The Defenestrator API, right? 🤷🏻‍♀️
	// some sort of WSCA listening issue (not WM) that doesn't affect AppKit apps
	
	if([process containsString:@"Dock.app/Contents/MacOS/Dock"])
	{
		defenestratorRegisterOnce(^()
		{
			CGDisplayRegisterReconfigurationCallback(dockHackDisplayReconfigured,NULL);
			
			defenestratorRegisterUpdate(^(NSObject<DefenestratorWrapper>* wrapper)
			{
				CGRect rect=wrapper.context.layer.bounds;
				
				if(rect.size.width<1||rect.size.height<1)
				{
					// trace(@"Dock size hack %@",NSStringFromRect(rect));
					
					int display=CGMainDisplayID();
					
					rect.size=CGSizeMake(CGDisplayPixelsWide(display),CGDisplayPixelsHigh(display));
					
					SLSSetSurfaceBounds(SLSMainConnectionID(),wrapper.wid,wrapper.sid,rect);
				}
			});
		});
	}
}
#endif

void* SLSSetWindowTags(int edi_cid,int esi_wid,long rdx,int ecx);
void* SLSClearWindowTags(int edi_cid,int esi_wid,long rdx,int ecx);

void* SLSTransactionSetWindowTags(int rdi_trans,int esi_wid,long rdx,int ecx,int r8d_bool)
{
	if(r8d_bool==0)
	{
		return SLSSetWindowTags(SLSMainConnectionID(),esi_wid,rdx,ecx);
	}
	else
	{
		return SLSClearWindowTags(SLSMainConnectionID(),esi_wid,rdx,ecx);
	}
}

int SLPSSetFrontProcessWithOptions(long* rdi,int esi,long rdx);

int SLSSetFrontProcessWithInfo(long* rdi,int esi,long rdx,NSDictionary* rcx)
{
	// TODO: this is much more complex, rcx has various keys, and supposed to skip the SLPS path entirely if ANY are present
	// however it seems we can get away with just this 1 check to "fix" the window unfocusing glitch
	
	if(!((NSNumber*)rcx[@"kSLSSetFrontProcessIgnoringOtherApps"]).boolValue)
	{
		return 0;
	}
	
	return SLPSSetFrontProcessWithOptions(rdi,esi,rdx);
}

//idk if this is correct but works on my machine

void SLSSetMenuBarCompanionWindow(int edi_cid,int esi,int rdx,double xmm0);

void SLSTransactionSetMenuBarCompanionWindow(void* rdi_trans,int esi,int rdx,double xmm0)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSSetMenuBarCompanionWindow(SLSMainConnectionID(),esi,rdx,xmm0);
	});
}

void SLSSpaceFinishedResizeForRect(int edi_cid,int esi,double xmm0,double xmm1);

void SLSTransactionSpaceFinishedResizeForRect(void* rdi_trans,int esi,double xmm0,double xmm1)
{
	pushCommitBlock(rdi_trans,^()
	{
		SLSSpaceFinishedResizeForRect(SLSMainConnectionID(),esi,xmm0,xmm1);
	});
}

// workaround safari exit full screen - softlink
// no/stub SLSTransactionAddPostDecodeAction
// softlink removed in 15.4, shim required to exit YouTube fullscreen in Safari

void SLSTransactionAddPostDecodeAction(void* rdi_transaction,void (^rsi_block)(void* transaction))
{
	// trace(@"SLSTransactionAddPostDecodeAction %p %p %@",rdi_transaction,rsi_block,NSThread.callStackSymbols);
	
	void (^safeBlock)(void*)=[rsi_block copy];
	
	pushCommitBlock(rdi_transaction,^()
	{
		safeBlock(rdi_transaction);
		
		[safeBlock release];
	});
}
