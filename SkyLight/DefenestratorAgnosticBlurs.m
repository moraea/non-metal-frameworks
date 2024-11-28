// modified from Edu's D2C+CABL shim to demonstrate DefenestratorInterface.h

#define NSVisualEffectBlendingModeBehindWindow 0

BOOL blurBetaValue;
dispatch_once_t blurBetaOnce;
BOOL blurBeta()
{
	dispatch_once(&blurBetaOnce,^()
	{
		blurBetaValue=[NSUserDefaults.standardUserDefaults boolForKey:@"Moraea_BlurBeta"];
	});
	
	return blurBetaValue;
}

@interface BlurInfo:NSObject

@property(assign) NSObject<DefenestratorWrapper>* wrapper;
@property(assign) void* backdrop;
@property(assign) BOOL activeBlurs;

@end

@implementation BlurInfo

-(void)updateBackdrop
{
	// TODO: exit early if unchanged activeBlurs and bounds
	
	self.removeBackdrop;
	
	if(!_activeBlurs)
	{
		return;
	}
	
	CGRect bounds=_wrapper.context.layer.bounds;
	
	// TODO: why
	bounds.size.width+=1;
	
	_backdrop=SLSWindowBackdropCreateWithLevelAndTintColor(_wrapper.wid,@"Mimic",@"Sover",0,NULL,bounds);
}

-(void)removeBackdrop
{
	if(_backdrop)
	{
		SLSWindowBackdropRelease(_backdrop);
		_backdrop=NULL;
	}
}

-(void)dealloc
{
	self.removeBackdrop;
}

@end

NSMutableDictionary<NSNumber*,BlurInfo*>* blurInfo;

void (*real__updateMaterialLayer)(NSVisualEffectViewLite* self,SEL selector);
void fake__updateMaterialLayer(NSVisualEffectViewLite* self,SEL selector)
{
	if(self.blendingMode==NSVisualEffectBlendingModeBehindWindow)
	{
		unsigned int windowID=self.window.windowNumber;
		BlurInfo* info=blurInfo[[NSNumber numberWithInt:windowID]];
		info.activeBlurs=self._shouldUseActiveAppearance;
		info.updateBackdrop;
	}
	
	real__updateMaterialLayer(self,selector);
}

void blursSetupNew()
{
	defenestratorRegisterOnce(^()
	{
		if(blurBeta())
		{
			swizzleImp(@"NSVisualEffectView",@"_updateMaterialLayer",true,(IMP)fake__updateMaterialLayer,(IMP*)&real__updateMaterialLayer);
		
			blurInfo=NSMutableDictionary.alloc.init;
			
			defenestratorRegisterCreation(^(NSObject<DefenestratorWrapper>* wrapper)
			{
				BlurInfo* info=BlurInfo.alloc.init;
				info.wrapper=wrapper;
				blurInfo[[NSNumber numberWithInt:wrapper.wid]]=info;
				info.release;
			});
			
			defenestratorRegisterDestruction(^(NSObject<DefenestratorWrapper>* wrapper)
			{
				blurInfo[[NSNumber numberWithInt:wrapper.wid]]=nil;
			});
			
			defenestratorRegisterUpdate(^(NSObject<DefenestratorWrapper>* wrapper)
			{
				blurInfo[[NSNumber numberWithInt:wrapper.wid]].updateBackdrop;
			});
		}
	});
}
