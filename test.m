#import <Foundation/Foundation.h>
#import "rest.h"


int main (int argc, const char * argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDictionary *value = [[[NSDictionary alloc] initWithObjectsAndKeys: 
        @"ChatTopic", @"name",
		nil] autorelease];

	[[RestHelper instance] Invoke: @"SelectTopic" value:value callback: ^(NSString * result) {
		NSLog(@"%@", result);
	}];
	
	[pool drain];
		
	return 0;
}