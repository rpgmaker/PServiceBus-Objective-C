#import "httpstreaming.h"

int const MAX_BUFFER_SIZE = 8;

@interface PSBHttpStreaming ()

@property (readwrite, nonatomic, copy) PSBOneStringBlock callback;
@property (readwrite) bool running;
@property (readwrite) NSMutableData *lastBuffer;
@property (readwrite) NSMutableData *bigBuffer;

@property (readwrite) NSURLConnection *client;
@property (readwrite) NSMutableURLRequest *request;
@property (readwrite) NSURLResponse *response;

@property (readwrite) NSMutableData *buffer;

@property (readwrite) NSString *url;

@end

@implementation PSBHttpStreaming

@synthesize callback, running, lastBuffer, bigBuffer,
    client, response, buffer, url, request;

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
    [request release];
    [response release];
    [lastBuffer release];
    [bigBuffer release];
    [super dealloc];
}

- (void) start {
    if(running) [NSException raise: @"running" format: @"Streaming is already in progress"];
    running = true;
    request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod: @"GET"];
    [request setTimeoutInterval: 60.0 * 60.0];
    client = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
    [client setDelegateQueue: httpQueue];
    [client start];
}

- (void) stop {
    if(!running) return;
    running = false;
    @try{
        [client cancel];
    }
    @catch(id ex){ }
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
    unsigned long length = [data length];
    unsigned long iterations = length / MAX_BUFFER_SIZE;
    unsigned long reads = iterations * MAX_BUFFER_SIZE;
    int remains = length - reads;

    for(int i = 0; i < iterations; i++){
        int startIndex = i * MAX_BUFFER_SIZE;
        int endIndex = startIndex + MAX_BUFFER_SIZE;
        NSRange range = {startIndex, endIndex};
        NSData *read = [data subdataWithRange: range];
        [buffer appendData: read];
        if([self hasData: read])
            [self processBuffer: buffer];
    }
    if(remains > 0){
        NSRange remainRange = {reads, length};
        NSData *remain = [data subdataWithRange: remainRange];
        [buffer appendData: remain];
        if([self hasData: remain])
            [self processBuffer: buffer];
    }

    if(length > MAX_BUFFER_SIZE){
        NSRange lastRange = {length - MAX_BUFFER_SIZE, length};
        [lastBuffer setData: [data subdataWithRange: lastRange]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

}


@end

