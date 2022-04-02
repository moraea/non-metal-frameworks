#import "Notifications.h"

// Renamer

unsigned int SLSNewWindowWithOpaqueShap$(unsigned int edi_connectionID,unsigned int esi,char* rdx_region,char* rcx_region,unsigned int r8d,char* r9,unsigned long stack1_windowID,unsigned long stack2,double xmm0,double xmm1);

unsigned int SLSSetMenuBar$(unsigned int edi_connectionID,NSMutableArray* rsi_array,NSMutableDictionary* rdx_dict);

NSDictionary* SLSCopyDevicesDictionar$();

dispatch_block_t SLSCopyCoordinatedDistributedNotificationContinuationBloc$();

unsigned int SLSShapeWindowInWindowCoordinate$(unsigned int edi_connectionID,unsigned int esi_windowID,char* rdx_region,unsigned int ecx,unsigned int r8d,unsigned int r9d,unsigned int stack);

CFMachPortRef SLSEventTapCreat$(unsigned int edi_location,NSString* rsi_priority,unsigned int edx_placement,unsigned int ecx_options,unsigned long r8_eventsOfInterest,void* r9_callback,void* stack_info);

void SLSWindowSetShadowPropertie$(unsigned int edi_windowID,NSDictionary* rsi_properties);

// SkyLight

unsigned int SLSMainConnectionID();

void SLSGetDockRectWithReason(unsigned int edi_connectionID,CGRect* rsi_rectOut,char* rdx_reasonOut);
void SLSSetDockRectWithReason(unsigned int edi_connectionID,unsigned int esi,CGRect stack_rect);

unsigned int SLSAddSurface(unsigned int edi_connectionID,unsigned int esi_windowID,unsigned int* rdx_surfaceIDOut);
unsigned int SLSOrderSurface(unsigned int edi_connectionID,unsigned int esi_windowID,unsigned int edx_surfaceID,unsigned int ecx_delta,unsigned int r8d_relativeSurfaceID);
unsigned int SLSSetSurfaceBounds(unsigned int edi_connectionID,unsigned int esi_windowID,unsigned int edx_surfaceID,CGRect stack_rect);
unsigned int SLSBindSurface(unsigned int edi_connectionID,unsigned int esi_windowID,unsigned int edx_surfaceID,unsigned int ecx,unsigned int r8d,unsigned int r9d_contextID);

unsigned int SLSGetWindowBounds(unsigned int edi_connectionID,unsigned int esi_windowID,CGRect* rdx_rectOut);
unsigned int SLSOrderWindow(unsigned int edi_connectionID,unsigned int esi,unsigned int edx,unsigned int ecx);
unsigned int SLSOrderWindowList(unsigned int edi_connectionID,unsigned int* rsi_list,unsigned int* rdx_list,unsigned int* rcx_list,unsigned int r8d_count);

unsigned int SLSRegisterConnectionNotifyProc(unsigned int edi_connectionID,void (*rdi_callback)(),unsigned int edx_type,char* rcx_context);
unsigned int SLSRequestNotificationsForWindows(unsigned int edi_connectionID,unsigned int* rsi_windowIDList,unsigned int edx_windowIDCount);

unsigned int SLSGetDisplayList(unsigned int edi_maxCount,unsigned int* rsi_idsOut,unsigned int* rdx_countOut);
unsigned int SLSCopyDisplayUUID(unsigned int edi_displayID,CFUUIDRef* rsi_uuidOut);

NSString* SLSCopyActiveMenuBarDisplayIdentifier(unsigned int edi_connectionID);
unsigned long SLSGetActiveSpace(unsigned int connectionID);
NSDictionary* SLSSpaceCopyValues(unsigned int edi_connectionID,unsigned long rsi_parentSpaceID);

void SLSSystemStatusBarRegisterSortedWindow(unsigned int edi_connectionID,unsigned int esi_windowID,unsigned int edx_priority,unsigned long rcx_spaceID,unsigned long r8_displayID,unsigned int r9d_flags,float xmm0_preferredPosition);
void SLSSystemStatusBarRegisterReplicantWindow(unsigned int edi_connectionID,unsigned int edi_windowID,unsigned int edx_windowNumber,unsigned long rcx_displayID,unsigned int r8d_flags);
void SLSUnregisterWindowWithSystemStatusBar(unsigned int edi_connectionID,unsigned int esi_windowID);
void SLSAdjustSystemStatusBarWindows(unsigned int edi_connectionID);

void SLSSessionSwitchToAuditSessionID(unsigned int edi_sessionID);

typedef void(^RemoteContextBlock)(id,unsigned int,unsigned int);
void SLSInstallRemoteContextNotificationHandler(NSString* rdi,RemoteContextBlock rsi);

unsigned int SLSPackagesEnableWindowOcclusionNotifications(unsigned int edi_connectionID,unsigned int esi_windowID,unsigned int edx,unsigned long rcx);

void SLDisplayForceToGray(BOOL);

char* SLSWindowBackdropCreateWithLevelAndTintColor(unsigned int edi_windowID,NSString* rsi_material,NSString* rdx_blendMode,unsigned long rcx_level,CGColorRef r8_tintColor,CGRect stack_frame);
void SLSWindowBackdropRelease(char* rdi_backdrop);
void SLSWindowBackdropActivate(char* rdi_backdrop);
void SLSWindowBackdropDeactivate(char* rdi_backdrop);

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

// HIServices private
// https://github.com/rcarmo/qsb-mac/blob/master/QuickSearchBox/externals/UndocumentedGoodness/CoreDock/CoreDockPrivate.h
void CoreDockGetOrientationAndPinning(unsigned long* orientationOut,unsigned long* pinningOut);

// QuartzCore private

@interface CAContext:NSObject

@property(assign) CALayer* layer;
@property unsigned int contextId;

+(instancetype)contextWithCGSConnection:(unsigned int)edx_connectionID options:(NSDictionary*)rcx_options;

@end

// IOKit

#if MAJOR == 11

#define kIOMainPortDefault kIOMasterPortDefault

#endif