// clang -fmodules -F /System/Library/PrivateFrameworks -framework SkyLight flag_flags_2.m -o /tmp/ff
// scp /tmp/ff amy@ivy.local:/Users/amy/Desktop

@import Foundation;
#define trace NSLog

void SLSSetDebugOptions(int);

int main()
{
	// > CA will flatten using (forced) IOSurface backings.
	// SLSSetDebugOptions(0x800000e2);
	
	// > CA will flatten using texture rectangles, if GL is active.
	// SLSSetDebugOptions(0x800000e1);
	
	// > CA will flatten using compositor-native backings.
	// SLSSetDebugOptions(0x800000e0);
	
	// sWSCAFlattenAlways = 1; blurs are continuously "flashed"
	SLSSetDebugOptions(0x80000083);
	
	// sWSCAFlattenAlways = 0, sWSCAFlattenNever = 1; blurs can't flash but fading doesn't work
	// SLSSetDebugOptions(0x800000a0);
	
	// sWSCAFlattenNever = 0
	// SLSSetDebugOptions(0x800000a1);
	
	// write surface info to file (snapshot and overwrites; have to call again to refresh)
	
	SLSSetDebugOptions(0xc0000010);
	
	[NSThread sleepForTimeInterval:1];
	
	trace(@"%@",[NSString stringWithContentsOfFile:@"/tmp/WindowServer.sinfo.out" encoding:NSUTF8StringEncoding error:nil]);
}