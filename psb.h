#import <Foundation/Foundation.h>
#import "rest.h"

extern NSString * const USERNAME_KEY;
extern NSString * const ESBTOPIC_HEADERS;
extern NSString * const STREAM_URL;

typedef void (^PSBVoidBlock)(void);

typedef void (^PSBMessageBlock)(id * message);

typedef enum {
    MSMQ = 0,
    RabbitMQ = 1,
    Tcp = 2,
	Redis = 6
} TransportType;

@interface PSBClient : NSObject {}

+ (void) disconnect;
+ (void) _registerTopic:(NSString *)name description:(NSString *)description contract:(NSDictionary *)contract;
+ (void) unRegisterTopic:(NSString *)name;
+ (NSString *) parseAddress:(NSString *)topicName;
+ (NSDictionary *) getTransportData:(NSString *)topicName;
+ (void) unSubscribeFromTopic:(NSString *)topicName;
+ (void) cleanUp;

+ (void) onDisconnect:(PSBVoidBlock)value;
+ (void) apikey:(NSString *)value;
+ (void) passcode:(NSString *)value;
+ (void) address:(NSString *)value;
+ (void) transport:(TransportType)value;
+ (void) endpoint:(NSString *)value;
+ (void) durable:(BOOL)value;
+ (void) throwException:(BOOL)value;
+ (NSString *) endpoint;
+ (NSString *) username;
+ (BOOL) throwException;
+ (NSString *) apikey;
+ (NSString *) passcode;

+ (void) ping:(void (^)(BOOL success))callback;
+ (void) update:(Class)clazz filter:(NSString *)filter caseSensitive:(BOOL)caseSensitive;
+ (void) update:(Class)clazz filter:(NSString *)filter;

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize caseSensitive:(BOOL)caseSensitive;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback;

+ (void) unSubscribe:(NSString *)topicName;
+ (void) unSubscribeWith:(Class)clazz;

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn headers:(NSDictionary *)headers;
+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn;
+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID;
+ (void) publish:(id)message;


+ (void) unRegister:(NSString *)name;
+ (void) unRegisterWith:(Class)clazz;
+ (void) registerTopicWith:(Class)clazz;
+ (void) registerTopic:(NSString *)name description:(NSString *)description;
+ (void) registerTopic:(NSString *)name;

@end

