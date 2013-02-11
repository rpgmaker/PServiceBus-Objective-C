#import <Foundation/Foundation.h>
#import "callbackop.h"
#import "psb.h"

#ifdef UI_USER_INTERFACE_IDIOM
	#define PSB_UI
#endif

@interface RestHelper : NSObject {
	
}

+ (RestHelper *) instance;
+ (NSString *) _Invoke:(NSString *)methodName value:(NSDictionary *)value;
- (void) Invoke: (NSString *)methodName value:(NSDictionary *)value callback:(OneStringBlock)callback;

@end