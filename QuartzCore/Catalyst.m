// possible hack for lifecycle issues, needs further testing

BOOL (*real_ACHFP)(CATransaction*,SEL,void*,int);
BOOL fake_ACHFP(CATransaction* self,SEL sel,void* rdx_block,int ecx_phase)
{
	if(ecx_phase==5)
	{
		ecx_phase=4;
	}
	
	real_ACHFP(self,sel,rdx_block,ecx_phase);
	
	return true;
}

// TODO: upside-down

// TODO: mysterious (use after free?) crashes

void catalystSetup()
{
	swizzleImp(@"CATransaction",@"addCommitHandler:forPhase:",false,(IMP)fake_ACHFP,(IMP*)&real_ACHFP);
}