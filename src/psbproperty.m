#import "psbproperty.h"


@implementation PSBPropertyInfo

@synthesize clazz, name, primitive;

- (PSBPropertyInfo *) initWith:(objc_property_t)prop {
    self = [super init];
    if(self){
        NSString *key = [NSString stringWithUTF8String:property_getName(prop)];
        NSArray *keyTokens = [key componentsSeparatedByString: [NSString stringWithFormat: @"set%@", [[key substringToIndex: 1] uppercaseString]]];
        key = (NSString *)[keyTokens objectAtIndex: 0];

        const char *attribute = property_getAttributes(prop);

        NSString *propClassStr = [NSString stringWithCString:attribute encoding:NSASCIIStringEncoding];
        NSArray *tokens = [propClassStr componentsSeparatedByString: @"\""];

        NSString *className = (NSString *)[tokens objectAtIndex: 1];

        Class propClass = NSClassFromString(className);

        self.primitive =
            propClass == [NSString class] ||
            propClass == [NSNumber class] ||
            propClass == [NSDictionary class] ||
            propClass == [NSArray class];

        self.name = key;
        self.clazz = propClass;
    }
    return self;
}

@end

