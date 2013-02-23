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
@property (readwrite) NSMutableData *stream;

@property (readwrite) NSString *url;

@end

@implementation PSBHttpStreaming

@synthesize callback, running, lastBuffer, bigBuffer,
    client, response, buffer, url, request, stream;

static NSRegularExpression *cometRegex = nil;
static NSOperationQueue *httpQueue = nil;
static NSData *delimeter = nil;

+ (void) initialize {
    NSError *error = nil;
    cometRegex = [NSRegularExpression regularExpressionWithPattern: @"(<comet)?>(.+?)</comet>"
        options:NSRegularExpressionCaseInsensitive error: &error];

    httpQueue = [[NSOperationQueue alloc] init];
	httpQueue.name = @"HTTP Streaming";

	delimeter = [@"</comet>" dataUsingEncoding: NSUTF8StringEncoding];
}

- (PSBHttpStreaming *) initWithUrl:(NSString *)value {
    self = [super init];
    if(self){
        self.url = value;
        self.lastBuffer = [NSMutableData dataWithLength: MAX_BUFFER_SIZE];
        self.bigBuffer = [NSMutableData dataWithLength: MAX_BUFFER_SIZE * 2];
        self.buffer = [[NSMutableData alloc] init];
        self.stream = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc {
    [url release];
    [callback release];
    [request release];
    [response release];
    [bigBuffer release];
    [lastBuffer release];
    [super dealloc];
}

- (void) start {
    if(running) [NSException raise: @"running" format: @"Streaming is already in progress"];
    running = true;
    request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod: @"GET"];
    [request setTimeoutInterval: 60.0 * 60.0 * 24.0];
    client = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
    [client setDelegateQueue: httpQueue];
    [client start];

    NSThread *thread = [[NSThread alloc] initWithTarget:self selector: @selector(readBuffer:) object: nil];
    [thread start];
}

- (void) stop {
    if(!running) return;
    running = false;
    @try{
        [client cancel];
    }
    @catch(id ex){ }
}

- (void) readBuffer:(id)obj {
    while(running){
        @synchronized(self){
            unsigned long bufferLength = [buffer length];
            unsigned long readLength = MAX_BUFFER_SIZE > bufferLength ? bufferLength : MAX_BUFFER_SIZE;
            unsigned long currentLength = bufferLength - readLength;

            if(currentLength < 1) currentLength = 0;
            if(bufferLength == 0) {
                continue;
            }
            NSRange readRange = {0, readLength};
            NSRange currentRange = {readLength, currentLength};

            NSData *read = [buffer subdataWithRange: readRange];
            NSData *current = [buffer subdataWithRange: currentRange];

            bool hasRead = [read length] > 0;


            if(current)
                [buffer setData: current];
            else
                [buffer resetBytesInRange: readRange];

            if(hasRead)
                [stream appendData: read];

            if([self hasData: read])
                [self processBuffer: stream];

            [lastBuffer resetBytesInRange: readRange];

            [lastBuffer replaceBytesInRange: readRange withBytes: [read bytes]];

            if(read)
                [read release];
        }
    }
}

- (bool) hasData:(NSData *)bufferData {
    if(bufferData == nil) return false;
    int count = 0;
    const char *bufferBytes = [bufferData bytes];
    const char *delimeterBytes = [delimeter bytes];
    unsigned long delimeterLength = [delimeter length];
    unsigned long bufferLength = [bufferData length];
    for(int i = 0; i < bufferLength; i++){
        if(bufferBytes[i] == delimeterBytes[i]) count++;
    }
    if(count == bufferLength) return true;
    if(lastBuffer == nil) return false;

    [bigBuffer replaceBytesInRange: NSMakeRange(0, MAX_BUFFER_SIZE) withBytes: [lastBuffer bytes]];
    [bigBuffer replaceBytesInRange: NSMakeRange(MAX_BUFFER_SIZE, MAX_BUFFER_SIZE * 2) withBytes: [bufferData bytes]];


    int delimeterIndex = 0;

    const char *bigBufferBytes = [bigBuffer bytes];
    for(int i = 0; i < [bigBuffer length]; i++){
        if(bigBufferBytes[i] == delimeterBytes[delimeterIndex]){
            if(++delimeterIndex == delimeterLength){
                if(i < MAX_BUFFER_SIZE) return false;
                else return true;
            }
        }else
            delimeterIndex = 0;
    }
    return false;
}

- (void) processBuffer:(NSData *)bufferData {
    NSString *text = [[NSString alloc] initWithData: bufferData encoding: NSUTF8StringEncoding];
    NSTextCheckingResult *result = [cometRegex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    NSString *json = [text substringWithRange: [result rangeAtIndex: 2]];

    #ifdef PSB_UI
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(json);
        });
    #else
        callback(json);
    #endif

    [stream setLength: 0];
}

- (void) onReceived:(PSBOneStringBlock)value {
    self.callback = value;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    @synchronized(self){
        [buffer appendData: data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

}


@end

