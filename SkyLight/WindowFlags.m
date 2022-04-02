// SLSNewWindowWithOpaqueShape abort()

unsigned int SLSNewWindowWithOpaqueShape(unsigned int edi_connectionID,unsigned int esi,char* rdx_region,char* rcx_region,unsigned int r8d,char* r9,unsigned long stack1_windowID,unsigned long stack2,double xmm0,double xmm1)
{
	esi=MIN(esi,4);
	
	return SLSNewWindowWithOpaqueShap$(edi_connectionID,esi,rdx_region,rcx_region,r8d,r9,stack1_windowID,stack2,xmm0,xmm1);
}