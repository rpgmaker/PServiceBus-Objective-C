#import "rest.h"

@implementation RestHelper

static RestHelper *restInstance = nil;
static NSOperationQueue *restQueue = nil;

+ (RestHelper *) instance {		
	if(restInstance != nil) return restInstance;
	if(restQueue == nil){
		restQueue = [[NSOperationQueue alloc] init];
		restQueue.name = @"PSB REST API";
	}
	restInstance = [[RestHelper alloc] init];
	return restInstance;
}

+ (NSString *) _Invoke:(NSString *)methodName value:(NSDictionary *)value {

	NSMutableData *data = [[NSMutableData alloc] init];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSError *jsonError = nil;
	
	NSString *urlStr = [NSString stringWithFormat:@"http://localhost:8087/esb/%@", methodName];
    
	NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	
    NSData *buffer = [NSJSONSerialization dataWithJSONObject: value options:0 error:&jsonError];
	
	[request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: buffer];

	[data appendData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];
    
	if(error) @throw error; 
	
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

- (void) Invoke: (NSString *)methodName value:(NSDictionary *)value callback:(PSBOneStringBlock)callback {
	#ifdef PSB_UI
		PSBRestOperation *op = [[[PSBRestOperation alloc] initWithRequest:methodName value:value callback:callback] autorelease];
		[restQueue addOperation : op];
	#else
		NSString *result = [RestHelper _Invoke: methodName value: value];
		callback(result);
	#endif
}

@end