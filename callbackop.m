#import "callbackop.h"
#import "rest.h"

@implementation PSBRestOperation

@synthesize callback, methodName, value;

- (PSBRestOperation *) initWithRequest:(NSString *)pmethodName value:(NSDictionary *)pvalue callback:(PSBOneStringBlock)pcallback {
	
	self = [super init];
	
	if(self){
		self.callback = pcallback;
		self.methodName = pmethodName;
		self.value = pvalue;
	}
	
	return self;
}

- (void) main {	
	NSString *result = [RestHelper invokeRequest: methodName value:value];
	if(callback) {
		callback(result);
		[callback release];
	}
	[value release];
}

@end