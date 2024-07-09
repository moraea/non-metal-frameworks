#import "Utils.h"

#if FRAMEWORK_DOWNGRADE == 101507
@import IOSurface;

// TODO: downgrading IOSurface to 10.14.6 (TS2 patchset) fixes the underlying issue for me
// but Edu can't replicate this on his identical Zoe... should reverse IOSurface.kext

size_t IOSurfaceGetPropertyMaximu$(CFStringRef);

size_t IOSurfaceGetPropertyMaximum(CFStringRef property) {
	size_t real = IOSurfaceGetPropertyMaximu$(property);
	if (real == INT_MAX) {
		// TODO: actually fetch the value somehow?
		// returned by working IOSurface on Zoe, but could vary on different GPUs
		
		return 0x2000;
	}
	return real;
}

#endif