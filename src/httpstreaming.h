#import <Foundation/Foundation.h>
#import "callbackop.h"

extern int const MAX_BUFFER_SIZE;

@interface PSBHttpStreaming : NSObject {}

@property (readonly, nonatomic, copy) PSBOneStringBlock callback;
@property (readonly) bool running;
@property (readonly) NSMutableData *lastBuffer;
@property (readonly) NSMutableData *bigBuffer;

@property (readonly) NSURLConnection *client;
@property (readonly) NSMutableURLRequest *request;
@property (readonly) NSURLResponse *response;

@property (readonly) NSMutableData *buffer;
@property (readonly) NSMutableData *stream;

@property (readonly) NSString *url;

- (PSBHttpStreaming *) initWithUrl:(NSString *)value;

- (void) start;

- (void) stop;

- (void) readBuffer:(id)obj;

- (bool) hasData:(NSData *)bufferData;

- (void) processBuffer:(NSData *)bufferData;

- (void) onReceived:(PSBOneStringBlock)value;

@end
