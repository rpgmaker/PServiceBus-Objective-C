#import <Foundation/Foundation.h>
#import "rest.h"

extern NSString * const USERNAME_KEY;
extern NSString * const ESBTOPIC_HEADERS;
extern NSString * const STREAM_URL;

typedef void (^PSBVoidBlock)(void);

typedef enum {
    MSMQ = 0,
    RabbitMQ = 1,
    Tcp = 2,
	Redis = 6
} TransportType;
	
@interface PSBClient : NSObject {
	+ (NSString *) username;
	+ (NSDictionary *) handlers;
	+ (NSDictionary *) topics;
	+ (void) disconnect;
	+ (void) _registerTopic:(NSString *)name description:(NSString *)description;
	+ (void) unRegisterTopic:(NSString *)name;
	+ (NSString *) parseAddress:(NSString *)topicName;
	+ (NSDictionary *) getTransportData:(NSString *)topicName;
	+ (void) unSubscribeFromTopic:(NSString *)topicName;
	+ (void) cleanUp;
}


+ (void) onDisconnect:(PSBVoidBlock)value;
+ (void) apikey:(NSString *)value;
+ (void) passcode:(NSString *)value;
+ (void) address:(NSString *)value;
+ (void) transport:(TransportType)value;
+ (void) endpoint:(NSString *)value;
+ (void) durable:(BOOL)value;
+ (void) throwException:(BOOL)value;
+ (NSString *) endpoint;

+ (void) unRegister:(NSString *)name;
+ (void) unRegisterWith:(Class *)clazz;
+ (void) registerTopicWith:(Class *)clazz;
+ (void) registerTopic:(NSString *)name description:(NSString *)description;
+ (void) registerTopic:(NSString *)name;

@end