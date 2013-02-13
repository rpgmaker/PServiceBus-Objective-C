#import <Foundation/Foundation.h>
#import "callbackop.h"
#import "psb.h"

#ifdef UI_USER_INTERFACE_IDIOM
	#define PSB_UI
#endif

@interface RestHelper : NSObject {
	
}

+ (NSString *) invokeRequest:(NSString *)methodName value:(NSDictionary *)value;
+ (void) invoke:(NSString *)methodName value:(NSDictionary *)value callback:(PSBOneStringBlock)callback;
+ (void) invoke:(NSString *)methodName value:(NSDictionary *)value;

@end