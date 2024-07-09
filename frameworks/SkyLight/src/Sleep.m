// display sleep
// from reversed Monterey SkyLight

dispatch_once_t displaySleepOnce;
io_registry_entry_t displaySleepEntry;

unsigned int SLSDisplayManagerRequestDisplaysIdle()
{
	dispatch_once(&displaySleepOnce,^()
	{
		displaySleepEntry=IORegistryEntryFromPath(kIOMainPortDefault,"IOService:/IOResources/IODisplayWrangler");
	});
	
	IORegistryEntrySetCFProperty(displaySleepEntry,(CFStringRef)@"IORequestIdle",@true);
	
	return 0x3ec;
}

// sleep wake notifications

dispatch_once_t displayNotifyOnce;
NSMutableArray<dispatch_queue_t>* displayNotifyQueues;
NSMutableArray<NSNumber*>* displayNotifyTypes;
NSMutableArray<dispatch_block_t>* displayNotifyBlocks;

void displayNotifyCommon(unsigned int type)
{
	for(unsigned int index=0;index<displayNotifyQueues.count;index++)
	{
		if(displayNotifyTypes[index].intValue==type)
		{
			dispatch_queue_t queue;
			if(displayNotifyQueues[index]!=(dispatch_queue_t)NSNull.null)
			{
				queue=displayNotifyQueues[index];
			}
			else
			{
				queue=dispatch_get_main_queue();
			}
			
			dispatch_async(queue,displayNotifyBlocks[index]);
		}
	}

}

void displaySleepCallback()
{
	displayNotifyCommon(3);
}

void displayWakeCallback()
{
	displayNotifyCommon(2);
}

unsigned int SLSDisplayManagerRegisterPowerStateNotification(dispatch_queue_t rdi_queue,unsigned int esi,unsigned int edx_type,dispatch_block_t rcx_block)
{
	dispatch_once(&displayNotifyOnce,^()
	{
		displayNotifyQueues=NSMutableArray.alloc.init;
		displayNotifyTypes=NSMutableArray.alloc.init;
		displayNotifyBlocks=NSMutableArray.alloc.init;
		
		unsigned int connection=SLSMainConnectionID();
		
		SLSRegisterConnectionNotifyProc(connection,displaySleepCallback,kCGSDisplayWillSleep,nil);
		SLSRegisterConnectionNotifyProc(connection,displayWakeCallback,kCGSDisplayDidWake,nil);
	});
	
	// passed NULL by PowerChime
	if(rdi_queue)
	{
		[displayNotifyQueues addObject:rdi_queue];
	}
	else
	{
		[displayNotifyQueues addObject:(dispatch_queue_t)NSNull.null];
	}
	
	[displayNotifyTypes addObject:[NSNumber numberWithInt:edx_type]];
	
	// TODO: confirm this is how blocks work
	dispatch_block_t heapBlock=Block_copy(rcx_block);
	[displayNotifyBlocks addObject:heapBlock];
	Block_release(heapBlock);
	
	return 0;
}

// TODO: implement SLSDisplayManagerUnregisterPowerStateNotification