// clang -fmodules -F /System/Library/PrivateFrameworks -framework SkyLight flag_flags_2.m -o /tmp/ff && /tmp/ff

@import Foundation;
#define trace NSLog

void SLSSetDebugOptions(int);

int main()
{
	SLSSetDebugOptions(0xC0000010);
	
	[NSThread sleepForTimeInterval:5];
	
	trace(@"%@",[NSString stringWithContentsOfFile:@"/tmp/WindowServer.sinfo.out"]);
}