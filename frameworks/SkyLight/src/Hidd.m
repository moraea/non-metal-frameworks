// pretty much just lifted from hidd

// TODO: check signatures
void* IOHIDEventSystemCreate(CFAllocatorRef);
long IOHIDEventSystemOpen(void*,void*,void*,void*,long);
long IOHIDEventSystemSetProperty(void*,CFStringRef,void*);

dispatch_queue_t hiddQueue;

void* eventSystem;

NSDictionary* getHidParams()
{
	io_service_t service=IORegistryEntryFromPath(kIOMainPortDefault,"IOService:/IOResources/IOHIDSystem");
	NSDictionary* result=IORegistryEntryCreateCFProperty(service,CFSTR("HIDParameters"),kCFAllocatorDefault,0);
	IOObjectRelease(service);
	
	// trace(@"getHidParams IORegistryEntryCreateCFProperty %@",result);
	
	return result.autorelease;
}

void setHidParams(NSDictionary* params)
{
	// trace(@"setHidParams IOHIDEventSystemSetProperty %d %@",IOHIDEventSystemSetProperty(eventSystem,CFSTR("HIDParameters"),params),params);
	IOHIDEventSystemSetProperty(eventSystem,CFSTR("HIDParameters"),params);
}

void hiddSetup()
{
	if(isWindowServer)
	{
		dispatch_queue_attr_t queueSettings=dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE,-1);
		hiddQueue=dispatch_queue_create(NULL,queueSettings);
		
		dispatch_async(hiddQueue,^()
		{
			eventSystem=IOHIDEventSystemCreate(kCFAllocatorDefault);
			
			if(!eventSystem)
			{
				trace(@"IOHIDEventSystemCreate failed, will be unresponsive without HiddHack!");
				return;
			}
			
			// trace(@"IOHIDEventSystemOpen %ld",IOHIDEventSystemOpen(eventSystem,NULL,NULL,NULL,0));
			IOHIDEventSystemOpen(eventSystem,NULL,NULL,NULL,0);
			
			setHidParams(getHidParams());
			
			// eventSystem not freed
		});
	}
}