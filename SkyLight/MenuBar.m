BOOL styleIsDarkValue;
dispatch_once_t styleIsDarkOnce;
BOOL styleIsDark()
{
	// NSUserDefaults is unavailable in early boot
	
	dispatch_once(&styleIsDarkOnce,^()
	{
		styleIsDarkValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_DarkMenuBar"];
	});
	
	return styleIsDarkValue;
}

// right side

void SLSTransactionSystemStatusBarRegisterSortedWindow(unsigned long rdi_transaction,unsigned int esi_windowID,unsigned int edx_priority,unsigned long rcx_displayID,unsigned int r8d_flags,unsigned int r9d_insertOrder,float xmm0_preferredPosition,unsigned int stack_appearance)
{
	unsigned int connection=SLSMainConnectionID();
	
	// TODO: null space ID
	SLSSystemStatusBarRegisterSortedWindow(connection,esi_windowID,edx_priority,0,rcx_displayID,r8d_flags,xmm0_preferredPosition);
	SLSAdjustSystemStatusBarWindows(connection);
}

// greyed copies on inactive display

void SLSTransactionSystemStatusBarRegisterReplicantWindow(unsigned long rdi_transaction,unsigned int esi_windowID,unsigned int edx_parent,unsigned long rcx_displayID,unsigned int r8d_flags,unsigned int r9d_appearance)
{
	unsigned int connection=SLSMainConnectionID();
	SLSSystemStatusBarRegisterReplicantWindow(connection,esi_windowID,edx_parent,rcx_displayID,r8d_flags);
	SLSAdjustSystemStatusBarWindows(connection);
}

void SLSTransactionSystemStatusBarUnregisterWindow(unsigned long rdi_transaction,unsigned int esi_windowID)
{
	unsigned int connection=SLSMainConnectionID();
	SLSUnregisterWindowWithSystemStatusBar(connection,esi_windowID);
	SLSOrderWindow(connection,esi_windowID,0,0);
	SLSAdjustSystemStatusBarWindows(connection);
}

// emulate selections (formerly drawn in AppKit)

void SLSTransactionSystemStatusBarSetSelectedContentFrame(unsigned long rdi_transaction,unsigned int esi_windowID,CGRect stack_rect)
{
	CALayer* layer=wrapperForWindow(esi_windowID).context.layer;
	
	if(NSIsEmptyRect(stack_rect))
	{
		layer.backgroundColor=CGColorGetConstantColor(kCGColorClear);
	}
	else
	{
		// TODO: totally guessed
		CGColorRef fillBase=CGColorGetConstantColor(styleIsDark()?kCGColorBlack:kCGColorWhite);
		float fillAlpha=styleIsDark()?0.1:0.25;
		CGColorRef fillColor=CGColorCreateCopyWithAlpha(fillBase,fillAlpha);
		layer.backgroundColor=fillColor;
		CFRelease(fillColor);
		
		// sort of measured from Catherine's screenshot
		layer.cornerRadius=3.5;
	}
}

// auto-generated work in Monterey, but hardcoded elsewhere without "Key" suffix in Big Sur

const NSString* kSLMenuBarImageWindowDarkKey=@"kSLMenuBarImageWindowDark";
const NSString* kSLMenuBarImageWindowLightKey=@"kSLMenuBarImageWindowLight";
const NSString* kSLMenuBarInactiveImageWindowDarkKey=@"kSLMenuBarInactiveImageWindowDark";
const NSString* kSLMenuBarInactiveImageWindowLightKey=@"kSLMenuBarInactiveImageWindowLight";

// intercept from HIToolbox MenuBarInstance::SetServerBounds()

unsigned int SLSSetMenuBars(unsigned int edi_connectionID,NSMutableArray* rsi_array,NSMutableDictionary* rdx_dict)
{
	// emulate the new highlight color
	// TODO: strings may be defined somewhere
	// TODO: obviously better to do via CALayer if possible
	
	rdx_dict[kCGMenuBarTitleMaterialKey]=styleIsDark()?@"UltrathinDark":@"UltrathinLight";
	
	// prevent black menubar in Monterey
	
	rdx_dict[kCGMenuBarActiveMaterialKey]=@"Light";
	
	// fix text window IDs
	
	for(unsigned int barIndex=0;barIndex<rsi_array.count;barIndex++)
	{
		NSNumber* activeID;
		NSNumber* inactiveID;
		
		if(styleIsDark())
		{
			activeID=rsi_array[barIndex][kSLMenuBarImageWindowDarkKey];
			inactiveID=rsi_array[barIndex][kSLMenuBarInactiveImageWindowDarkKey];
		}
		else
		{
			activeID=rsi_array[barIndex][kSLMenuBarImageWindowLightKey];
			inactiveID=rsi_array[barIndex][kSLMenuBarInactiveImageWindowLightKey];
		}
		
		rsi_array[barIndex][kCGMenuBarImageWindowKey]=activeID;
		rsi_array[barIndex][kCGMenuBarInactiveImageWindowKey]=inactiveID;
	}
	
	return SLSSetMenuBar$(edi_connectionID,rsi_array,rdx_dict);
}

// replicants and appearance

NSDictionary* SLSCopySystemStatusBarMetrics()
{
	NSMutableDictionary* result=NSMutableDictionary.alloc.init;
	
	NSString* activeID=SLSCopyActiveMenuBarDisplayIdentifier(SLSMainConnectionID());
	result[@"activeDisplayIdentifier"]=activeID;
	activeID.release;
	
	int count;
	SLSGetDisplayList(0,NULL,&count);
	int* ids=malloc(sizeof(int)*count);
	SLSGetDisplayList(count,ids,&count);
	
	NSMutableArray<NSDictionary*>* displays=NSMutableArray.alloc.init;
	
	for(int index=0;index<count;index++)
	{
		NSMutableDictionary* display=NSMutableDictionary.alloc.init;
		
		NSNumber* appearance=styleIsDark()?@0:@1;
		display[@"appearances"]=@[appearance];
		display[@"currentAppearance"]=appearance;
		
		CFUUIDRef uuid;
		SLSCopyDisplayUUID(ids[index],&uuid);
		NSString* uuidString=(NSString*)CFUUIDCreateString(NULL,uuid);
		CFRelease(uuid);
		display[@"identifier"]=uuidString;
		uuidString.release;
		
		[displays addObject:display];
		display.release;
	}
	
	free(ids);
	
	result[@"displays"]=displays;
	displays.release;
	
	// don't autorelease because *Copy*
	return result;
}

// move replicants between screens

void statusBarSpaceCallback()
{
	// TODO: not how it's officially done
	
	NSDictionary* dict=SLSCopySystemStatusBarMetrics();
	[NSNotificationCenter.defaultCenter postNotificationName:kSLSCoordinatedSystemStatusBarMetricsChangedNotificationName object:nil userInfo:dict];
	dict.release;
}

// update app toolbars

void menuBarRevealCommon(NSNumber* amount)
{
	// based on -[_NSFullScreenSpace wallSpaceID]
	
	unsigned int connection=SLSMainConnectionID();
	unsigned long spaceID=SLSGetActiveSpace(connection);
	NSDictionary* spaceDict=SLSSpaceCopyValues(SLSMainConnectionID(),spaceID);
	NSNumber* wallID=spaceDict[kCGSWorkspaceWallSpaceKey][kCGSWorkspaceSpaceIDKey];
	
	NSMutableDictionary* output=NSMutableDictionary.alloc.init;
	output[@"space"]=wallID;
	output[@"reveal"]=amount;
	
	spaceDict.release;
	
	[NSNotificationCenter.defaultCenter postNotificationName:kSLSCoordinatedSpaceMenuBarRevealChangedNotificationName object:nil userInfo:output];
	
	output.release;
}

void menuBarRevealCallback()
{
	menuBarRevealCommon(@1.0);
}

void menuBarHideCallback()
{
	menuBarRevealCommon(@0.0);
}

dispatch_once_t notifyOnce;
NSNotificationCenter* SLSCoordinatedLocalNotificationCenter()
{
	dispatch_once(&notifyOnce,^()
	{
		int connection=SLSMainConnectionID();
		
		SLSRegisterConnectionNotifyProc(connection,statusBarSpaceCallback,kCGSPackagesStatusBarSpaceChanged,nil);
		
		// not in WSLogStringForNotifyType
		SLSRegisterConnectionNotifyProc(connection,menuBarRevealCallback,0x524,nil);
		SLSRegisterConnectionNotifyProc(connection,menuBarHideCallback,0x525,nil);
	});
	
	return NSNotificationCenter.defaultCenter;
}

// AppKit callbacks crash

dispatch_block_t SLSCopyCoordinatedDistributedNotificationContinuationBlock()
{
	dispatch_block_t result=SLSCopyCoordinatedDistributedNotificationContinuationBloc$();
	if(result)
	{
		return result;
	}
	
	// TODO: ownership?
	return ^()
	{
	};
}

// custom background colors

void menuBarOverrideSetup()
{
	if(!isWindowServer)
	{
		return;
	}
	
	NSString* pref=[NSUserDefaults.standardUserDefaults stringForKey:@"Moraea_MenuBarOverride"];
	if(!pref)
	{
		return;
	}
	
	NSArray<NSString*>* bits=[pref componentsSeparatedByString:@","];
	if(bits.count!=4)
	{
		return;
	}
	
	float floats[4];
	for(int i=0;i<4;i++)
	{
		floats[i]=bits[i].floatValue;
		if(floats[i]<0||floats[i]>1)
		{
			return;
		}
	}
	
	trace(@"menu bar override sanity checks passed (%f, %f, %f, %f)",floats[0],floats[1],floats[2],floats[3]);
	
	char* base=(char*)SLSMainConnectionID-0x1d8272;
	char* target=base+0x26ef60;
	
	trace(@"menu bar override found SkyLight base %p target %p",base,target);
	
	if(mprotect(target-(long)target%getpagesize(),getpagesize()*2,PROT_READ|PROT_WRITE))
	{
		trace(@"menu bar override mprotect failed");
		return;
	}
	
	memcpy(target,floats,16);
}

// refresh layout on status bar length changes

void (*real_setLength)(NSObject* rdi_self,SEL rsi_sel,double xmm0_length);
void fake_setLength(NSObject* rdi_self,SEL rsi_sel,double xmm0_length)
{
	real_setLength(rdi_self,rsi_sel,xmm0_length);
	
	SLSAdjustSystemStatusBarWindows(SLSMainConnectionID());
}

void menuBarSetup()
{
	menuBarOverrideSetup();
	
	swizzleImp(@"NSStatusItem",@"setLength:",true,(IMP)fake_setLength,(IMP*)&real_setLength);
}