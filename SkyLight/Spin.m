#define SPIN_COUNT 29
#define SPIN_DELAY 1.0/60

char* (*soft_CGXMainDisplayDevice)();
int (*soft_CGXGetCurrentCursorLocation)(double rdi_positionOut[2]);
void (*soft_WSAddNotificationCallback)(void* edi_callback,int esi_type,void* rdx_context);

BOOL spinDisabled;
dispatch_once_t spinInitOnce;
dispatch_queue_t spinQueue;
BOOL spinning=false;
long frame;

// TODO: just as fucked as it was 2 years ago
// TODO: work on non-main displays

int getFramebufferHandle()
{
	char* device=soft_CGXMainDisplayDevice();
	int connect=*(int*)((*(char**)(device+0x160))+0x6c);
	return connect;
}

void updateCursor()
{
	int handle=getFramebufferHandle();
	
	double mouse[2];
	soft_CGXGetCurrentCursorLocation(mouse);
	
	long inputs[3]={};
	inputs[0]=(short)mouse[0];
	inputs[1]=(short)mouse[1];
	if(spinning)
	{
		inputs[2]=frame%SPIN_COUNT+1;
	}
	
	IOConnectCallMethod(handle,13,(const uint64_t*)inputs,3,NULL,0,NULL,NULL,NULL,NULL);
}

void spinStart()
{
	spinning=true;
	
	dispatch_async(spinQueue,^()
	{
		while(spinning)
		{
			[NSThread sleepForTimeInterval:SPIN_DELAY];
			updateCursor();
			frame++;
		}
	});
}

void spinEnd()
{
	spinning=false;
}

void spinInit()
{
	// sudo defaults write /Library/Preferences/.GlobalPreferences.plist Moraea.EnableSpinHack -bool true
	
	spinDisabled=![NSUserDefaults.standardUserDefaults boolForKey:@"Moraea.EnableSpinHack"];
	if(spinDisabled)
	{
		return;
	}
	
	char* base=(char*)SLSMainConnectionID-0x1d8272;
	soft_CGXGetCurrentCursorLocation=(void*)(base+0x234015);
	soft_WSAddNotificationCallback=(void*)(base+0x126372);
	soft_CGXMainDisplayDevice=dlsym(RTLD_DEFAULT,"CGXMainDisplayDevice");
	
	soft_WSAddNotificationCallback(spinStart,0x5e5,NULL);
	soft_WSAddNotificationCallback(spinEnd,0x5e6,NULL);
	
	spinning=false;
	frame=0;
	
	dispatch_queue_attr_t queueSettings=dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE,-1);
	spinQueue=dispatch_queue_create(NULL,queueSettings);
}

int IOHIDSetFixedMouseLocation(int edi_driver,int esi_x,int edx_y);
int fake_IOHIDSetFixedMouseLocation(int edi_driver,int esi_x,int edx_y)
{
	int result=IOHIDSetFixedMouseLocation(edi_driver,esi_x,edx_y);
	
	dispatch_once(&spinInitOnce,^()
	{
		spinInit();
	});
	
	if(spinning)
	{
		updateCursor();
	}
	
	return result;
}

DYLD_INTERPOSE(fake_IOHIDSetFixedMouseLocation,IOHIDSetFixedMouseLocation)