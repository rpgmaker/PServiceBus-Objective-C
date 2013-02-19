#import <Foundation/Foundation.h>
#import "callbackop.h"

extern int const MAX_BUFFER_SIZE;

@interface PSBHttpStreaming : NSObject {}

@property (readonly, nonatomic, copy) PSBOneStringBlock callback;
@property (readonly) bool running;
@property (readonly) NSMutableData *lastBuffer;
@property (readonly) NSMutableData *bigBuffer;

@property (readonly) NSMutableURLRequest *client;
@property (readonly) NSURLResponse *response;

@property (readonly) NSMutableData *buffer;

@property (readonly) NSString *url;

- (PSBHttpStreaming *) initWithUrl:(NSString *)value;

- (void) start;

- (void) stop;

- (void) readBuffer:(NSURLResponse *)response;

- (bool) hasData:(NSData *)buffer;

- (void) processBuffer:(NSData *)buffer;

- (void) onReceived:(PSBOneStringBlock)value;

@end
