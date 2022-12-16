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

// Edu again! - this is relevant for adjusting split screen divider?

// AppKit 10.13.6 -[_NSFullScreenContentController performTileResizeToFit:acceptIncorrectSize:]
// rdi from tileSpaceID
// esi
// xmm0
// xmm1
// TODO: return value

void SLSTileSpaceMoveSpacersForSize(long rdi,int esi,double xmm0,double xmm1);

// AppKit 13.1 DP1 __44-[NSCGSSpace moveSpacersForSize:fenceRight:]_block_invoke
// rdi
// esi
// xmm0
// xmm1
// TODO: doesn't even seem to be called

void SLSTileSpaceMoveSpacersForSizeFenced(long rdi,int esi,double xmm0,double xmm1)
{
	SLSTileSpaceMoveSpacersForSize(rdi,esi,xmm0,xmm1);
}

// AppKit 10.13.6 -[_NSFullScreenTileDividerWindow _liveResizeToDividerLocation:]
// edi contextID
// rsi parentSpaceID
// rdx tileSpaceID
// rcx verticalIndex
// r8 horizontalIndex
// r9d 2 or 0 depending on horizontalIndex
// xmm0 divider location
// xmm1 0 always
// TODO: return

void SLSSpaceClientDrivenMoveSpacersToPoint(int edi_cid,long rsi_parentSpaceID,long rdx_tileSpaceID,long rcx_verticalIndex,long r8_horizontalIndex,int r9d_flags,double xmm0_location,double xmm1);

// AppKit 13.1 DP1 4ff804097a6e
// rdx verticalIndex
// rcx horizontalIndex
// r8 0 or 2 i think
// r9d fencePort
// xmm0 same passed to _liveResizeToDividerLocation:
// xmm1 0
// clientDrivenMoveSpacersToPoint:verticalIndex:horizontalIndex:options:fenceRight:

// -[NSCGSSpace clientDrivenMoveSpacersToPoint:verticalIndex:horizontalIndex:options:fenceRight:]
// block+0x20 self
// block+0x28 rdx - verticalIndex
// 0x30 rcx - horizontalIndex
// 0x38 xmm0 - location
// 0x40 xmm1 - 0
// 0x48 r8 - flags
// 0x50 r9d - fencePort

// __94-[NSCGSSpace clientDrivenMoveSpacersToPoint:verticalIndex:horizontalIndex:options:fenceRight:]_block_invoke
// edi cid
// rsi *(block+0x20) + 0x8 - spaceID
// rdx +0x28 - verticalIndex
// rcx +0x30 - horizontalIndex
// r8 +0x48 - flags
// r9d +0x50 - fencePort
// xmm0 +0x38 - location
// xmm1 +0x40 - 0
// TODO: return

void SLSSpaceClientDrivenMoveSpacersToPointFenced(int edi_cid,long rsi_spaceID,long rdx_verticalIndex,long rcx_horizontalIndex,long r8_flags,int r9d_fencePort,double xmm0_location,double xmm1)
{
	// TODO: is the 0 (tileSpaceID) an issue?
	// the parentSpaceID is definitely correct as it doesn't work otherwise
	
	SLSSpaceClientDrivenMoveSpacersToPoint(edi_cid,rsi_spaceID,0,rdx_verticalIndex,rcx_horizontalIndex,r8_flags,xmm0_location,xmm1);
}