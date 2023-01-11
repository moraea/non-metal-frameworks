// reimplemented Cycle Through Windows since i can't figure out why it's broken

// can't link AppKit

#define NSEventMaskKeyDown 0x400
#define NSEventModifierFlagShift 0x20000
#define NSEventModifierFlagCommand 0x100000

@interface NSEventLite:NSObject
+(void)addLocalMonitorForEventsMatchingMask:(long)mask handler:(NSEventLite* (^)(NSEventLite*))block;
-(long)modifierFlags;
-(NSString*)characters;
@end

@interface NSApplicationLite:NSObject
+(NSApplicationLite*)sharedApplication;
-(void)_cycleWindowsReversed:(BOOL)reversed;
@end

BOOL (*real_boolForKey)(NSUserDefaults* self,SEL sel,NSString* key);
BOOL fake_boolForKey(NSUserDefaults* self,SEL sel,NSString* key)
{
	if([key isEqualToString:@"_NSAppAllowsNonTrustedUGID"])
	{
		// trace(@"Cycle setugid hack: _NSAppAllowsNonTrustedUGID - bool");
		return true;
	}
	
	return real_boolForKey(self,sel,key);
}

id (*real_objectForKey)(NSUserDefaults* self,SEL sel,NSString* key);
id fake_objectForKey(NSUserDefaults* self,SEL sel,NSString* key)
{
	if([key isEqualToString:@"_NSAppAllowsNonTrustedUGID"])
	{
		// trace(@"Cycle setugid hack: _NSAppAllowsNonTrustedUGID - object");
		return @true;
	}
	
	return real_objectForKey(self,sel,key);
}

void cycleSetup()
{
	// cursed
	// VirtualBoxVM: (AppKit) The application with bundle ID org.virtualbox.app.VirtualBoxVM is running setugid(), which is not allowed. Exiting.
	
	if(issetugid())
	{
		// trace(@"Cycle setugid hack: enabling");
		
		swizzleImp(@"NSUserDefaults",@"objectForKey:",true,(IMP)fake_objectForKey,(IMP*)&real_objectForKey);
		swizzleImp(@"NSUserDefaults",@"boolForKey:",true,(IMP)fake_boolForKey,(IMP*)&real_boolForKey);
	}
	
	Class NSEvent=NSClassFromString(@"NSEvent");
	Class NSApplication=NSClassFromString(@"NSApplication");
	if(!NSEvent||!NSApplication)
	{
		return;
	}
	
	[NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEventLite*(NSEventLite* event)
	{
		if(event.modifierFlags&NSEventModifierFlagCommand)
		{
			if([event.characters isEqualToString:@"`"])
			{
				// trace(@"Cycle: handling %@",event);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
#if MAJOR<=12
				[[NSApplication sharedApplication] _cycleWindowsReversed:!!(event.modifierFlags&NSEventModifierFlagShift)];
#else
				[[NSApplication sharedApplication] _cycleWindowsBypassingWindowManagerReversed:!!(event.modifierFlags&NSEventModifierFlagShift)];
#endif
#pragma clang diagnostic pop
				
				return nil;
			}
		}
		
		return event;
	}];
}