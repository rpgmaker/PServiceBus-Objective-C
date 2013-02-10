#import <Foundation/Foundation.h>

typedef void (^OneStringBlock)(NSString * result);

@interface PSBRestOperation : NSOperation {
	OneStringBlock callback;
	NSString *methodName;
	NSDictionary *value;
}

@property (nonatomic, copy) OneStringBlock callback;
@property (retain) NSString *methodName;
@property (retain) NSDictionary *value;

- (PSBRestOperation *) initWithRequest:(NSString *)pmethodName value:(NSDictionary *)pvalue callback:(OneStringBlock)pcallback;

@end