#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "rest.h"
#import "psb.h"
#import "objectparser.h"
#import "httpstreaming.h"


NSString * const USERNAME_KEY = @"pservicebus_username_info";
NSString * const ESBTOPIC_HEADERS = @"ESBTOPIC_HEADERS";
NSString * const STREAM_URL = @"Stream/?Subscriber=%@&TransportName=%@&BatchSize=%d&Interval=%ld&ConnectionID=%@&transport=httpstreaming&durable=%@";

@implementation PSBClient


static NSString *username = nil;
static NSString *apikey = nil;
static bool durable = false;
static bool throwException = false;
static NSString *passcode = nil;
static NSString *address = nil;
static NSMutableDictionary *handlers = nil;
static NSMutableDictionary *topics = nil;
static TransportType transport;
static PSBVoidBlock onDisconnect = nil;

static NSString *endpoint;

+ (void) initialize {
	apikey = @"demo";
	passcode = @"demo";
	endpoint = @"http://localhost:8087/esb/";
	address = @"endpoint://guest:guest@localhost:5672/";
	transport = RabbitMQ;
	handlers = [[NSMutableDictionary alloc] init];
	topics = [[[NSMutableDictionary alloc] init] autorelease];
}


+ (void) disconnect {
	NSString *username = [PSBClient username];
	void (^action)(NSString *) = ^(NSString *name) {
		[RestHelper invoke: @"Disconnect" value:
			[[NSDictionary alloc] initWithObjectsAndKeys:
				name, @"name",
			nil]];
	};
	[PSBClient cleanUp];
	if(!durable){
		[RestHelper invoke: @"DeleteSubscriber" value:
			[[NSDictionary alloc] initWithObjectsAndKeys:
				username, @"name",
			nil] callback: ^(NSString * _) {
				action(username);
			}];
	}else {
		action(username);
	}
}

+ (void) _registerTopic:(NSString *)name description:(NSString *)description contract:(NSDictionary *)contract {
	if(name == nil) [NSException raise: @"name" format: @"name cannot be nil"];
	if([topics objectForKey: name] != nil) return;
	if(contract == nil) contract = [[NSDictionary alloc] init];
	if(description == nil) description = [[NSString alloc] initWithString: name];
	[RestHelper invoke: @"Disconnect" value:
		[[NSDictionary alloc] initWithObjectsAndKeys:
			contract, @"Contract",
			name, @"Name",
			description, @"Description",
		nil]];
	[topics setValue: name forKey:name];
}

+ (void) unRegisterTopic:(NSString *)name {
	if(name == nil) [NSException raise: @"name" format: @"name cannot be nil"];
	[RestHelper invoke: @"Disconnect" value:
		[[NSDictionary alloc] initWithObjectsAndKeys:
			name, @"name",
		nil]];
	[topics removeObjectForKey: name];
}

+ (NSString *) parseAddress:(NSString *)topicName {
	return [NSString stringWithFormat:@"%@%@%@", address, topicName, username];
}

+ (NSDictionary *) getTransportData:(NSString *)topicName {
	switch(transport) {
		case MSMQ:
		case RabbitMQ:
		case Redis:
		{
			return [[NSDictionary alloc] initWithObjectsAndKeys:
                [NSNumber numberWithInt: 0], @"Format",
				[PSBClient parseAddress: topicName], @"Path",
				nil];
		}
		case Tcp:
		{
			NSArray *tokens = [address componentsSeparatedByString: @":"];
			BOOL useSSL = [tokens count] > 2 &&
			[(NSString *)[tokens objectAtIndex: 2] caseInsensitiveCompare: @"true"] == NSOrderedSame;
			NSString *ipAddress = (NSString *)[tokens objectAtIndex: 0];
			int port = [(NSString *)[tokens objectAtIndex: 1] intValue];
			return [[NSDictionary alloc] initWithObjectsAndKeys:
                [NSNumber numberWithInt: 0], @"Format",
				ipAddress, @"IPAddress",
				port, @"Port",
				[NSNumber numberWithBool: useSSL], @"UseSSL",
				nil];
		}
		default:
		{
			return nil;
		}
	}
}

+ (void) unSubscribeFromTopic:(NSString *)topicName {
    if(topicName == nil) [NSException raise: @"topicName" format: @"topicName cannot be nil"];
    PSBHttpStreaming *handler;
    [RestHelper invoke: @"Disconnect" value:
		[[NSDictionary alloc] initWithObjectsAndKeys:
			[self username], @"Subscriber",
			topicName, @"Topic",
			[[NSDictionary alloc] initWithObjectsAndKeys:
                topicName, @"Name",
                nil], @"Transport",
		nil]];
    if((handler = (PSBHttpStreaming *)[handlers objectForKey: topicName]) != nil){
        [handlers removeObjectForKey: topicName];
        [handler stop];
        [handler release];
    }
}

+ (void) cleanUp {
	if(!durable){
		NSUserDefaults  *settings = [NSUserDefaults standardUserDefaults];
		[settings removeObjectForKey: USERNAME_KEY];
	}
	NSEnumerator *enumerator = [handlers objectEnumerator];
	PSBHttpStreaming *handler;
	while((handler = (PSBHttpStreaming *)[enumerator nextObject])){
		if(handler)
            [handler stop];
	}
	if(onDisconnect) onDisconnect();
	[handlers release];
}

+ (void) onDisconnect:(PSBVoidBlock)value { onDisconnect = value; }

+ (void) apikey:(NSString *)value { apikey = value; }

+ (void) passcode:(NSString *)value { passcode = value; }

+ (void) address:(NSString *)value { address = value; }

+ (void) transport:(TransportType)value { transport = value; }

+ (void) endpoint:(NSString *)value { endpoint = value; }

+ (void) durable:(bool)value { durable = value; }

+ (void) throwException:(bool)value { throwException = value; }

+ (NSString *) endpoint {
	return [NSString stringWithFormat:@"%@%@", endpoint, [endpoint hasSuffix: @"/"] ? @"" : @"/"];
}

+ (NSString *) username {
	if(username) return username;
	NSUserDefaults  *settings = [NSUserDefaults standardUserDefaults];
	username = [settings stringForKey: USERNAME_KEY];
	if(username) durable = false;
	if(username == nil) {
		NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
		username = [NSString stringWithFormat: @"iOS%@", uuid];
	}
	if(durable)
		[settings setObject: username forKey: USERNAME_KEY];

	return username;
}

+ (bool) throwException { return throwException; }

+ (NSString *) apikey { return apikey; }
+ (NSString *) passcode { return passcode; }

+ (void) ping:(void (^)(bool))callback {
    if(!callback) [NSException raise: @"callback" format: @"callback cannot be nil"];
    [RestHelper invoke: @"Ping" value: [[NSDictionary alloc] init]
    callback: ^(NSString *result){
        bool success = [result caseInsensitiveCompare: @"true"] == NSOrderedSame;
        callback(success);
    }];
}

+ (void) update:(Class)clazz filter:(NSString *)filter caseSensitive:(BOOL)caseSensitive {
    NSString *topicName = NSStringFromClass(clazz);
    NSNumber *needHeader = [NSNumber numberWithBool: NO];

    [self registerTopic: topicName];

    [RestHelper invoke: @"Update" value:
		[[NSDictionary alloc] initWithObjectsAndKeys:
			[self username], @"Subscriber",
			topicName, @"Topic",
			filter, @"Filter",
			[NSNumber numberWithBool: caseSensitive], @"CaseSensitive",
			needHeader, @"NeedHeader",
		nil]];
}

+ (void) update:(Class)clazz filter:(NSString *)filter {
    [self update: clazz filter:filter caseSensitive: YES];
}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize caseSensitive:(BOOL)caseSensitive {
    if(!callback) [NSException raise: @"callback" format: @"callback cannot be nil"];
    filter = filter == nil ? @"" : filter;
    interval = interval <= 0 ? 5 : interval;

    NSString *topicName = NSStringFromClass(clazz);
    NSNumber *needHeader = [NSNumber numberWithBool: NO];

    [self registerTopic: topicName];

    [RestHelper invoke: @"Subscribe" value:
		[[NSDictionary alloc] initWithObjectsAndKeys:
			[self username], @"Subscriber",
			topicName, @"Topic",
			filter, @"Filter",
			[NSNumber numberWithBool: caseSensitive], @"CaseSensitive",
			needHeader, @"NeedHeader",
			[[NSDictionary alloc] initWithObjectsAndKeys:
                topicName, @"Name",
                [self getTransportData: topicName], @"Parameters",
                [NSNumber numberWithInt: (int)transport], @"TypeID",
                nil], @"Transport",
            nil]
            callback: ^(NSString *result){
                NSString *url = [NSString stringWithFormat: @"%@%@", [self endpoint],
                    [NSString stringWithFormat: STREAM_URL, [self username],
                        topicName, batchSize, interval, [self username], (durable ? @"true" : @"false")]
                ];
                PSBHttpStreaming *handler = [[PSBHttpStreaming alloc] initWithUrl: url];
                [handler onReceived: ^(NSString *json) {
                    id obj = [PSBJSONParser jsonToObject: json clazz: clazz];
                    callback(obj);
                }];
                [handler start];
                [handlers setValue: handler forKey: topicName];
            }];
}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize {
    [self subscribe: clazz callback:callback filter:filter interval:interval batchSize:batchSize caseSensitive: YES];
}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval {
    [self subscribe: clazz callback:callback filter:filter interval:interval batchSize:1];
}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter {
    [self subscribe: clazz callback:callback filter:filter interval:5];
}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback {
    [self subscribe: clazz callback:callback filter:@""];
}

+ (void) unSubscribe:(NSString *)topicName {
    [self unSubscribeFromTopic: topicName];
}

+ (void) unSubscribeWith:(Class)clazz {
    NSString *topicName = NSStringFromClass(clazz);
    [self unSubscribeFromTopic: topicName];
}

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn headers:(NSDictionary *)headers {
    Class clazz = [message class];
    NSString *topicName = NSStringFromClass(clazz);
    expiresIn = expiresIn <= 0 ? 1000 * 60 * 30 : expiresIn;
    NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
    if(headers) [headerDict addEntriesFromDictionary: headers];

    if(groupID && sequenceID > 0){
        [headerDict setValue: groupID forKey: @"ESB_GROUP_ID"];
        [headerDict setValue: [NSString stringWithFormat: @"%ld", sequenceID] forKey: @"ESB_SEQUENCE_ID"];
    }

    if(clazz != [NSArray class]) {
        message = [[NSArray alloc] initWithObjects:
            [PSBJSONParser objectToDictionary: message], nil];
    }else {
        NSArray *arry = (NSArray *)message;
        id item = [arry objectAtIndex: 0];
        clazz = [item class];
        topicName = NSStringFromClass(clazz);

        NSMutableArray *items = [NSMutableArray arrayWithCapacity: [arry count]];
        NSEnumerator *enumerator = [arry objectEnumerator];

        while(item = [enumerator nextObject]){
            [items addObject: [PSBJSONParser objectToDictionary: item]];
        }

        message = items;
    }

    [self registerTopic: topicName];

    [RestHelper invoke: @"PublishTopic" value:
		[[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithLong: expiresIn], @"ExpiresIn",
			topicName, @"Topic",
			[NSDictionary dictionaryWithDictionary: headerDict], @"Headers",
			message, @"Messages",
		nil]];
}

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn {
    [self publish: message groupID:groupID sequenceID:sequenceID expiresIn:expiresIn headers:nil];
}

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID {
    [self publish: message groupID:groupID sequenceID:sequenceID expiresIn: 0];
}

+ (void) publish:(id)message {
    [self publish: message groupID:nil sequenceID:0];
}


+ (void) unRegister:(NSString *)name {
	[self unRegisterTopic: name];
}

+ (void) unRegisterWith:(Class)clazz {
	[self unRegisterTopic: NSStringFromClass(clazz)];
}

+ (void) registerTopicWith:(Class)clazz {
	NSString *topicName = NSStringFromClass(clazz);
	[self _registerTopic: topicName description:topicName contract:nil];
}

+ (void) registerTopic:(NSString *)name description:(NSString *)description {
	[self _registerTopic: name description:description contract:nil];
}

+ (void) registerTopic:(NSString *)name {
	[self _registerTopic: name description:nil contract:nil];
}


@end
