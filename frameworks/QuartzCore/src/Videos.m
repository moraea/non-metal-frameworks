// black videos with Mojave QC

int CAImageQueueInsertImageWithRotation(void* rdi_queue,int esi,void* rdx,int ecx,int r8d,void* r9_function,double xmm0,void* stack)
{
	// TODO: not sure of order of 32-bit parameters
	// and clearly the lack of rotation will pose a problem at some point
	
	return CAImageQueueInsertImage(rdi_queue,esi,rdx,ecx,r9_function,stack,xmm0);
}