#import "Utils.h"
@import Darwin.POSIX.dlfcn;
@import UniformTypeIdentifiers;

__attribute__((constructor))
void load()
{
	traceLog=true;
}

dispatch_once_t slsOnce;
NSDictionary* (*dynamic_SLSCopyDisplayInfoDictionary)(int)=NULL;

NSDictionary* CoreDisplay_DisplayCreateInfoDictionary(int edi)
{
	// trace(@"thic: CoreDisplay_DisplayCreateInfoDictionary %d %@",edi,NSThread.callStackSymbols);
	
	dispatch_once(&slsOnce,^()
	{
		dynamic_SLSCopyDisplayInfoDictionary=dlsym(RTLD_DEFAULT,"SLSCopyDisplayInfoDictionary");
		// trace(@"thic: dlsym %p %s",dynamic_SLSCopyDisplayInfoDictionary,dlerror());
	});
	
	if(!dynamic_SLSCopyDisplayInfoDictionary)
	{
		return nil;
	}
	
	NSDictionary* result=dynamic_SLSCopyDisplayInfoDictionary(edi);
	
	NSMutableDictionary* mutable=result.mutableCopy;
	result.release;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
	NSString* type=[[UTType _typeOfCurrentDevice] identifier];
#pragma clang diagnostic pop
	NSString* path=[NSString stringWithFormat:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/%@.icns",type];
	
	// trace(@"thic: adding %@",path);
	mutable[@"display-icon"]=path;
	mutable[@"display-resolution-preview-icon"]=path;
	
	// TODO: these are for placing the screen image over the icon
	/*mutable[@"resolution-preview-width"]=
	mutable[@"resolution-preview-height"]=
	mutable[@"resolution-preview-x"]=
	mutable[@"resolution-preview-x"]=*/
	
	// trace(@"thic: result %@",mutable);
	
	return mutable;
}