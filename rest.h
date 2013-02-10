#import <Foundation/Foundation.h>

#ifdef UI_USER_INTERFACE_IDIOM
	#define PSB_UI
#endif

//typedef void (^PSBAction)(NSString *result);

@interface RestHelper : NSObject {
	
}


+ (RestHelper *) instance;
+ (NSString *) _Invoke:(NSString *)methodName value:(NSDictionary *)value;
- (void) Invoke: (NSString *)methodName value:(NSDictionary *)value;

@end