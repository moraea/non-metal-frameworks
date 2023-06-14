// TODO: the White Stuff Problem
// like the HD3000 Problem, this is "fixable" by changing colorspace to sRGB/Unknown Display

// monochrome widgets

void (*widgetReal_setFilters)(CALayer*,SEL,NSArray*);
void widgetFake_setFilters(CALayer* self,SEL sel,NSArray* filters)
{
	NSMutableArray* filters2=NSMutableArray.alloc.init;
	for(id filter in filters)
	{
		// TODO: this makes it visible but VERY ugly
		// we will need to either fix or reimplement this filter
		
		if([filter respondsToSelector:@selector(name)]&&[[filter name] isEqualToString:@"vibrantColorMatrix"])
		{
			continue;
		}
		else
		{
			[filters2 addObject:filter];
		}
	}
	
	widgetReal_setFilters(self,sel,filters2);
	
	filters2.release;
}

void sonomaSetup()
{
	if([process containsString:@"NotificationCenter.app"])
	{
		swizzleImp(@"CALayer",@"setFilters:",true,widgetFake_setFilters,&widgetReal_setFilters);
	}
}