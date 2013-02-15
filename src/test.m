#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "psb.h"

@interface TestObject : NSObject {}

@property (retain) NSString *value;

@end

@implementation TestObject 

@synthesize value;

@end

int main (int argc, const char * argv[])
{
	@autoreleasepool {
		NSDictionary *value = [[NSDictionary alloc] initWithObjectsAndKeys: 
			@"ChatTopic", @"name",
			nil];
				
		//id obj = [[TestObject alloc] init];
		
		//NSString *name =  NSStringFromClass([obj class]);
		
		//NSLog(@"%@", name);
		
		[RestHelper invoke: @"SelectTopic" value:value callback: ^(NSString * result) {
			NSLog(@"%@", result);
		}];
		
	}
	
	return 0;
}