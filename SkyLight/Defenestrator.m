// window backing surfaces

@interface ContextWrapper:NSObject

@property unsigned int connectionID;
@property unsigned int windowID;
@property unsigned int surfaceID;
@property(assign) CAContext* context;
@property(assign) char* backdrop;
@property(assign) BOOL activeBlurs;

-(void)updateBackdrop;

@end

NSMutableDictionary<NSNumber*,ContextWrapper*>* contextWrappers;

ContextWrapper* wrapperForWindow(unsigned int windowID)
{
	return contextWrappers[[NSNumber numberWithInt:windowID]];
}

#define NSVisualEffectBlendingModeBehindWindow 0

void defenestratorSetup()
{
	contextWrappers=NSMutableDictionary.alloc.init;
}

dispatch_once_t defenestratorOnce;

void closeHandler(unsigned int rdi_type,char* rsi_window,unsigned int rdx,id rcx_context)
{
	unsigned int windowID=*(unsigned int*)rsi_window;
	
	[contextWrappers removeObjectForKey:[NSNumber numberWithInt:windowID]];
}

void (*real__updateMaterialLayer)(NSVisualEffectViewLite* self,SEL selector);

// TODO: extremely naive

void fake__updateMaterialLayer(NSVisualEffectViewLite* self,SEL selector)
{
	if(self.blendingMode==NSVisualEffectBlendingModeBehindWindow)
	{
		unsigned int windowID=self.window.windowNumber;
		ContextWrapper* wrapper=wrapperForWindow(windowID);
		wrapper.activeBlurs=self._shouldUseActiveAppearance;
		wrapper.updateBackdrop;
	}
	
	real__updateMaterialLayer(self,selector);
}

BOOL blurBetaValue;
dispatch_once_t blurBetaOnce;
BOOL blurBeta()
{
	dispatch_once(&blurBetaOnce,^()
	{
		blurBetaValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_BlurBeta"];
	});
	
	return blurBetaValue;
}

@implementation ContextWrapper

-(instancetype)initWithConnectionID:(unsigned int)connectionID windowID:(unsigned int)windowID context:(CAContext*)context
{
	dispatch_once(&defenestratorOnce,^()
	{
		NSNotificationCenter* center=NSNotificationCenter.defaultCenter;
		
		SLSRegisterConnectionNotifyProc(connectionID,closeHandler,kCGSWindowIsTerminated,NULL);
		
		if(!blurBeta())
		{
			return;
		}
		
		swizzleImp(@"NSVisualEffectView",@"_updateMaterialLayer",true,(IMP)fake__updateMaterialLayer,(IMP*)&real__updateMaterialLayer);
	});
	
	_connectionID=connectionID;
	_windowID=windowID;
	_context=context.retain;
	
	SLSAddSurface(connectionID,windowID,(int*)&_surfaceID);
	SLSBindSurface(connectionID,windowID,_surfaceID,4,0,context.contextId);
	SLSOrderSurface(connectionID,windowID,_surfaceID,1,0);
	
	_backdrop=NULL;
	_activeBlurs=false;
	
	self.updateSurfaceBounds;
	
	unsigned int windowIDCopy=windowID;
	SLSRequestNotificationsForWindows(connectionID,(int*)&windowIDCopy,1);
	
	return self;
}

-(void)updateSurfaceBounds
{
	SLSSetSurfaceBounds(_connectionID,_windowID,_surfaceID,self.getBounds);
	
	if(blurBeta())
	{
		self.updateBackdrop;
	}
}

-(CGRect)getBounds
{
	CGRect bounds;
	SLSGetWindowBounds(_connectionID,_windowID,&bounds);
	
	bounds.origin.x=0;
	bounds.origin.y=0;
	
	return bounds;
}

-(void)removeBackdrop
{
	if(_backdrop)
	{
		SLSWindowBackdropRelease(_backdrop);
		_backdrop=NULL;
	}
}

-(void)updateBackdrop
{
	// TODO: exit early if unchanged activeBlurs and bounds
	
	self.removeBackdrop;
	
	if(!_activeBlurs)
	{
		return;
	}
	
	CGRect bounds=self.getBounds;
	
	// TODO: why
	bounds.size.width+=1;
	
	_backdrop=SLSWindowBackdropCreateWithLevelAndTintColor(_windowID,@"Mimic",@"Sover",0,NULL,bounds);
}

-(void)dealloc
{
	// TODO: do *Surface* calls need to be undone?
	
	_context.release;
	
	self.removeBackdrop;
	
	super.dealloc;
}

@end

unsigned int SLSSetWindowLayerContext(unsigned int edi_connectionID,unsigned int esi_windowID,CAContext* rdx_context)
{
	ContextWrapper* wrapper=[ContextWrapper.alloc initWithConnectionID:edi_connectionID windowID:esi_windowID context:rdx_context];
	NSNumber* key=[NSNumber numberWithInt:esi_windowID];
	contextWrappers[key]=wrapper;
	wrapper.release;
	
	return 0;
}

// TODO: non ideal way to detect bounds change, but makes visual synchronization easy

unsigned int SLSShapeWindowInWindowCoordinates(unsigned int edi_connectionID,unsigned int esi_windowID,char* rdx_region,unsigned int ecx,unsigned int r8d,unsigned int r9d,unsigned int stack)
{
	unsigned int result=SLSShapeWindowInWindowCoordinate$(edi_connectionID,esi_windowID,rdx_region,ecx,r8d,r9d,stack);
	
	wrapperForWindow(esi_windowID).updateSurfaceBounds;
	
	return result;
}
