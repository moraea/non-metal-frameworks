#define photosHiddenTypes @[@"PXTransientCollectionIdentifierMap"]

@interface ThingWithCollection:NSObject
-(NSObject*)collection;
@end

@interface ThingWithIdentifier:NSObject
-(NSObject*)identifier;
@end

NSObject* (*real_initWithChildDataSectionManagers)(NSObject*,SEL,NSArray*);

NSObject* fake_initWithChildDataSectionManagers(NSObject* self,SEL sel,NSArray* children)
{
	NSMutableArray* filtered=NSMutableArray.alloc.init.autorelease;
	
	for(NSObject* child in children)
	{
		BOOL hide=false;
		
		if([child respondsToSelector:@selector(collection)])
		{
			NSObject* collection=((ThingWithCollection*)child).collection;
			if([collection respondsToSelector:@selector(identifier)])
			{
				if([photosHiddenTypes containsObject:((ThingWithIdentifier*)collection).identifier])
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

BOOL fake_curatedLibraryEnabled()
{
	// supposed to check PXGView.supportLevel which checks Metal
	// but we can just lie? what?
	
	return true;
}

long kil()
{
	return 0;
}

void photosSetup()
{
	if(![process isEqualToString:@"/System/Applications/Photos.app/Contents/MacOS/Photos"])
	{
		return;
	}
	
	swizzleImp(@"PXDataSectionManager",@"initWithChildDataSectionManagers:",true,(IMP)fake_initWithChildDataSectionManagers,(IMP*)&real_initWithChildDataSectionManagers);
	
	swizzleImp(@"IPXWorkspaceSettings",@"curatedLibraryEnabled",true,(IMP)fake_curatedLibraryEnabled,NULL);

	// memories crash
	swizzleImp(@"PXGViewTextureConverter",@"applyAdjustment:toTexture:options:",true,(IMP)kil,NULL);
}
