#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "psb.h"
#import "objectparser.h"
#import "httpstreaming.h"

@interface TestObject : NSObject {}

@property (retain) NSString *setting;

@end

@implementation TestObject

@synthesize setting;

@end

struct BlockDescriptor {
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct Block {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct BlockDescriptor *descriptor;
};

static const char *BlockSig(id blockObj)
{
    struct Block *block = (void *)blockObj;
    struct BlockDescriptor *descriptor = block->descriptor;

    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;

    assert(block->flags & signatureFlag);

    int index = 0;
    if(block->flags & copyDisposeFlag)
        index += 2;

    return descriptor->rest[index];
}

int main (int argc, const char * argv[])
{
	@autoreleasepool {
		NSDictionary *value = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"ChatTopic", @"name",
			nil];

		TestObject *obj = [[TestObject alloc] init];
		obj.setting = @"Testing";

		//NSString *name =  NSStringFromClass([obj class]);

		//NSLog(@"%@", name);

		//[RestHelper invoke: @"SelectTopic" value:value callback: ^(NSString * result) {
		//	NSLog(@"%@", result);
		//}];

		NSString *json = [PSBJSONParser toJSONString: obj];

		NSLog(@"%@", json);
		TestObject *obj2 = (TestObject *)[PSBJSONParser jsonToObject: json clazz: [TestObject class]];
		NSLog(@"%@", obj2.setting);


        void (^block)(TestObject *) = ^(TestObject *o) {
            NSLog(@"%@ %@", NSStringFromClass([o class]), o);

        };
        NSLog(@"signature %s", BlockSig(block));
        block(obj2);

        PSBHttpStreaming *http = [[PSBHttpStreaming alloc] initWithUrl: @"http://yahoo.com"];
        [http start];

        //getch();

		//NSLog(@"%@", [NSString stringWithCString:@encode(TestObject) encoding:NSASCIIStringEncoding]);
	}

	return 0;
}
