#import "rest.h"

static RestHelper *restInstance = nil;

@implementation RestHelper

+ (RestHelper *) instance {
	if(restInstance != nil) return restInstance;
	
	restInstance = [[RestHelper alloc] init];
	
	return restInstance;
}

- (void) Invoke:(NSString *)name json:(NSString *)json {
		
	NSMutableData *data = [[NSMutableData alloc] init];

	NSString *urlStr = [NSString stringWithFormat:@"http://localhost:8087/esb/%@", name];
	
    NSURL *url = [NSURL URLWithString:urlStr];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	
	NSURLResponse *response = nil;
	
	NSError *error = nil;
	
    NSData *buffer = [NSData dataWithBytes:[json UTF8String] length:[json length]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: buffer];

	[data appendData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];

    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	NSLog(result);
}

@end