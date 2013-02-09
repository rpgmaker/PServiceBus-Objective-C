#import <Foundation/Foundation.h>
#import "rest.h"

int main (int argc, const char * argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *json = @"{\"name\" : \"ChatTopic\"}"; 
	
	[[RestHelper instance] Invoke: @"SelectTopic" json: json];
	
	[pool drain];
		
	return 0;
}