// Dock collisions

// new approach (2023-5-29): store orientation in "reason" rather than using HIServices
// workaround CoreDock function not working as root

void SLSGetDockRectWithOrientation(unsigned int edi_connectionID,CGRect* rsi_rectOut,char* rdx_reasonOut,unsigned long* rcx_orientationOut)
{
	int merged=0;
	
	SLSGetDockRectWithReason(edi_connectionID,rsi_rectOut,(char*)&merged);
	
	*rdx_reasonOut=merged&0xffff;
	*rcx_orientationOut=merged>>16;
	
	// SLSGetDockRectWithReason(edi_connectionID,rsi_rectOut,rdx_reasonOut);
	
	// unsigned long pinningIgnored;
	// CoreDockGetOrientationAndPinning(rcx_orientationOut,&pinningIgnored);
}

void SLSSetDockRectWithOrientation(unsigned int edi_connectionID,unsigned int esi,unsigned int edx,CGRect stack_rect)
{
	int merged=esi|(edx<<16);
	
	SLSSetDockRectWithReason(edi_connectionID,merged,stack_rect);
	
	// SLSSetDockRectWithReason(edi_connectionID,esi,stack_rect);
}