#import <Foundation/Foundation.h>

@interface RestHelper : NSObject {
	
}

+ (RestHelper *) instance;
- (void) Invoke:(NSString *)name json:(NSString *)json;

@end