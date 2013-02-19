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


- (PSBHttpStreaming *) initWithUrl:(NSString *)value {
    self = [super init];
    if(self){
        self.url = value;
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


@end

