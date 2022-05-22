NSString *_AXInterfaceGetReduceTransparencyEnabled();
int fake__AXInterfaceGetReducedTransparencyEnabled(){
	NSLog(@"dyld_interposed");
	
    if([NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_EnableTransparency"]){
        return 0;
    } else {
        return _AXInterfaceGetReduceTransparencyEnabled();
    }
}
DYLD_INTERPOSE(fake__AXInterfaceGetReducedTransparencyEnabled,_AXInterfaceGetReduceTransparencyEnabled)
