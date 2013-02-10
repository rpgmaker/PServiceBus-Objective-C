#import <Foundation/Foundation.h>

#ifdef UI_USER_INTERFACE_IDIOM
	#define PSB_UI
#endif
#define PSB_UI


@interface RestHelper : NSObject {
	
}


+ (RestHelper *) instance;
+ (NSString *) _Invoke:(NSString *)methodName value:(NSDictionary *)value;
- (void) Invoke: (NSString *)methodName value:(NSDictionary *)value callback:(void (^)(NSString *))callback;

@end