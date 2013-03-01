#import <Foundation/Foundation.h>
#import <objc/runtime.h>


typedef void (^PSBOneStringBlock)(NSString * result);

@interface PSBRestOperation : NSOperation {}

@property (nonatomic, copy) PSBOneStringBlock callback;
@property (retain) NSString *methodName;
@property (retain) NSDictionary *value;


- (PSBRestOperation *) initWithRequest:(NSString *)pmethodName value:(NSDictionary *)pvalue callback:(PSBOneStringBlock)pcallback;

@end




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



@interface PSBJSONParser : NSObject {}


+ (id) jsonToObject:(NSString *)json clazz:(Class)clazz;

+ (NSDictionary *) jsonToDictionary:(NSString *)json;

+ (NSString *) toJSONString:(id)obj;

+ (NSData *) toJSONData:(id)obj;

+ (NSDictionary *) objectToDictionary:(id)obj;

+ (id) dictionaryToObject:(NSDictionary *)dict clazz:(Class)clazz;

@end




extern NSString * const USERNAME_KEY;
extern NSString * const ESBTOPIC_HEADERS;
extern NSString * const STREAM_URL;

typedef void (^PSBVoidBlock)(void);

typedef void (^PSBMessageBlock)(id message);

typedef enum {
    MSMQ = 0,
    RabbitMQ = 1,
    Tcp = 2,
	Redis = 6
} TransportType;

@interface PSBClient : NSObject {}

+ (void) disconnect;
+ (void) _registerTopic:(NSString *)name description:(NSString *)description contract:(NSDictionary *)contract;
+ (void) unRegisterTopic:(NSString *)name;
+ (NSString *) parseAddress:(NSString *)topicName;
+ (NSDictionary *) getTransportData:(NSString *)topicName;
+ (void) unSubscribeFromTopic:(NSString *)topicName;
+ (void) cleanUp;

+ (void) onDisconnect:(PSBVoidBlock)value;
+ (void) apikey:(NSString *)value;
+ (void) passcode:(NSString *)value;
+ (void) address:(NSString *)value;
+ (void) transport:(TransportType)value;
+ (void) endpoint:(NSString *)value;
+ (void) durable:(bool)value;
+ (void) throwException:(bool)value;
+ (NSString *) endpoint;
+ (NSString *) username;
+ (bool) throwException;
+ (NSString *) apikey;
+ (NSString *) passcode;

+ (void) ping:(void (^)(bool success))callback;
+ (void) update:(Class)clazz filter:(NSString *)filter caseSensitive:(BOOL)caseSensitive;
+ (void) update:(Class)clazz filter:(NSString *)filter;

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize caseSensitive:(BOOL)caseSensitive;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter;
+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback;

+ (void) unSubscribe:(NSString *)topicName;
+ (void) unSubscribeWith:(Class)clazz;

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn headers:(NSDictionary *)headers;
+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn;
+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID;
+ (void) publish:(id)message;


+ (void) unRegister:(NSString *)name;
+ (void) unRegisterWith:(Class)clazz;
+ (void) registerTopicWith:(Class)clazz;
+ (void) registerTopic:(NSString *)name description:(NSString *)description;
+ (void) registerTopic:(NSString *)name;

@end





@interface PSBPropertyInfo : NSObject {}

@property (retain) Class clazz;
@property (retain) NSString *name;
@property (nonatomic, readwrite) bool primitive;

- (PSBPropertyInfo *) initWith:(objc_property_t)prop;

@end





#ifdef UI_USER_INTERFACE_IDIOM
	#define PSB_UI
#endif

@interface RestHelper : NSObject {
	
}

+ (NSString *) invokeRequest:(NSString *)methodName value:(NSDictionary *)value;
+ (void) invoke:(NSString *)methodName value:(NSDictionary *)value callback:(PSBOneStringBlock)callback;
+ (void) invoke:(NSString *)methodName value:(NSDictionary *)value;

@end



@implementation PSBRestOperation

@synthesize callback, methodName, value;

- (PSBRestOperation *) initWithRequest:(NSString *)pmethodName value:(NSDictionary *)pvalue callback:(PSBOneStringBlock)pcallback {

	self = [super init];

	if(self){
		self.callback = pcallback;
		self.methodName = pmethodName;
		self.value = pvalue;
	}

	return self;
}

- (void) main {
	NSString *result = [RestHelper invokeRequest: methodName value:value];
	if(callback) {
		callback(result);
		[callback release];
	}
	[value release];
}

@end



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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response { }

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    @synchronized(self){
        [buffer appendData: data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error { }

- (void)connectionDidFinishLoading:(NSURLConnection *)connection { }


@end







@implementation PSBJSONParser

+ (id) jsonToObject:(NSString *)json clazz:(Class)clazz {
    NSDictionary *dict = [self jsonToDictionary: json];
    return [self dictionaryToObject: dict clazz: clazz];
}

+ (NSDictionary *) jsonToDictionary:(NSString *)json {
    NSError *error = nil;
    NSData * buffer = [json dataUsingEncoding: NSUTF8StringEncoding];
    return (NSDictionary *)[NSJSONSerialization JSONObjectWithData: buffer options:0 error:&error];
}

+ (NSString *) toJSONString:(id)obj {
    NSData *buffer = [self toJSONData: obj];
    return [[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding] autorelease];
}

+ (NSData *) toJSONData:(id)obj {
    bool isCollection = [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]];
    NSError *error = nil;
    if(!isCollection)
        obj = [self objectToDictionary: obj];
    return [NSJSONSerialization dataWithJSONObject: obj options:0 error:&error];
}



+ (NSDictionary *) objectToDictionary:(id)obj {

    if([obj isKindOfClass: [NSDictionary class]]){
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
        NSDictionary *nDict = (NSDictionary *)obj;
        NSEnumerator *enumerator = [nDict keyEnumerator];
        id itemKey;

        while((itemKey = [enumerator nextObject])){
            id item = [nDict objectForKey: itemKey];
            Class itemClass = [item class];
            bool isPrimitive = itemClass == [NSString class] ||
                itemClass == [NSNumber class];
            if(isPrimitive) [mDict setObject:item forKey:itemKey];
            else {
                [mDict setObject:[self objectToDictionary: item] forKey:itemKey];
            }
        }

        return [NSDictionary dictionaryWithDictionary:mDict];
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);

    for (int i = 0; i < count; i++) {

        objc_property_t prop = properties[i];

        if(prop == NULL) continue;

        PSBPropertyInfo *propInfo = [[[PSBPropertyInfo alloc] initWith: prop] autorelease];

        NSString *key = propInfo.name;

        id value = [obj valueForKey:key];

        if(value == nil) continue;

        if (!propInfo.primitive)
            value = [self objectToDictionary: value];
        else {
            if([value isKindOfClass: [NSDictionary class]])
                value = [self objectToDictionary: (NSDictionary *)value];
        }

        [dict setObject:value forKey:key];
    }

    free(properties);

    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (id) dictionaryToObject:(NSDictionary *)dict clazz:(Class)clazz {
    id obj = [[clazz alloc] init];

    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);

    for (int i = 0; i < count; i++) {

        objc_property_t prop = properties[i];

        if(prop == NULL) continue;

        PSBPropertyInfo *propInfo = [[PSBPropertyInfo alloc] initWith: prop];

        NSString *key = propInfo.name;

        id value = [dict valueForKey: key];

        if(value == nil) continue;

        if(!propInfo.primitive){
            NSDictionary *nDict = (NSDictionary *)value;
            value = [self dictionaryToObject:nDict clazz: propInfo.clazz];
        }

        [obj setValue:value forKey:key];
    }
    return [obj autorelease];
}

@end









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




@implementation PSBPropertyInfo

@synthesize clazz, name, primitive;

- (PSBPropertyInfo *) initWith:(objc_property_t)prop {
    self = [super init];
    if(self){
        NSString *key = [NSString stringWithUTF8String:property_getName(prop)];
        NSArray *keyTokens = [key componentsSeparatedByString: [NSString stringWithFormat: @"set%@", [[key substringToIndex: 1] uppercaseString]]];
        key = (NSString *)[keyTokens objectAtIndex: 0];

        const char *attribute = property_getAttributes(prop);

        NSString *propClassStr = [NSString stringWithCString:attribute encoding:NSASCIIStringEncoding];
        NSArray *tokens = [propClassStr componentsSeparatedByString: @"\""];

        NSString *className = (NSString *)[tokens objectAtIndex: 1];

        Class propClass = NSClassFromString(className);

        self.primitive =
            propClass == [NSString class] ||
            propClass == [NSNumber class] ||
            propClass == [NSDictionary class] ||
            propClass == [NSArray class];

        self.name = key;
        self.clazz = propClass;
    }
    return self;
}

@end






@implementation RestHelper

static NSOperationQueue *restQueue = nil;

+ (void) initialize {
	if(restQueue != nil) return;
	restQueue = [[NSOperationQueue alloc] init];
	restQueue.name = @"PSB REST API";
}

+ (NSString *) invokeRequest:(NSString *)methodName value:(NSDictionary *)value {

	NSMutableData *data = [[[NSMutableData alloc] init] autorelease];
	NSURLResponse *response = nil;
	NSError *error = nil;

	NSString *urlStr = [NSString stringWithFormat:@"%@%@?ReThrowException=%@&ESBUserName=%@&ESBPassword=%@&ConnectionID=%@",
		[PSBClient endpoint], methodName, [NSNumber numberWithBool: ([PSBClient throwException] ? YES : NO)],
		[PSBClient apikey], [PSBClient passcode], [PSBClient username]];

	NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];

    NSData *buffer = [PSBJSONParser toJSONData: value];

	[request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: buffer];

	[data appendData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];

	if(error) @throw error;

	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

+ (void) invoke: (NSString *)methodName value:(NSDictionary *)value callback:(PSBOneStringBlock)callback {
	#ifdef PSB_UI
		PSBRestOperation *op = [[[PSBRestOperation alloc] initWithRequest:methodName value:value callback:callback] autorelease];
		[restQueue addOperation : op];
	#else
		NSString *result = [self invokeRequest: methodName value: value];
		if(callback) callback(result);
		[value release];
	#endif
}

+ (void) invoke: (NSString *)methodName value:(NSDictionary *)value {
	[RestHelper invoke: methodName value:value callback: ^(NSString * _) {}];
}

@end





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

