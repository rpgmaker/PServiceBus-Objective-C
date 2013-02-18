#import "objectparser.h"
#import "rest.h"


@implementation RestHelper

static NSOperationQueue *restQueue = nil;

+ (void) initialize {
	if(restQueue != nil) return;
	restQueue = [[NSOperationQueue alloc] init];
	restQueue.name = @"PSB REST API";
}

+ (NSString *) invokeRequest:(NSString *)methodName value:(NSDictionary *)value {

	NSMutableData *data = [[NSMutableData alloc] init];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSError *jsonError = nil;

	NSString *urlStr = [NSString stringWithFormat:@"%@%@?ReThrowException=%@&ESBUserName=%@&ESBPassword=%@&ConnectionID=%@",
		[PSBClient endpoint], methodName, [PSBClient throwException] ? @"true" : @"false",
		[PSBClient apikey], [PSBClient passcode], [PSBClient username]];

	NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    NSData *buffer = [PSBJSONParser toJSONData: value];

	[request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: buffer];

	[data appendData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];

	if(error) @throw error;

	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

+ (void) invoke: (NSString *)methodName value:(NSDictionary *)value callback:(PSBOneStringBlock)callback {
	#ifdef PSB_UI
		PSBRestOperation *op = [[[PSBRestOperation alloc] initWithRequest:methodName value:value callback:callback] autorelease];
		[restQueue addOperation : op];
	#else
		NSString *result = [self invokeRequest: methodName value: value];
		if(callback) callback(result);
		[value release];
	#endif
}

+ (void) invoke: (NSString *)methodName value:(NSDictionary *)value {
	[RestHelper invoke: methodName value:value callback: ^(NSString * _) {}];
}

@end
