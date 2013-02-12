#import <Foundation/Foundation.h>
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
	
		NSDictionary *value = [[[NSDictionary alloc] initWithObjectsAndKeys: 
			@"ChatTopic", @"name",
			nil] autorelease];
				
		//id obj = [[TestObject alloc] init];
		
		//NSString *name =  NSStringFromClass([obj class]);
		
		//NSLog(@"%@", name);
		
		[[RestHelper instance] Invoke: @"SelectTopic" value:value callback: ^(NSString * result) {
			NSLog(@"%@", result);
		}];
		
	}
	
	return 0;
}