#import "Notifications.h"

// Renamer

int SLSNewWindowWithOpaqueShap$(int edi_connectionID,int esi,char* rdx_region,char* rcx_region,int r8d,char* r9,unsigned long stack1_windowID,unsigned long stack2,double xmm0,double xmm1);

int SLSSetMenuBar$(int edi_connectionID,NSMutableArray* rsi_array,NSMutableDictionary* rdx_dict);

NSDictionary* SLSCopyDevicesDictionar$();

dispatch_block_t SLSCopyCoordinatedDistributedNotificationContinuationBloc$();

int SLSShapeWindowInWindowCoordinate$(int edi_connectionID,int esi_windowID,char* rdx_region,int ecx,int r8d,int r9d,int stack);

CFMachPortRef SLSEventTapCreat$(int edi_location,NSString* rsi_priority,int edx_placement,int ecx_options,unsigned long r8_eventsOfInterest,void* r9_callback,void* stack_info);

void SLSWindowSetShadowPropertie$(int edi_windowID,NSDictionary* rsi_properties);

int SLSSetWindowTyp$(int,int,int,int,int,void*);

// SkyLight

int SLSMainConnectionID();

void SLSGetDockRectWithReason(int edi_connectionID,CGRect* rsi_rectOut,char* rdx_reasonOut);
void SLSSetDockRectWithReason(int edi_connectionID,int esi,CGRect stack_rect);

int SLSAddSurface(int edi_connectionID,int esi_windowID,int* rdx_surfaceIDOut);
int SLSOrderSurface(int edi_connectionID,int esi_windowID,int edx_surfaceID,int ecx_delta,int r8d_relativeSurfaceID);
int SLSSetSurfaceBounds(int edi_connectionID,int esi_windowID,int edx_surfaceID,CGRect stack_rect);
int SLSBindSurface(int edi_connectionID,int esi_windowID,int edx_surfaceID,int ecx,int r8d,int r9d_contextID);

int SLSGetWindowBounds(int edi_connectionID,int esi_windowID,CGRect* rdx_rectOut);
int SLSOrderWindow(int edi_connectionID,int esi,int edx,int ecx);
int SLSOrderWindowList(int edi_connectionID,int* rsi_list,int* rdx_list,int* rcx_list,int r8d_count);

int SLSRegisterConnectionNotifyProc(int edi_connectionID,void (*rsi_callback)(),int edx_type,char* rcx_context);
int SLSRegisterNotifyProc(void (*rdi_callback)(),int esi_type,char* rdx_context);
int SLSRequestNotificationsForWindows(int edi_connectionID,int* rsi_windowIDList,int edx_windowIDCount);

int SLSGetDisplayList(int edi_maxCount,int* rsi_idsOut,int* rdx_countOut);
int SLSCopyDisplayUUID(int edi_displayID,CFUUIDRef* rsi_uuidOut);

NSString* SLSCopyActiveMenuBarDisplayIdentifier(int edi_connectionID);
unsigned long SLSGetActiveSpace(int connectionID);
NSDictionary* SLSSpaceCopyValues(int edi_connectionID,unsigned long rsi_parentSpaceID);

void SLSSystemStatusBarRegisterSortedWindow(int edi_connectionID,int esi_windowID,int edx_priority,unsigned long rcx_spaceID,unsigned long r8_displayID,int r9d_flags,float xmm0_preferredPosition);
void SLSSystemStatusBarRegisterReplicantWindow(int edi_connectionID,int edi_windowID,int edx_windowNumber,unsigned long rcx_displayID,int r8d_flags);
void SLSUnregisterWindowWithSystemStatusBar(int edi_connectionID,int esi_windowID);
void SLSAdjustSystemStatusBarWindows(int edi_connectionID);

void SLSSessionSwitchToAuditSessionID(int edi_sessionID);

typedef void(^RemoteContextBlock)(id,int,int);
void SLSInstallRemoteContextNotificationHandler(NSString* rdi,RemoteContextBlock rsi);

int SLSPackagesEnableWindowOcclusionNotifications(int edi_connectionID,int esi_windowID,int edx,unsigned long rcx);

void SLDisplayForceToGray(BOOL);

char* SLSWindowBackdropCreateWithLevelAndTintColor(int edi_windowID,NSString* rsi_material,NSString* rdx_blendMode,unsigned long rcx_level,CGColorRef r8_tintColor,CGRect stack_frame);
void SLSWindowBackdropRelease(char* rdi_backdrop);
void SLSWindowBackdropActivate(char* rdi_backdrop);
void SLSWindowBackdropDeactivate(char* rdi_backdrop);

void SLSSetAppearanceThemeLegacy(BOOL);
BOOL SLSGetAppearanceThemeSwitchesAutomatically();

void SLSSetSessionSwitchCubeAnimation(BOOL);

extern const NSString* kSLSBuiltInDevicesKey;
extern const NSString* kSLSMouseDevicesKey;
extern const NSString* kSLSGestureScrollDevicesKey;

extern const NSString* kCGSWorkspaceWallSpaceKey;
extern const NSString* kCGSWorkspaceSpaceIDKey;

extern const NSString* kSLSAccessibilityAdjustmentMatrix;

// CoreGraphics private

CGRect* CGRegionGetBoundingBox(CGRect* rdi_rectOut,char* rsi_region);

extern const NSString* kCGMenuBarTitleMaterialKey;
extern const NSString* kCGMenuBarActiveMaterialKey;
extern const NSString* kCGMenuBarImageWindowKey;
extern const NSString* kCGMenuBarInactiveImageWindowKey;
extern const NSString* kCGMenuBarMenuTitlesArrayKey;
extern const NSString* kCGMenuBarDisplayIDKey;
extern const NSString* kCGMenuBarSpaceIDKey;

// HIServices private
// https://github.com/rcarmo/qsb-mac/blob/master/QuickSearchBox/externals/UndocumentedGoodness/CoreDock/CoreDockPrivate.h
void CoreDockGetOrientationAndPinning(unsigned long* orientationOut,unsigned long* pinningOut);

// QuartzCore private

@interface CAContext:NSObject

@property(assign) CALayer* layer;
@property int contextId;

+(NSArray<CAContext*>*)allContexts;
+(instancetype)contextWithCGSConnection:(int)edx_connectionID options:(NSDictionary*)rcx_options;
+(id)contextWithId:(int)contextID;

@end

@interface CALayer(Private)
-(CAContext*)context;
@end

@interface CADisplay:NSObject

+(NSArray<CADisplay*>*)displays;
+(CADisplay*)mainDisplay;

@end

#if MAJOR>=15
@interface CADisplayLink(Private)

+(instancetype)displayLinkWithDisplay:(CADisplay*)display target:(id)target selector:(SEL)action;

@end
#endif

@interface CATransaction(Private)

+(int)currentState;

@end

// IOKit

#if MAJOR == 11

#define kIOMainPortDefault kIOMasterPortDefault

#endif

// renamed only for Ventura

#if MAJOR>=13
void SLSTransactionCommi$(void* rdi,int esi);
#endif

// renamed always now

NSArray* SLSHWCaptureWindowLis$(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags);
NSArray* SLSHWCaptureWindowLis$InRect(int edi_cid,int* rsi_list,int edx_count,unsigned int ecx_flags,CGRect stack);

// TODO: dumped here by Amy for Ventura stuff, sort

int SLSMoveWindowOnMatchingDisplayChangedSeed(int edi,int esi,void* rdx,int ecx);
void SLSWindowSetActiveShadowLegacy(int edi,int esi);
void SLSSetSurfaceLayerBackingOptions(int edi,int esi,int edx,double xmm0,double xmm1,double xmm2);
void SLSSetWindowEventShape(int edi,int esi,void* rdx);
void SLSSetWindowRegionsLegacy(int edi,void* rsi,void* rdx,void* rcx,void* r8);
void SLSSetWindowHasMainAppearance(int edi,int esi,int edx);
void SLSSetWindowHasKeyAppearance(int edi,int esi,int edx);
void SLSSetWindowCornerMask(int edi,void* rsi,int edx,CGRect stack);
void SLSSetWindowOriginRelativeToWindow(int edi,int esi,int edx,int ecx,double xmm0,double xmm1);
int SLSAddWindowToWindowMovementGroup(int edi,int esi,int edx);
int SLSRemoveWindowFromWindowMovementGroup(int edi,int esi,int edx);
void SLSTileSpaceMoveSpacersForSize(long rdi,int esi,double xmm0,double xmm1);
void SLSSpaceClientDrivenMoveSpacersToPoint(int edi_cid,long rsi_parentSpaceID,long rdx_tileSpaceID,long rcx_verticalIndex,long r8_horizontalIndex,int r9d_flags,double xmm0_location,double xmm1);

CGContextRef SLWindowContextCreate(int,int,CFDictionaryRef);
CGImageRef SLWindowContextCreateImage(CGContextRef);
int SLSNewWindow(int edi_cid,int esi_backing,void* rdx_region,int* rcx_widOut,double xmm0,double xmm1);
void SLSReleaseWindow(int edi_cid,int esi_wid);
int SLSSetWindowOpaqueShape(int edi_cid,int esi_wid,void* rdx_region);
int SLSSetWindowOpacity(int edi_cid,int esi_wid,BOOL dl_opaque);
int CGSNewRegionWithRect(CGRect* rdi_rect,void* rsi_regionOut);

NSDictionary* SLSCopyCurrentSessionDictionary();
void SLSSetDictionaryForCurrentSession(NSDictionary*);
void* SLSWindowQueryCreate(int edi);
void* SLSWindowQueryRun(int edi_cid,void* rsi_query,int edx);
void* SLSWindowQueryResultCopyWindows(void* rdi_result);
long SLSWindowIteratorGetCount(void* rdi_iterator);
int SLSWindowIteratorGetWindowID(void* rdi_iterator,long rsi_index);
long SLSWindowIteratorGetTags(void* rdi_iterator,long rsi_index);
int SLSWindowIteratorGetPID(void* rdi_iterator,long rsi_index);
long SLSWindowIteratorGetSpaceAttributes(void* rdi_iterator,long rsi_index);
void SLSWindowIteratorGetScreenRect(CGRect* rdi_out,void* rsi_iterator,long rsi_index);
NSArray<NSDictionary*>* SLSCopyManagedDisplaySpaces(int edi_cid);
int SLSGetDisplayForUUID(CFUUIDRef rdi_uuid);
int SLSGetDisplaysWithRect(CGRect* rdi_rect,int esi_count,int* rdx_listOut,int* rcx_countOut);
int SLSGetWindowBounds(int edi_cid,int esi_wid,CGRect* rdx_rectOut);

// TODO: dumb but we can't link AppKit

@class NSWindowLite;

@interface NSViewLite:NSObject

@property(assign) NSWindowLite* window;
@property(assign) BOOL wantsLayer;
@property(retain) CALayer* layer;
@property(retain) NSArray* subviews;
@property(assign) CGRect frame;

-(void)addSubview:(NSViewLite*)child;

@end

@interface NSColorLite:NSObject

+(NSColorLite*)clearColor;

@end

@interface NSWindowLite:NSObject

@property(assign) unsigned int windowNumber;
@property(retain) NSViewLite* contentView;
@property(assign) BOOL opaque;
@property(retain) NSColorLite* backgroundColor;

-(instancetype)initWithContentRect:(CGRect)contentRect styleMask:(long)style backing:(long)backingStoreType defer:(BOOL)flag;

@end

#define NSBackingStoreBuffered 2

@interface NSVisualEffectViewLite:NSViewLite

@property(assign) BOOL _shouldUseActiveAppearance;
@property(assign) long blendingMode;

@end

@interface NSBitmapImageRepLite:NSObject

-(instancetype)initWithCGImage:(CGImageRef)image;

@end
