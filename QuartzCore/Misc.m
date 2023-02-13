// TODO: stuff to be cleaned or moved elsewhere

// private, can't use a category to add missing selectors
// TODO: generate via Stubber, make public, or SOMETHING better than this...

#if defined(CAT) || defined(MOJ)

void doNothing()
{
}

NSObject* fake_contextWithId(NSObject* self,SEL sel,int target)
{
	NSObject* found=nil;
	for(NSObject* context in [self allContexts])
	{
		if([context contextId]==target)
		{
			found=context;
			break;
		}
	}
	return found;
}

void fixCAContextImpl()
{
	Class CAContextImpl=NSClassFromString(@"CAContextImpl");
	class_addMethod(CAContextImpl,@selector(addFence:),(IMP)doNothing,"v@:@");
	class_addMethod(CAContextImpl,@selector(transferSlot:toContextWithId:),(IMP)doNothing,"v@:@@");
	class_addMethod(CAContextImpl,@selector(contextWithId:),(IMP)fake_contextWithId,"v@:i");
}
#endif

// reee

void (*real_setScale)(id,SEL,double);

void fake_setScale(id self,SEL selector,double value)
{
	value=MAX(value,1.0);
	
	real_setScale(self,selector,value);
}

#ifdef BS
void (*real_setFilters)(id,SEL,NSArray*);

void fake_setFilters(id self,SEL selector,NSArray* filters)
{
	NSMutableArray* newFilters=NSMutableArray.alloc.init;
	
	for(NSObject* filter in filters)
	{
		NSString* name=[filter name];
		if([name isEqualToString:@"sdrNormalize"]||[name isEqualToString:@"colorSaturate"])
		{
			continue;
		}
		[newFilters addObject:filter];
	}
	
	real_setFilters(self,selector,newFilters);
	
	newFilters.release;
}

void blurFilterHack()
{
	swizzleImp(@"CABackdropLayer",@"setFilters:",true,(IMP)fake_setFilters,(IMP*)&real_setFilters);
}
#endif

void blurScaleHack()
{
	swizzleImp(@"CABackdropLayer",@"setScale:",true,(IMP)fake_setScale,(IMP*)&real_setScale);
}

void miscSetup()
{
	blurScaleHack();
	
#if defined(CAT) || defined(MOJ)
	fixCAContextImpl();
#endif
#ifdef BS
	blurFilterHack();
#endif
}