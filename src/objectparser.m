#import "objectparser.h"

@implementation PSBJSONParser

+ (id) jsonToObject:(NSString *)json clazz:(Class)clazz {
    NSDictionary *dict = [self jsonToDictionary: json];
    return [self dictionaryToObject: dict clazz: clazz];
}

+ (NSDictionary *) jsonToDictionary:(NSString *)json {
    NSError *error = nil;
    NSData * buffer = [json dataUsingEncoding: NSUTF8StringEncoding];
    return (NSDictionary *)[NSJSONSerialization JSONObjectWithData: buffer options:0 error:&error];
}

+ (NSString *) toJSONString:(id)obj {
    NSData *buffer = [self toJSONData: obj];
    return [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
}

+ (NSData *) toJSONData:(id)obj {
    BOOL isRegularClass = [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]] ? NO : YES;
    NSError *error = nil;
    if(isRegularClass == YES)
        obj = [self objectToDictionary: obj];
    return [NSJSONSerialization dataWithJSONObject: obj options:0 error:&error];
}

+ (NSDictionary *) objectToDictionary:(id)obj {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);

    for (int i = 0; i < count; i++) {
        objc_property_t prop = properties[i];

        NSString *key = [NSString stringWithUTF8String:property_getName(prop)];
        NSArray *keyTokens = [key componentsSeparatedByString: [NSString stringWithFormat: @"set%@", [[key substringToIndex: 1] uppercaseString]]];
        key = (NSString *)[keyTokens objectAtIndex: 0];

        const char *attribute = property_getAttributes(prop);

        NSString *propClassStr = [NSString stringWithCString:attribute encoding:NSASCIIStringEncoding];
        NSArray *tokens = [propClassStr componentsSeparatedByString: @"\""];

        NSString *className = (NSString *)[tokens objectAtIndex: 1];

        Class propClass = NSClassFromString(className);

        BOOL isPrimitive =
            propClass == [NSString class] ||
            propClass == [NSNumber class] ||
            propClass == [NSDictionary class] ||
            propClass == [NSArray class] ? YES : NO;

        if (isPrimitive == NO) {
            id subObj = [self objectToDictionary:[obj valueForKey:key]];
            [dict setObject:subObj forKey:key];
        }
        else
        {
            id value = [obj valueForKey:key];
            if(value) [dict setObject:value forKey:key];
        }
    }

    free(properties);

    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (id) dictionaryToObject:(NSDictionary *)dict clazz:(Class)clazz {
    id obj = [[clazz alloc] init];

    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);

    for (int i = 0; i < count; i++) {
        objc_property_t prop = properties[i];

        NSString *key = [NSString stringWithUTF8String:property_getName(prop)];
        NSArray *keyTokens = [key componentsSeparatedByString: [NSString stringWithFormat: @"set%@", [[key substringToIndex: 1] uppercaseString]]];
        key = (NSString *)[keyTokens objectAtIndex: 0];

        const char *attribute = property_getAttributes(prop);

        NSString *propClassStr = [NSString stringWithCString:attribute encoding:NSASCIIStringEncoding];
        NSArray *tokens = [propClassStr componentsSeparatedByString: @"\""];

        NSString *className = (NSString *)[tokens objectAtIndex: 1];

        Class propClass = NSClassFromString(className);

        BOOL isPrimitive =
            propClass == [NSString class] ||
            propClass == [NSNumber class] ||
            propClass == [NSDictionary class] ||
            propClass == [NSArray class] ? YES : NO;

        if(isPrimitive == NO){
            NSDictionary *nDict = (NSDictionary *)[dict valueForKey: key];
            id nObj = [self dictionaryToObject:nDict clazz: propClass];
            [obj setValue:nObj forKey: key];
        }else{
            id value = [dict valueForKey: key];
            [obj setValue:value forKey:key];
        }
    }
    return obj;
}

@end
