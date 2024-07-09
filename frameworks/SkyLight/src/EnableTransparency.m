int _AXInterfaceGetReduceTransparencyEnabled();
int _AXInterfaceGetIncreaseContrastEnabled();
int fake__AXInterfaceGetReducedTransparencyEnabled(){	
    if([NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_EnableTransparency"]){
        return 0;
    } else {
        return _AXInterfaceGetReduceTransparencyEnabled();
    }
}

int fake__AXInterfaceGetIncreaseContrastEnabled(){
    if([NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_EnableTransparency"]){
        return 0;
    } else {
        return _AXInterfaceGetIncreaseContrastEnabled();
    }
}

DYLD_INTERPOSE(fake__AXInterfaceGetReducedTransparencyEnabled,_AXInterfaceGetReduceTransparencyEnabled)
DYLD_INTERPOSE(fake__AXInterfaceGetIncreaseContrastEnabled,_AXInterfaceGetIncreaseContrastEnabled)
