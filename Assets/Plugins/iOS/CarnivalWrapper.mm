#import "CarnivalWrapper.h"
#import <Foundation/Foundation.h>

@interface CarnivalWrapper ()
@property (nonatomic, copy) void (^tagReturnBlock)(NSArray *tags, NSError *error);
@property (nonatomic, copy) void (^tagSetBlock)(NSArray *tags, NSError *error);
@property (nonatomic, copy) void (^stringAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^booleanAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^floatAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^integerAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^dateAttributeSetBlock)(NSError *error);
@property (nonatomic, copy) void (^unsetAttributeBlock)(NSError *error);

@property (nonatomic, strong) UINavigationController *navVC;
@end
@implementation CarnivalWrapper

- (id) init {
    self = [super init];
    if (self) {
        carnivalInstance = self;
    }
    return self;
}

//C Methods

void initCarnival () {
    if (!carnivalInstance) {
        [[CarnivalWrapper alloc] init];
    }
}
void _startEngine(char *apiKey) {
    printf("We got here\n:");
    [Carnival startEngine:[NSString stringWithUTF8String:apiKey]];
}

void _setTags(char *tagString, const char *GameObjectName,const char *TagCallback,const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance setTags:[[NSString stringWithUTF8String:tagString] componentsSeparatedByString:@","] withGameObject:[NSString stringWithUTF8String:GameObjectName] andTagsCallback:[NSString stringWithUTF8String:TagCallback] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
    
}

void _getTags(const char *GameObjectName,const char *TagCallback,const char *ErrorCallback) {
    initCarnival();

    [carnivalInstance getTagsAndCallback:[NSString stringWithUTF8String:GameObjectName]
                        andTagsCallback:[NSString stringWithUTF8String:TagCallback]
                        andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}

void _showMessageStream() {
    initCarnival();

    [carnivalInstance showMesssageStream];
}

void _updateLocation(double lat, double lon) {
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    [Carnival updateLocation:loc];
}

void _logEvent(const char *event) {
    [Carnival logEvent:[NSString stringWithUTF8String:event]];
}

void _setString(const char *string, const char *key, const char *GameObjectName, const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance setString:[NSString stringWithUTF8String:string] forKey:[NSString stringWithUTF8String:key] withGameObject:[NSString stringWithUTF8String:GameObjectName] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}

void _setBool(bool boolValue, const char *key, const char *GameObjectName, const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance setBoolean:boolValue forKey:[NSString stringWithUTF8String:key] withGameObject:[NSString stringWithUTF8String:GameObjectName] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}

void _setDate(int64_t secondsSince1970, const char *key, const char *GameObjectName,  const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance setDate:[NSDate dateWithTimeIntervalSince1970:secondsSince1970] forKey:[NSString stringWithUTF8String:key] withGameObject:[NSString stringWithUTF8String:GameObjectName] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}
void _setFloat(double floatValue, const char *key, const char *GameObjectName,  const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance setFloat:floatValue forKey:[NSString stringWithUTF8String:key] withGameObject:[NSString stringWithUTF8String:GameObjectName] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}
void _setInteger(int64_t intValue, const char *key, const char *GameObjectName, const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance setInteger:intValue forKey:[NSString stringWithUTF8String:key] withGameObject:[NSString stringWithUTF8String:GameObjectName] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}
void _removeAttribute(const char *key, const char *GameObjectName, const char *ErrorCallback) {
    initCarnival();
    [carnivalInstance unsetValueForKey:[NSString stringWithUTF8String:key] withGameObject:[NSString stringWithUTF8String:GameObjectName] andErrorCallback:[NSString stringWithUTF8String:ErrorCallback]];
}



//Obj-C Methods
# pragma mark - Tags
- (void)getTagsAndCallback:(NSString *)gameObjectName andTagsCallback:(NSString *)tagCallback andErrorCallback:(NSString *)errorCallback {
    self.tagReturnBlock = ^(NSArray *tags, NSError *error) {
        if (tags) {
            UnitySendMessage([gameObjectName UTF8String], [tagCallback UTF8String], [[tags componentsJoinedByString:@","] UTF8String]);
        }
        if (error) {
            UnitySendMessage([gameObjectName UTF8String], [errorCallback UTF8String], [[error localizedDescription] UTF8String]);
        }
    };
    
    [Carnival getTagsInBackgroundWithResponse:self.tagReturnBlock];
}

- (void)setTags:(NSArray *)tags withGameObject:(NSString *)gameObjectName andTagsCallback:(NSString *)tagCallback andErrorCallback:(NSString *)errorCallback {
    self.tagSetBlock = ^(NSArray *tags, NSError *error) {
        if (tags) {
            UnitySendMessage([gameObjectName UTF8String], [tagCallback UTF8String], [[tags componentsJoinedByString:@","] UTF8String]);
        }
        if (error) {
            UnitySendMessage([gameObjectName UTF8String], [errorCallback UTF8String], [[error localizedDescription] UTF8String]);
        }
    };
    
    [Carnival setTagsInBackground:tags withResponse:self.tagSetBlock];
}

# pragma mark - Stream

- (void)showMesssageStream {
    CarnivalStreamViewController *streamVC = [[CarnivalStreamViewController alloc] init];
    self.navVC = [[UINavigationController alloc] initWithRootViewController:streamVC];
    
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CarnivalResources.bundle/cp_close_button.png"]  style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonPressed:)];
    
    [closeItem setTintColor:[UIColor blackColor]];
    
    [streamVC.navigationItem setRightBarButtonItem:closeItem];
    
    [UnityGetGLViewController() presentViewController:self.navVC animated:YES completion:nil];
}

- (void)closeButtonPressed:(UIButton *)button {
    [self.navVC dismissViewControllerAnimated:YES completion:NULL];
}

# pragma mark - Custom Attributes

- (void)setString:(NSString *)value forKey:(NSString *)key withGameObject:(NSString *)gameObject andErrorCallback:(NSString *)errorCallback {
    self.stringAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage([gameObject UTF8String], [errorCallback UTF8String], [error.localizedDescription UTF8String]);
        }
    };
    [Carnival setString:value forKey:key withResponse:self.stringAttributeSetBlock];
}

- (void)setBoolean:(BOOL)value forKey:(NSString *)key withGameObject:(NSString *)gameObject andErrorCallback:(NSString *)errorCallback {
    self.booleanAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage([gameObject UTF8String], [errorCallback UTF8String], [error.localizedDescription UTF8String]);
        }
    };
    [Carnival setBool:value forKey:key withResponse:self.booleanAttributeSetBlock];
}

- (void)setDate:(NSDate *)value forKey:(NSString *)key withGameObject:(NSString *)gameObject andErrorCallback:(NSString *)errorCallback {
    self.dateAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage([gameObject UTF8String], [errorCallback UTF8String], [error.localizedDescription UTF8String]);
        }
    };
    [Carnival setDate:value forKey:key withResponse:self.dateAttributeSetBlock];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key withGameObject:(NSString *)gameObject andErrorCallback:(NSString *)errorCallback {
    self.integerAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage([gameObject UTF8String], [errorCallback UTF8String], [error.localizedDescription UTF8String]);
        }
    };
    [Carnival setInteger:value forKey:key withResponse:self.integerAttributeSetBlock];
}

- (void)setFloat:(CGFloat)value forKey:(NSString *)key withGameObject:(NSString *)gameObject andErrorCallback:(NSString *)errorCallback {
    self.floatAttributeSetBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage([gameObject UTF8String], [errorCallback UTF8String], [error.localizedDescription UTF8String]);
        }
    };
    [Carnival setFloat:value forKey:key withResponse:self.floatAttributeSetBlock];
}

- (void)unsetValueForKey:(NSString *)key withGameObject:(NSString *)gameObject andErrorCallback:(NSString *)errorCallback {
    self.unsetAttributeBlock = ^(NSError *error) {
        if (error) {
            UnitySendMessage([gameObject UTF8String], [errorCallback UTF8String], [error.localizedDescription UTF8String]);
        }
    };
    [Carnival removeAttributeWithKey:key withResponse:self.unsetAttributeBlock];
}



@end
