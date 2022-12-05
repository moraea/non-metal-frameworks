// work around lifecycle issues (can't quit, 1200 second crash)

BOOL (*real_addCommitHandler)(CATransaction*,SEL,void*,int);
BOOL fake_addCommitHandler(CATransaction* self,SEL sel,void* rdx_block,int ecx_phase)
{
	if(ecx_phase==5)
	{
		ecx_phase=4;
	}
	
	real_addCommitHandler(self,sel,rdx_block,ecx_phase);
	
	return true;
}

#ifdef MOJ

// fix upside-down AppKit layers in UIKit apps

int* getLayerFlags(CALayer* layer)
{
	char* layerC=*(char**)(((char*)layer)+0x10);
	return (int*)(layerC+0x4);
}

void (*real_setLayer)(NSObject*,SEL,CALayer*);
void fake_setLayer(NSObject* self,SEL sel,CALayer* layer)
{
	NSDictionary* options=[self options];
	if(((NSNumber*)options[kCAContextReversesContentsAreFlippedInCatalystEnvironment]).boolValue)
	{
		*getLayerFlags(layer)|=0x400000;
	}
	
	real_setLayer(self,sel,layer);
}

// fix crashes due to CALayer.delegate being released prematurely
// TODO: confirm there is no memory leak

@interface CALayer(Shim)
@end

static char KEY_RETAINED_DELEGATE;
BOOL delegateWasRetained(NSObject* delegate)
{
	if(!delegate)
	{
		return false;
	}
	
	NSNumber* value=objc_getAssociatedObject(delegate,&KEY_RETAINED_DELEGATE);
	
	return value.boolValue;
}
void setDelegateWasRetained(NSObject* delegate,BOOL flag)
{
	if(!delegate)
	{
		return;
	}
	
	objc_setAssociatedObject(delegate,&KEY_RETAINED_DELEGATE,[NSNumber numberWithBool:flag],OBJC_ASSOCIATION_RETAIN);
}
void releaseLayerDelegateIfNecessary(CALayer* layer)
{
	NSObject* delegate=[layer delegate];
	if(delegateWasRetained(delegate))
	{
		setDelegateWasRetained(delegate,false);
		delegate.release;
	}
}

@implementation CALayer(Shim)

-(void)setUnsafeUnretainedDelegate:(NSObject*)rdx
{
	[self setDelegate:rdx];
	
	rdx.retain;
	setDelegateWasRetained(rdx,true);
}

-(NSObject*)unsafeUnretainedDelegate
{
	return [self delegate];
}

@end

void (*real_setDelegate)(CALayer*,SEL,NSObject*);
void fake_setDelegate(CALayer* self,SEL sel,NSObject* delegate)
{
	releaseLayerDelegateIfNecessary(self);
	
	real_setDelegate(self,sel,delegate);
}

void (*real_dealloc)(CALayer*,SEL);
void fake_dealloc(CALayer* self,SEL sel)
{
	releaseLayerDelegateIfNecessary(self);
	
	real_dealloc(self,sel);
}

#endif

void catalystSetup()
{
	swizzleImp(@"CATransaction",@"addCommitHandler:forPhase:",false,(IMP)fake_addCommitHandler,(IMP*)&real_addCommitHandler);
	
#ifdef MOJ
	swizzleImp(@"CALayer",@"setDelegate:",true,(IMP)fake_setDelegate,(IMP*)&real_setDelegate);
	swizzleImp(@"CALayer",@"dealloc",true,(IMP)fake_dealloc,(IMP*)&real_dealloc);
	
	if(_CFMZEnabled())
	{
		swizzleImp(@"CAContextImpl",@"setLayer:",true,(IMP)fake_setLayer,(IMP*)&real_setLayer);
	}
#endif
}