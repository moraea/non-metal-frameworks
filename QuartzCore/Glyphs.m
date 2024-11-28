// WindowServer crash due to sidebar glyphs
// only applies to Cat QC

void (*real_SCF)(CALayer*,SEL,NSObject*);
void fake_SCF(CALayer* self,SEL sel,NSObject* filter)
{
	if(filter&&[filter respondsToSelector:@selector(name)]&&[((CAFilter*)filter).name isEqualToString:@"vibrantColorMatrixSourceOver"])
	{
		filter=nil;
	}
	
	real_SCF(self,sel,filter);
}

void glyphsSetup()
{
	swizzleImp(@"CALayer",@"setCompositingFilter:",true,(IMP)fake_SCF,(IMP*)&real_SCF);
}
