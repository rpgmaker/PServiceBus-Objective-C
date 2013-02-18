#import <objc/runtime.h>
#import "psbproperty.h"
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

    if([obj isKindOfClass: [NSDictionary class]]){
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
        NSDictionary *nDict = (NSDictionary *)obj;
        NSEnumerator *enumerator = [nDict keyEnumerator];
        id itemKey;

        while((itemKey = [enumerator nextObject])){
            id item = [nDict objectForKey: itemKey];
            Class itemClass = [item class];
            bool isPrimitive = itemClass == [NSString class] ||
                itemClass == [NSNumber class];
            if(isPrimitive) [mDict setObject:item forKey:itemKey];
            else {
                [mDict setObject:[self objectToDictionary: item] forKey:itemKey];
            }
        }

        return [NSDictionary dictionaryWithDictionary:mDict];
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);

    for (int i = 0; i < count; i++) {

        objc_property_t prop = properties[i];

        PSBPropertyInfo *propInfo = [[PSBPropertyInfo alloc] initWith: prop];

        NSString *key = propInfo.name;

        id value = [obj valueForKey:key];

        if(value == nil) continue;

        if (!propInfo.primitive)
            value = [self objectToDictionary: value];
        else {
            if([value isKindOfClass: [NSDictionary class]])
                value = [self objectToDictionary: (NSDictionary *)value];
        }

        [dict setObject:value forKey:key];
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

        PSBPropertyInfo *propInfo = [[PSBPropertyInfo alloc] initWith: prop];

        NSString *key = propInfo.name;

        id value = [dict valueForKey: key];

        if(value == nil) continue;

        if(!propInfo.primitive){
            NSDictionary *nDict = (NSDictionary *)value;
            value = [self dictionaryToObject:nDict clazz: propInfo.clazz];
        }

        [obj setValue:value forKey:key];
    }
    return obj;
}

@end
