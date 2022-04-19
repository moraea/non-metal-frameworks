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

void cycleSetup()
{
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
				[[NSApplication sharedApplication] _cycleWindowsReversed:!!(event.modifierFlags&NSEventModifierFlagShift)];
				return nil;
			}
		}
		
		return event;
	}];
}