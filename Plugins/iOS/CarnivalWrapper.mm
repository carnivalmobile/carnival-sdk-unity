#import "CarnivalWrapper.h"
#import <Foundation/Foundation.h>

@interface CarnivalMessage ()

- (nullable instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary;
- (nonnull NSDictionary *)dictionary;

@end

@interface Carnival ()
+ (void)setWrapperName:(NSString *)wrapperName andVersion:(NSString *)wrapperVersion;
@end

@interface CarnivalWrapper ()
/*
 * We need to hold these blocks to make sure they are not released 
 * by ARC before they're executed and the scope variable are destroyed. 
 * Seems to be unique to the Unity runtime and Objective-C++.
 */
@property (nonatomic, copy) void (^stringAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^booleanAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^floatAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^integerAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^dateAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^unsetAttributeBlock)(NSError *error);
@property (nonatomic, copy) void (^userIDBlock)(NSError *error);
@property (nonatomic, copy) void (^userEmailBlock)(NSError *error);
@property (nonatomic, copy) void (^messagesBlock)(NSArray *messages, NSError *error);
@property (nonatomic, copy) void (^markAsReadBlock)(NSError *error);
@property (nonatomic, copy) void (^removeMessageBlock)(NSError *error);
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, copy) void (^deviceIDBlock)(NSString *deviceID, NSError *error);
@property (nonatomic, copy) void (^unreadCountBlock)(NSUInteger unreadCount, NSError *error);

@property (nonatomic, strong) UINavigationController *navVC;
@end
@implementation CarnivalWrapper

# pragma mark - C Methods

# pragma mark Init

/*
 * Use of carnivalInstance is to effectively call self inside C++ methods, which you can't do.
 */
void initCarnival () {
    if (!carnivalInstance) {
        [[CarnivalWrapper alloc] init];
    }
}

# pragma mark Engine

void _startEngine(char *apiKey) {
    [Carnival startEngine:[NSString stringWithUTF8String:apiKey]];
    [Carnival setWrapperName:@"Unity" andVersion:@"1.0.0"];
}
# pragma mark Message Detail

void _showMessageDetail(char *messageJSON) {
    initCarnival();
    CarnivalMessage *message = [carnivalInstance messageFromJSON:[NSString stringWithUTF8String:messageJSON]];
    [CarnivalMessageStream presentMessageDetailForMessage:message];
}

void _dismissMessageDetail() {
    [CarnivalMessageStream dismissMessageDetail];
}

# pragma mark Location

void _updateLocation(double lat, double lon) {
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    [Carnival updateLocation:loc];
}

# pragma mark Custom Events

void _logEvent(const char *event) {
    [Carnival logEvent:[NSString stringWithUTF8String:event]];
}

# pragma mark Custom Attributes

void _setString(const char *string, const char *key) {
    initCarnival();
    [carnivalInstance setString:[NSString stringWithUTF8String:string] forKey:[NSString stringWithUTF8String:key]];
}

void _setBool(bool boolValue, const char *key) {
    initCarnival();
    [carnivalInstance setBoolean:boolValue forKey:[NSString stringWithUTF8String:key]];
}

void _setDate(int64_t secondsSince1970, const char *key) {
    initCarnival();
    [carnivalInstance setDate:[NSDate dateWithTimeIntervalSince1970:secondsSince1970] forKey:[NSString stringWithUTF8String:key]];
}

void _setFloat(float floatValue, const char *key) {
    initCarnival();
    [carnivalInstance setFloat:floatValue forKey:[NSString stringWithUTF8String:key]];
}

void _setInteger(int intValue, const char *key) {
    initCarnival();
    [carnivalInstance setInteger:intValue forKey:[NSString stringWithUTF8String:key]];
}

void _removeAttribute(const char *key) {
    initCarnival();
    [carnivalInstance unsetValueForKey:[NSString stringWithUTF8String:key]];
}

# pragma mark - In App Notifications

void _setInAppNotificationsEnabled(bool enabled) {
    [Carnival setInAppNotificationsEnabled:enabled];
}

#pragma mark - User ID

void _setUserID(const char *userID) {
    initCarnival();
    [carnivalInstance setUserID:[NSString stringWithUTF8String:userID]];
}

void _setUserEmail(const char *userEmail) {
    initCarnival();
    [carnivalInstance setUserID:[NSString stringWithUTF8String:userEmail]];
}

void _messages () {
    initCarnival();
    [carnivalInstance sendMessages];
}

void _markMessageAsRead(char *messageJSON) {
    CarnivalMessage *message = [carnivalInstance messageFromJSON:[NSString stringWithUTF8String:messageJSON]];
    [carnivalInstance markMessageAsRead:message];
}

void _removeMessage(const char *messageJSON) {
    [carnivalInstance removeMessage:[carnivalInstance messageFromJSON:[NSString stringWithUTF8String:messageJSON]]];
}

void _registerImpression(const char *messageJSON, int impressionType) {
    CarnivalMessage *message = [carnivalInstance messageFromJSON:[NSString stringWithUTF8String:messageJSON]];
    if (impressionType == 0) {
        [CarnivalMessageStream registerImpressionWithType:CarnivalImpressionTypeInAppNotificationView forMessage:message];
    } else if (impressionType == 1) {
         [CarnivalMessageStream registerImpressionWithType:CarnivalImpressionTypeStreamView forMessage:message];
    } else if (impressionType == 2){
        [CarnivalMessageStream registerImpressionWithType:CarnivalImpressionTypeDetailView forMessage:message];
    } else {
        NSLog(@"Impression type not supported");
    }
}

#pragma mark Device ID 

void _deviceID() {
    initCarnival();
    [carnivalInstance deviceID];
}

# pragma mark - Unread Count

void _unreadCount() {
    initCarnival();
    [carnivalInstance unreadCount];
}

# pragma mark - Obj-C Methods

# pragma mark Init

- (id) init {
    self = [super init];
    if (self) {
        carnivalInstance = self;
    }
    return self;
}

# pragma mark Custom Attributes

- (void)setString:(NSString *)value forKey:(NSString *)key {
    self.stringAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    CarnivalAttributes *attributes = [[CarnivalAttributes alloc] init];
    [attributes setString:value forKey:key];
    [Carnival setAttributes:attributes withResponse:self.stringAttributeSetBlock];
}

- (void)setBoolean:(BOOL)value forKey:(NSString *)key {
    self.booleanAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    CarnivalAttributes *attributes = [[CarnivalAttributes alloc] init];
    [attributes setBool:value forKey:key];
    [Carnival setAttributes:attributes withResponse:self.booleanAttributeSetBlock];
}

- (void)setDate:(NSDate *)value forKey:(NSString *)key {
    self.dateAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    
    CarnivalAttributes *attributes = [[CarnivalAttributes alloc] init];
    [attributes setDate:value forKey:key];
    [Carnival setAttributes:attributes withResponse:self.dateAttributeSetBlock];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    self.integerAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    CarnivalAttributes *attributes = [[CarnivalAttributes alloc] init];
    [attributes setInteger:value forKey:key];
    [Carnival setAttributes:attributes withResponse:self.integerAttributeSetBlock];
}

- (void)setFloat:(CGFloat)value forKey:(NSString *)key {
    self.floatAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    CarnivalAttributes *attributes = [[CarnivalAttributes alloc] init];
    [attributes setFloat:value forKey:key];
    [Carnival setAttributes:attributes withResponse:self.floatAttributeSetBlock];
}

- (void)unsetValueForKey:(NSString *)key {
    self.unsetAttributeBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    [Carnival removeAttributeWithKey:key withResponse:self.unsetAttributeBlock];
}

#pragma mark - User ID

-(void)setUserID:(NSString *)userID {
    self.userIDBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    [Carnival setUserId:userID withResponse:self.userIDBlock];
}

-(void)setUserEmail:(NSString *)userEmail {
    self.userEmailBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    [Carnival setUserEmail:userEmail withResponse:self.userEmailBlock];
}


#pragma mark - Messages
- (void)sendMessages {
    __weak __typeof__(self) weakSelf = self;
    self.messagesBlock = ^(NSArray *messages, NSError *error) {
        __weak __typeof__(self) strongSelf = weakSelf;
        if (strongSelf) {
            if (error) {
                UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
            } else {
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[strongSelf arrayOfMessageDictionariesFromMessageArray:messages] options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                UnitySendMessage("Carnival", "ReceiveMessagesJSONData", [jsonString UTF8String]);
            }
        }
    };
    
    [CarnivalMessageStream messages:self.messagesBlock];
}

- (void)markMessageAsRead:(CarnivalMessage *)message {
    self.markAsReadBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    [CarnivalMessageStream markMessageAsRead:message withResponse:self.markAsReadBlock];
}

- (void)removeMessage:(CarnivalMessage *)message {
    self.removeMessageBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
    };
    [CarnivalMessageStream removeMessage:message withResponse:self.removeMessageBlock];
}

#pragma mark - Helper Methods

- (NSArray *)arrayOfMessageDictionariesFromMessageArray:(NSArray *)messageArray {
    NSMutableArray *messageDictionaries = [NSMutableArray array];
    for (CarnivalMessage *message in messageArray) {
        [messageDictionaries addObject:[message dictionary]];
    }
    return messageDictionaries;
}

- (CarnivalMessage *)messageFromJSON:(NSString *)JSONString {
    NSData *data = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *deserializeError = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&deserializeError];
    
    if (!deserializeError) {
        return [[CarnivalMessage alloc] initWithDictionary:dict];
    }
    return nil;
}

#pragma mark Device ID

- (void)deviceID {
    self.deviceIDBlock = ^(NSString *deviceID, NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        } else {
            UnitySendMessage("Carnival", "ReceiveDeviceID", [deviceID UTF8String]);
        }
    };
    
    [Carnival deviceID:self.deviceIDBlock];
}

#pragma mark  Unread Counts

- (void)unreadCount {
    self.unreadCountBlock = ^(NSUInteger unreadCount, NSError *error) {
        if (error) {
            UnitySendMessage("Carnival", "ReceiveError", [[error localizedDescription] UTF8String]);
        }
        UnitySendMessage("Carnival", "ReceiveUnreadCount", [[NSString stringWithFormat:@"%d", unreadCount] UTF8String]);
    };
    [CarnivalMessageStream unreadCount:self.unreadCountBlock];
}

@end
