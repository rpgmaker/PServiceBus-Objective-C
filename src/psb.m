#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "rest.h"
#import "psb.h"


NSString * const USERNAME_KEY = @"pservicebus_username_info";
NSString * const ESBTOPIC_HEADERS = @"ESBTOPIC_HEADERS";
NSString * const STREAM_URL = @"Stream/?Subscriber=%@&TransportName=%@&BatchSize=%@&Interval=%@&ConnectionID=%@&transport=httpstreaming";

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
				0, @"Format",
				[PSBClient parseAddress: topicName], @"Path",
				nil];
		}
		case Tcp:
		{
			NSArray *tokens = [address componentsSeparatedByString: @":"];
			BOOL useSSL = [tokens count] > 2 &&
			[(NSString *)[tokens objectAtIndex: 2] caseInsensitiveCompare: @"true"] == NSOrderedSame ? YES : NO;
			NSString *ipAddress = (NSString *)[tokens objectAtIndex: 0];
			int port = [(NSString *)[tokens objectAtIndex: 1] intValue];
			return [[NSDictionary alloc] initWithObjectsAndKeys:
				0, @"Format",
				ipAddress, @"IPAddress",
				port, @"Port",
				useSSL, @"UseSSL",
				nil];
		}
		default:
		{
			return nil;
		}
	}
}

+ (void) unSubscribeFromTopic:(NSString *)topicName {

}

+ (void) cleanUp {
	if(!durable){
		NSUserDefaults  *settings = [NSUserDefaults standardUserDefaults];
		[settings removeObjectForKey: USERNAME_KEY];
	}
	NSEnumerator *enumerator = [handlers objectEnumerator];
	id handler;
	while((handler = [enumerator nextObject])){
		//TODO: call stop for handler
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

+ (void) ping:(void (^)(bool success))callback {

}

+ (void) update:(Class)clazz filter:(NSString *)filter caseSensitive:(bool)caseSensitive {

}

+ (void) update:(Class)clazz filter:(NSString *)filter {

}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize caseSensitive:(BOOL)caseSensitive {

}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval batchSize:(int)batchSize {

}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter interval:(long)interval {

}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback filter:(NSString *)filter {

}

+ (void) subscribe:(Class)clazz callback:(PSBMessageBlock)callback {

}

+ (void) unSubscribe:(NSString *)topicName {

}

+ (void) unSubscribeWith:(Class)clazz {

}

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn headers:(NSDictionary *)headers {

}

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID expiresIn:(long)expiresIn {

}

+ (void) publish:(id)message groupID:(NSString *)groupID sequenceID:(long)sequenceID {

}

+ (void) publish:(id)message {

}


+ (void) unRegister:(NSString *)name {
	[PSBClient unRegisterTopic: name];
}

+ (void) unRegisterWith:(Class)clazz {
	[PSBClient unRegisterTopic: NSStringFromClass(clazz)];
}

+ (void) registerTopicWith:(Class)clazz {
	NSString *topicName = NSStringFromClass(clazz);
	[PSBClient _registerTopic: topicName description:topicName contract:nil];
}

+ (void) registerTopic:(NSString *)name description:(NSString *)description {
	[PSBClient _registerTopic: name description:description contract:nil];
}

+ (void) registerTopic:(NSString *)name {
	[PSBClient _registerTopic: name description:nil contract:nil];
}


@end
