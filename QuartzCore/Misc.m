// TODO: stuff to be cleaned or moved elsewhere

// private, can't use a category to add missing symbols
// TODO: generate via Stubber, make public, or SOMETHING better than this...

void doNothing()
{
}

void fixCAContextImpl()
{
	Class CAContextImpl=NSClassFromString(@"CAContextImpl");
	class_addMethod(CAContextImpl,@selector(addFence:),(IMP)doNothing,"v@:@");
	class_addMethod(CAContextImpl,@selector(transferSlot:toContextWithId:),(IMP)doNothing,"v@:@@");
}

// reee

void (*real_setScale)(id,SEL,double);

void fake_setScale(id self,SEL selector,double value)
{
	value=MAX(value,1.0);
	
	real_setScale(self,selector,value);
}

void blurScaleHack()
{
	swizzleImp(@"CABackdropLayer",@"setScale:",true,(IMP)fake_setScale,(IMP*)&real_setScale);
}

void miscSetup()
{
	fixCAContextImpl();
	
#ifdef CAT
	blurScaleHack();
#endif
}