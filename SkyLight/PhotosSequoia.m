#define photosHiddenTypes @[@"PXPhotosVirtualCollection",@"PXTransientCollectionIdentifierMap"]

NSObject* (*real_initWithChildDataSectionManagers)(NSObject*,SEL,NSArray*);

NSObject* fake_initWithChildDataSectionManagers(NSObject* self,SEL sel,NSArray* children)
{
	NSMutableArray* filtered=NSMutableArray.alloc.init.autorelease;
	
	for(NSObject* child in children)
	{
		BOOL hide=false;
		
		if([child respondsToSelector:@selector(collection)])
		{
			NSObject* collection=[child collection];
			if([collection respondsToSelector:@selector(identifier)])
			{
				if([photosHiddenTypes containsObject:[collection identifier]])
				{
					hide=true;
				}
			}
		}
		
		if(!hide)
		{
			[filtered addObject:child];
		}
	}
	
	return real_initWithChildDataSectionManagers(self,sel,filtered);
}

void photosSetup()
{
	if(![process isEqualToString:@"/System/Applications/Photos.app/Contents/MacOS/Photos"])
	{
		return;
	}
	
	swizzleImp(@"PXDataSectionManager",@"initWithChildDataSectionManagers:",true,(IMP)fake_initWithChildDataSectionManagers,(IMP*)&real_initWithChildDataSectionManagers);
}
