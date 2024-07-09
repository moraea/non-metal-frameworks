// sidebar glyph colors

// TODO: extremely weird

void (*real_applyCustomForegroundColor)(id self,SEL selector,CGColorRef color,BOOL flag);

void fake_applyCustomForegroundColor(id self,SEL selector,CGColorRef color,BOOL flag)
{
	real_applyCustomForegroundColor(self,selector,color,flag);
	
	unsigned int* thing=*(unsigned int**)(((char*)self)+0x30);
	if(thing)
	{
		if(*thing==0x7663736f)
		{
			*thing=0x6e6f726d;
			
			float* colorList=(float*)(thing+1);
			const double* newColorList=CGColorGetComponents(color);
			for(unsigned int index=0;index<3;index++)
			{
				colorList[index]=newColorList[index];
			}
		}
	}
}

void glyphsSetup()
{
	swizzleImp(@"CUIShapeEffectStack",@"applyCustomForegroundColor:tintEffectColors:",true,(IMP)fake_applyCustomForegroundColor,(IMP*)&real_applyCustomForegroundColor);
}