#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "psb.h"
#import "objectparser.h"

@interface TestObject : NSObject {}

@property (retain) NSString *setting;

@end

@implementation TestObject

@synthesize setting;

@end

int main (int argc, const char * argv[])
{
	@autoreleasepool {
		NSDictionary *value = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"ChatTopic", @"name",
			nil];

		TestObject *obj = [[TestObject alloc] init];
		obj.setting = @"Testing";

		//NSString *name =  NSStringFromClass([obj class]);

		//NSLog(@"%@", name);

		//[RestHelper invoke: @"SelectTopic" value:value callback: ^(NSString * result) {
		//	NSLog(@"%@", result);
		//}];

		NSString *json = [PSBJSONParser toJSONString: obj];

		NSLog(@"%@", json);
		TestObject *obj2 = (TestObject *)[PSBJSONParser jsonToObject: json clazz: [TestObject class]];
		NSLog(@"%@", obj2.setting);
	}

	return 0;
}
