#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "psb.h"

@interface ChatTopic : NSObject {}

@property (retain) NSString *UserName;
@property (retain) NSString *Message;

- (id) initWith:(NSString *)username message:(NSString *)message;

@end

@implementation ChatTopic

@synthesize UserName, Message;

- (id) initWith:(NSString *)username message:(NSString *)message {
    if(self = [super init]){
        self.UserName = username;
        self.Message = message;
    }
    return self;
}

@end

int main (int argc, const char * argv[])
{
	@autoreleasepool {

	    [PSBClient endpoint: @"http://192.168.56.1:8087/ESB"];

	    [PSBClient address: @"endpoint://guest:guest@192.168.56.1:5672/"];

		ChatTopic *chat = [[ChatTopic alloc] initWith: @"Objective-C" message: @"Hello world"];

        NSLog(@"Type a message to publish. Type exit to close program...");

        [PSBClient subscribe: [ChatTopic class] callback: ^(ChatTopic *msg) {
            NSLog(@"%@: %@", msg.UserName, msg.Message);
        }];

        char word[1024];
        while(true){
            scanf("%s", word);
            NSString *text = [[NSString alloc] initWithCString:word encoding:NSUTF8StringEncoding];
            if([text isEqualToString: @"exit"]) break;
            chat.Message = text;
            [PSBClient publish: chat];
        }
	}

	return 0;
}
