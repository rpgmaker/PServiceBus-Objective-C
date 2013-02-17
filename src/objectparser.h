#import <Foundation/Foundation.h>

@interface PSBJSONParser : NSObject {}


+ (id) jsonToObject:(NSString *)json clazz:(Class)clazz;

+ (NSDictionary *) jsonToDictionary:(NSString *)json;

+ (NSString *) toJSONString:(id)obj;

+ (NSData *) toJSONData:(id)obj;

+ (NSDictionary *) objectToDictionary:(id)obj;

+ (id) dictionaryToObject:(NSDictionary *)dict clazz:(Class)clazz;

@end
