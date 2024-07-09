// libUADaemon passes 36 bytes based on 4x4 matrices in MediaAccessibility
// no idea how to handle that, but at least i can check for greyscale

char greyCheck[12]={0x9a,0x99,0x99,0x3e,0x3d,0x0a,0x17,0x3f,0xae,0x47,0xe1,0x3d};

unsigned int SLSSetAccessibilityAdjustments(NSDictionary* rdi_dict)
{
	NSData* matrix=rdi_dict[kSLSAccessibilityAdjustmentMatrix];
	SLDisplayForceToGray(!memcmp(matrix.bytes,greyCheck,12));
	
	return 0;
}