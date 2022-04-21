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

void miscSetup()
{
	fixCAContextImpl();
}