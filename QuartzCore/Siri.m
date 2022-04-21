// SiriNCService not appearing

@interface CAFenceHandle(Shim)<NSSecureCoding>
@end

@implementation CAFenceHandle(Shim)

+(instancetype)newFenceFromDefaultServer
{
	trace(@"CAFenceHandle newFenceFromDefaultServer %@",NSThread.callStackSymbols);
	return CAFenceHandle.alloc.init;
}

+(BOOL)supportsSecureCoding
{
	trace(@"CAFenceHandle supportsSecureCoding %@",NSThread.callStackSymbols);
	return true;
}

-(instancetype)initWithCoder:(NSCoder*)coder
{
	self=self.init;
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
}

@end