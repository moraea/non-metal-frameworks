// TODO: dumping location for stuff to be cleaned or moved elsewhere

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

// TODO: check necessary

@interface CALayer(Shim)
@end

@implementation CALayer(Shim)

-(void)setUnsafeUnretainedDelegate:(id)rdx
{
	[self setDelegate:rdx];
}

-(id)unsafeUnretainedDelegate
{
	return [self delegate];
}

@end

void miscSetup()
{
	fixCAContextImpl();
}