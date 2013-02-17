#import <Foundation/Foundation.h>

typedef void (^PSBOneStringBlock)(NSString * result);

@interface PSBRestOperation : NSOperation {}

@property (nonatomic, copy) PSBOneStringBlock callback;
@property (retain) NSString *methodName;
@property (retain) NSDictionary *value;


- (PSBRestOperation *) initWithRequest:(NSString *)pmethodName value:(NSDictionary *)pvalue callback:(PSBOneStringBlock)pcallback;

@end
