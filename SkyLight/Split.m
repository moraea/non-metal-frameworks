// credit EduCovas - SLSWindowGetBestSpace is required for "Tile Window to [Left/Right] of Screen"
// ref -[NSCGSWindow bestUserSpaceContainingWindow]
// oddly, just returning 1 seems to work, even on arbitrary spaces
// TODO: should probably still implement properly

#if MAJOR>=12

long SLSWindowGetBestSpace(int edi_wid,int esi)
{
	return 1;
}

#endif

// Edu - this is relevant for adjusting split screen divider?
// TODO: return value
// TODO: doesn't even seem to be called

void SLSTileSpaceMoveSpacersForSizeFenced(long rdi,int esi,double xmm0,double xmm1)
{
	SLSTileSpaceMoveSpacersForSize(rdi,esi,xmm0,xmm1);
}

// TODO: return

void SLSSpaceClientDrivenMoveSpacersToPointFenced(int edi_cid,long rsi_spaceID,long rdx_verticalIndex,long rcx_horizontalIndex,long r8_flags,int r9d_fencePort,double xmm0_location,double xmm1)
{
	// TODO: is the 0 (tileSpaceID) an issue?
	// the parentSpaceID is definitely correct as it doesn't work otherwise
	
	SLSSpaceClientDrivenMoveSpacersToPoint(edi_cid,rsi_spaceID,0,rdx_verticalIndex,rcx_horizontalIndex,r8_flags,xmm0_location,xmm1);
}