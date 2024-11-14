const char LOGIC_ATTACH_KEY;

@interface CLgPlayheadLite:NSObject
-(NSViewLite*)playheadView;
@end

Class soft_NSView=NULL;

@interface AmyLogicHack:NSObject

@property(retain) NSViewLite* view;
@property(retain) NSViewLite* markerView;
@property(assign) CALayer* mimic;
@property(assign) double headerHeight;

@end

@implementation AmyLogicHack

-(instancetype)initWithSyncedView:(NSViewLite*)syncedView markerView:(NSViewLite*)markerView
{
	self.view=[[soft_NSView alloc] init];
	_view.release;
	
	_mimic=CALayer.layer;
	_mimic.contentsCenter=CGRectMake(0,0.4,1,0.2);
	_mimic.anchorPoint=CGPointMake(0.5,0);
	
	_view.wantsLayer=true;
	[_view.layer addSublayer:_mimic];
	
	self.markerView=markerView;
	[_markerView addSubview:_view];
	
	NSViewLite* header=nil;
	for(NSViewLite* child in syncedView.subviews)
	{
		if([NSStringFromClass(child.class) isEqual:@"CLgSplitView"])
		{
			for(NSViewLite* child2 in child.subviews)
			{
				if([NSStringFromClass(child2.class) isEqual:@"CLgSyncedSplitView"])
				{
					for(NSViewLite* child3 in child2.subviews)
					{
						if([NSStringFromClass(child3.class) isEqual:@"CLgScrollView"])
						{
							header=child3;
							break;
						}
					}
					break;
				}
			}
			break;
		}
	}
	_headerHeight=header.frame.size.height/2;
	
	objc_setAssociatedObject(markerView,&LOGIC_ATTACH_KEY,self,OBJC_ASSOCIATION_RETAIN);
	
	return self;
}

-(void)refresh
{
	dispatch_async(dispatch_get_main_queue(),^()
	{
		// TODO: possible to refresh faster? it lags behind scrolling...
		
		CGPoint pos=CGPointZero;
		object_getInstanceVariable(_markerView,"currentPlayheadPos",(void*)&pos);
		_mimic.position=pos;
		
		CGImageRef image=NULL;
		object_getInstanceVariable(_markerView,"currentPlayheadReferenceImage",(void*)&image);
		_mimic.contents=(id)image;
		
		_view.frame=CGRectMake(0,0,_markerView.frame.size.width,_markerView.frame.size.height);
		_mimic.bounds=CGRectMake(0,0,CGImageGetWidth(image),_markerView.frame.size.height-_headerHeight);
	});
}

@end

void fake_DIM(NSViewLite* self,SEL sel,NSViewLite* selfAgain)
{
	AmyLogicHack* hack=objc_getAssociatedObject(self,&LOGIC_ATTACH_KEY);
	hack.refresh;
}

NSObject* (*real_IWV)(CLgPlayheadLite*,SEL,NSViewLite*,NSViewLite*);
NSObject* fake_IWV(CLgPlayheadLite* self,SEL sel,NSViewLite* view,NSViewLite* overview)
{
	NSObject* result=real_IWV(self,sel,view,overview);
	
	// TODO: just leaks these
	// not a big issue since it only gets a couple per session, but still dumb...
	
	[AmyLogicHack.alloc initWithSyncedView:view markerView:self.playheadView];
	
	return result;
}

void logicHackSetup()
{
	if([process containsString:@"Logic Pro X"])
	{
		if([NSUserDefaults.standardUserDefaults boolForKey:@"Moraea.LogicPlayheadHack"])
		{
			trace(@"enabling Logic playhead hack");
			
			soft_NSView=NSClassFromString(@"NSView");
			
			swizzleImp(@"CLgPlayheadView",@"drawInMTKView:",true,(IMP)fake_DIM,NULL);
			swizzleImp(@"CLgPlayhead",@"initWithView:forOverview:",true,(IMP)fake_IWV,(IMP*)&real_IWV);
		}
	}
}
