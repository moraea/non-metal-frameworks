// enable Night Shift (sentient-patcher only)

NSString* ASI_CopyComputerModelName(int edi_includeNumbers);

NSString* fake_CCMN(int edi_includeNumbers) {
    if ([@[
            @"/usr/libexec/corebrightnessd", @"/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter",
            @"/System/Library/PreferencePanes/Displays.prefPane/Contents/XPCServices/com.apple.preference.displays.Displays.remoteservice.xpc/Contents/MacOS/com.apple.preference.displays.Displays.remoteservice"
        ] containsObject:process]) {
        return @"MacBook420,69".retain;
    }

    return ASI_CopyComputerModelName(edi_includeNumbers);
}

DYLD_INTERPOSE(fake_CCMN, ASI_CopyComputerModelName)