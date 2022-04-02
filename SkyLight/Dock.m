// Dock collisions

void SLSGetDockRectWithOrientation(unsigned int edi_connectionID,CGRect* rsi_rectOut,char* rdx_reasonOut,unsigned long* rcx_orientationOut)
{
	SLSGetDockRectWithReason(edi_connectionID,rsi_rectOut,rdx_reasonOut);
	
	unsigned long pinningIgnored;
	CoreDockGetOrientationAndPinning(rcx_orientationOut,&pinningIgnored);
}

void SLSSetDockRectWithOrientation(unsigned int edi_connectionID,unsigned int esi,unsigned int edx,CGRect stack_rect)
{
	SLSSetDockRectWithReason(edi_connectionID,esi,stack_rect);
}