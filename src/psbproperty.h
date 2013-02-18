#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface PSBPropertyInfo : NSObject {}

@property (retain) Class clazz;
@property (retain) NSString *name;
@property (nonatomic, readwrite) bool primitive;

- (PSBPropertyInfo *) initWith:(objc_property_t)prop;

@end
