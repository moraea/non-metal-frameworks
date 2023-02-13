// TODO: stuff to be cleaned or moved elsewhere

// private, can't use a category to add missing selectors
// TODO: generate via Stubber, make public, or SOMETHING better than this...

#if defined(CAT) || defined(MOJ)

void doNothing()
{
}

void fixCAContextImpl()
{
	Class CAContextImpl=NSClassFromString(@"CAContextImpl");
	class_addMethod(CAContextImpl,@selector(addFence:),(IMP)doNothing,"v@:@");
	class_addMethod(CAContextImpl,@selector(transferSlot:toContextWithId:),(IMP)doNothing,"v@:@@");
}

@interface CAContext(Shim)
@end

@implementation CAContext(Shim)

+(CAContext*)contextWithId:(int)target
{
	CAContext* found=nil;
	for(CAContext* context in [self allContexts])
	{
		if([context contextId]==target)
		{
			found=context;
			break;
		}
	}
	
	// trace(@"contextWithId %@ %x -> %@",self,target,found);
	
	return found;
}

@end

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