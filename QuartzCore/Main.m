// TODO: re-test all now that we're downgrading to Mojave
// TODO: refactor into several files like SL shims

#import "Utils.h"

@interface CAPresentationModifierGroup(Shim)
@end

@implementation CAPresentationModifierGroup(Shim)

-(void)flushWithTransaction
{
	[self flush];
}

@end

BOOL brightnessHack;

// animations
// exploit existing key/value storage on CATransaction

int transactionBoolCount=0;
NSString* transactionFakeKey(int key)
{
	return [NSString stringWithFormat:@"fake%d",key];
}

@interface CATransaction(Shim)
@end

@implementation CATransaction(Shim)

+(void)setBoolValue:(BOOL)value forKey:(int)key
{
	[self setValue:[NSNumber numberWithBool:value] forKey:transactionFakeKey(key)];
}

+(BOOL)boolValueForKey:(int)key
{
	// MinhTon's fix for brightness slider on MacBook5,1
	// TODO: a mystery
	
	if(brightnessHack)
	{
		return false;
	}
	
	BOOL result=((NSNumber*)[self valueForKey:transactionFakeKey(key)]).boolValue;
	
	return result;
}

+(int)registerBoolKey
{
	transactionBoolCount++;
	
	return transactionBoolCount;
}

@end

// weird Catalyst crash
// TODO: look at it again

BOOL (*real_ACHFP)(CATransaction*,SEL,void*,int);
BOOL fake_ACHFP(CATransaction* self,SEL sel,void* rdx_block,int rcx_phase)
{
	// causes a hard crash in real function
	// silently return instead
	
	if(rcx_phase==5||rcx_phase==0xffffffff)
	{
		return true;
	}
	
	real_ACHFP(self,sel,rdx_block,rcx_phase);
	
	// always return success
	
	return true;
}

// SiriNCService not appearing

@interface CAFenceHandle(Shim)<NSSecureCoding>
@end

@implementation CAFenceHandle(Shim)

+(instancetype)newFenceFromDefaultServer
{
	trace(@"CAFenceHandle newFenceFromDefaultServer %@",NSThread.callStackSymbols);
	return CAFenceHandle.alloc.init;
}

+(BOOL)supportsSecureCoding
{
	trace(@"CAFenceHandle supportsSecureCoding %@",NSThread.callStackSymbols);
	return true;
}

-(instancetype)initWithCoder:(NSCoder*)coder
{
	self=self.init;
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
}

@end

// private, can't use a category to add missing symbols
// TODO: generate via Stubber, make public, or SOMETHING better than this...

void doNothing()
{
}

void fixCAContextImpl()
{
	Class CAContextImpl=NSClassFromString(@"CAContextImpl");
	class_addMethod(CAContextImpl,@selector(addFence:),(IMP)doNothing,"v@:@");
	class_addMethod(CAContextImpl,@selector(transferSlot:toContextWithId:),(IMP)doNothing,"v@:@@");
}

// TODO: check necessary

@interface CALayer(Shim)
@end

@implementation CALayer(Shim)

-(void)setUnsafeUnretainedDelegate:(id)rdx
{
	[self setDelegate:rdx];
}

-(id)unsafeUnretainedDelegate
{
	return [self delegate];
}

@end

// videos not playing

// TODO: check signatures, especially return value

long CAImageQueueInsertImage(void* rdi_queue,int esi,void* rdx_surface,int ecx,void* r8_function,void* r9,double xmm0);
long CAImageQueueInsertImageWithRotation(void* rdi_queue,int esi,void* rdx,int ecx,int r8d,void* r9_function,double xmm0,void* stack)
{
	// trace(@"CAImageQueueInsertImageWithRotation %p %d %p %d %d %p %lf %p %@",rdi_queue,esi,rdx,ecx,r8d,r9_function,xmm0,stack,NSThread.callStackSymbols);
	
	// TODO: not sure of order of 32-bit parameters
	// and clearly the lack of rotation will pose a problem at some point
	return CAImageQueueInsertImage(rdi_queue,esi,rdx,ecx,r9_function,stack,xmm0);
}

__attribute__((constructor))
void load()
{
	swizzleLog=false;
	traceLog=true;
	
	swizzleImp(@"CATransaction",@"addCommitHandler:forPhase:",false,(IMP)fake_ACHFP,(IMP*)&real_ACHFP);
	
	fixCAContextImpl();
	
	brightnessHack=[NSProcessInfo.processInfo.arguments[0] isEqualToString:@"/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter"];
}