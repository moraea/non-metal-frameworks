// Control Center fade out
// TODO: check necessary

#if MAJOR>=12

@interface CAPresentationModifierGroup(Shim)
@end

@implementation CAPresentationModifierGroup(Shim)

-(void)flushWithTransaction
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
	[self flush];
#pragma clang diagnostic pop
}

@end

#endif

// system-wide animations (e.g. Finder desktop stacks)

#if defined(CAT) || defined(MOJ)

BOOL brightnessHack;

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

void animationsSetup()
{
	// removed Cat/Mojave check here because it's in Main - Amy
	brightnessHack=[process isEqualToString:@"/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter"];
}

#endif