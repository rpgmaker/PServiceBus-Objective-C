#import "psb.h"

NSString * const USERNAME_KEY = @"pservicebus_username_info";
NSString * const ESBTOPIC_HEADERS = @"ESBTOPIC_HEADERS";
NSString * const STREAM_URL = @"Stream/?Subscriber={0}&TransportName={1}&BatchSize={2}&Interval={3}&ConnectionID={4}&transport=httpstreaming";

@implementation PSBClient


static NSString * username = nil;
static NSString * apikey = nil;
static NSString * passcode = nil;
static NSString * address = nil; 


@end
