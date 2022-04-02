// AppKit _iterateDevicesOfKeyWithBlock crash on NSString.stringValue

NSDictionary* SLSCopyDevicesDictionary()
{
	NSDictionary* dictIn=SLSCopyDevicesDictionar$();
	NSMutableDictionary* dictOut=dictIn.mutableCopy;
	dictIn.release;
	
	// TODO: confirm all (and only) these are needed
	NSArray<const NSString*>* keysToFix=@[kSLSBuiltInDevicesKey,kSLSMouseDevicesKey,kSLSGestureScrollDevicesKey];
	
	for(const NSString* key in keysToFix)
	{
		NSArray<NSString*>* valuesOld=dictOut[key];
		NSMutableArray<NSNumber*>* valuesNew=NSMutableArray.alloc.init;
		for(NSString* value in valuesOld)
		{
			// TODO: size?
			[valuesNew addObject:[NSNumber numberWithInteger:value.integerValue]];
		}
		dictOut[key]=valuesNew;
		valuesNew.release;
	}
	
	// don't autorelease because *Copy*
	return dictOut;
}