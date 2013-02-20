#import "httpstreaming.h"

int const MAX_BUFFER_SIZE = 8;

@interface PSBHttpStreaming ()

@property (readwrite, nonatomic, copy) PSBOneStringBlock callback;
@property (readwrite) bool running;
@property (readwrite) NSMutableData *lastBuffer;
@property (readwrite) NSMutableData *bigBuffer;

@property (readwrite) NSMutableURLRequest *client;
@property (readwrite) NSURLResponse *response;

@property (readwrite) NSMutableData *buffer;

@property (readwrite) NSString *url;

@end

@implementation PSBHttpStreaming

@synthesize callback, running, lastBuffer, bigBuffer,
    client, response, buffer, url = url;

static NSRegularExpression *cometRegex = nil;
static NSOperationQueue *httpQueue = nil;
static NSData *delimeter = nil;

+ (void) initialize {
    NSError *error = nil;
    cometRegex = [NSRegularExpression regularExpressionWithPattern: @"(<comet)?>(?<Data>.+?)</comet>"
        options:NSRegularExpressionCaseInsensitive error: &error];

    httpQueue = [[NSOperationQueue alloc] init];
	httpQueue.name = @"HTTP Streaming";

	delimeter = [@"</comet>" dataUsingEncoding: NSUTF8StringEncoding];
}

- (PSBHttpStreaming *) initWithUrl:(NSString *)value {
    self = [super init];
    if(self){
        self.url = value;
        self.bigBuffer = [NSMutableData dataWithLength: MAX_BUFFER_SIZE * 2];
        self.buffer = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc {
    [url release];
    [callback release];
    [client release];
    [response release];
    [lastBuffer release];
    [bigBuffer release];
    [super dealloc];
}

- (void) start {
    if(self.running) [NSException raise: @"running" format: @"Streaming is already in progress"];
    self.running = true;
    client = [NSURLRequest requestWithURL:[NSURL URLWithString: self.url]];
    [[[NSURLConnection alloc] initWithRequest:client delegate:self] autorelease];
}

- (void) stop {

}

- (void) readBuffer:(NSURLResponse *)response {

}

- (bool) hasData:(NSData *)buffer {
    return false;
}

- (void) processBuffer:(NSData *)buffer {

}

- (void) onReceived:(PSBOneStringBlock)value {
    self.callback = value;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

}


@end

