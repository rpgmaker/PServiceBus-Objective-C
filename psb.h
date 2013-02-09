#import <Foundation/Foundation.h>

extern NSString * const USERNAME_KEY;
extern NSString * const ESBTOPIC_HEADERS;
extern NSString * const STREAM_URL;
	
@interface PSBClient : NSObject {
	
}

+ (NSString *)username;
+ (NSString *)apikey;
+ (NSString *)passcode;
+ (NSString *)address;
+ (void) Register:(NSString *)name description:(NSString *)description;
+ (void) Register:(NSString *)name;

@end