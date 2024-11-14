// reversed private interfaces

int CAImageQueueInsertImage(void* rdi_queue,int esi,void* rdx_surface,int ecx,void* r8_function,void* r9,double xmm0);

BOOL _CFMZEnabled();

// TODO: a bit stupid; we can't link QC bc we'd get duplicate errors
// i don't remember if stubber 3 fixes this so im just doing this for now

@interface CAContext(Dumb)

+(NSArray*)allContexts;

@end

@interface CAFilter:NSObject

-(NSString*)name;

@end

@interface CALayer(Dumb)

+(CALayer*)layer;
-(void)setFrame:(CGRect)rect;
-(void)setBackgroundColor:(CGColorRef)color;
-(void)addSublayer:(CALayer*)child;
-(NSArray<CALayer*>*)sublayers;

@end
