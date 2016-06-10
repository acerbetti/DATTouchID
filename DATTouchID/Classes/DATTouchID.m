//
//  DATTouchID.m
//  DATTouchID
//
//  Created by Peter Gulyas on 2016-06-08.
//  Copyright © 2016 DATInc. All rights reserved.
//

#import "DATTouchID.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface DATTouchID ()
@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) DATTouchIDAuthenticationType type;
@end

@implementation DATTouchID

- (instancetype) initWithKey:(NSString* __nonnull ) key type:(DATTouchIDAuthenticationType) type{
    self = [super init];
    if (self){
        self.key = key;
        self.type = type;
    }
    return self;
}

- (instancetype) initWithKey:(NSString*) key{
    return [self initWithKey:key type:DATTouchIDAuthenticationTypeTouchIDAndPasscode];
}

- (instancetype) init{
    return [self initWithKey:@"DATTouchID-authentication"];
}

+ (BOOL) touchIdAvailable:(DATTouchIDAuthenticationType) type error:(NSError * __nullable * __nullable)error{
    LAContext* context = [LAContext new];
    
    switch (type) {
        case DATTouchIDAuthenticationTypePasscode: return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:error];
        case DATTouchIDAuthenticationTypeTouchID: return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:error];
        case DATTouchIDAuthenticationTypeTouchIDAndPasscode: return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:error];
    }
}

- (BOOL) isAvailable:(NSError * __nullable * __nullable)error{
    return [[self class] touchIdAvailable:self.type error:error];
}

- (NSString *)keychainErrorToString:(OSStatus)error {
    switch (error) {
        case errSecSuccess: return @"success";
        case errSecDuplicateItem: return @"item already exists";
        case errSecItemNotFound: return @"item not found";
        case errSecAuthFailed: return @"item authentication failed";
        case errSecUserCanceled: return @"item authentication canceled";
        default: return [NSString stringWithFormat:@"Unknown error: %ld", (long)error];
    }
}

- (void) updateUserDefaultsWithStatus:(OSStatus) status{
    
    BOOL success = NO;
    switch (status) {
        case errSecDuplicateItem:
        case errSecSuccess:{
            success = YES;
        } break;
        case errSecItemNotFound:{
            success = NO;
        }break;
        default:
            return; // do nothing
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:success forKey:self.key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (SecAccessControlRef) createSecAccessControlRefWithError:(NSError **) error{
    CFErrorRef cfError = NULL;
    SecAccessControlCreateFlags flags = 0;
    
    switch (self.type) {
        case DATTouchIDAuthenticationTypePasscode:
            flags = kSecAccessControlDevicePasscode;
            break;
        case DATTouchIDAuthenticationTypeTouchID:
            flags = kSecAccessControlTouchIDAny;
            break;
        case DATTouchIDAuthenticationTypeTouchIDAndPasscode:
            flags = kSecAccessControlDevicePasscode | kSecAccessControlOr | kSecAccessControlTouchIDAny;
            break;
        
    }
    
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                    flags, &cfError);
    if (error){
        *error = (__bridge NSError *)cfError;
    }
    
    return sacObject;
    
}

- (void) getDataWithComplete:(void(^ __nullable)(NSData* __nullable data, NSError * __nullable error))complete{
    [self getDataWithPrompt:nil complete:complete];
}

- (void) getDataWithPrompt:(NSString* __nullable) prompt complete:(void(^ __nullable)(NSData* __nullable data, NSError * __nullable error))complete{
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                     (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                                                                     (__bridge id)kSecAttrService: self.key,
                                                                                     (__bridge id)kSecReturnData: @YES,
                                                                                     }];
        
        if (prompt.length > 0){
            query[(__bridge id)kSecUseOperationPrompt] = prompt;
        }
        
        CFTypeRef dataTypeRef = NULL;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUserDefaultsWithStatus:status];
            
            if (status == errSecSuccess || status == errSecItemNotFound) {
                if (complete){
                    NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;
                    complete(resultData, nil);
                }
            } else {
                if (complete){
                    NSError *error = [self errorForStatus:status];
                    complete(nil, error);
                }
            }
        });
        
    });
}

- (NSError*) errorForStatus:(OSStatus) status{
    return [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey: [self keychainErrorToString:status]}];
}

- (void) setData:(NSData *)data complete:(void(^)(BOOL success, NSError * __nullable error))complete{
    
    NSError *error = nil;
    
    SecAccessControlRef sacObject = [self createSecAccessControlRefWithError:&error];
    
    if (sacObject == NULL || error != nil) {
        if (complete){
            complete(NO, error);
        }
        return;
    }
    
    LAContext *context = [[LAContext alloc] init];
    [context evaluateAccessControl:sacObject operation:LAAccessControlOperationCreateItem localizedReason:@"setData" reply:^(BOOL success, NSError * _Nullable error) {
     
        NSDictionary *query = @{
                                (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService: self.key,
                                };
        
        SecItemDelete((__bridge CFDictionaryRef)query);
        
        if (data){
            NSDictionary *attributes = @{
                                         (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                         (__bridge id)kSecAttrService: self.key,
                                         (__bridge id)kSecValueData: data,
                                         (__bridge id)kSecUseAuthenticationUI: @YES,
                                         (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject,
                                         (__bridge id)kSecUseAuthenticationContext: context
                                         };
            
            OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateUserDefaultsWithStatus:status];
                if (status == errSecSuccess){
                    if (complete){
                        complete(YES, nil);
                    }
                } else {
                    if (complete){
                        NSError *error = [self errorForStatus:status];
                        complete(NO, error);
                    }
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateUserDefaultsWithStatus:errSecItemNotFound];
                if (complete){
                    complete(YES, nil);
                }
            });
        }
 }];
}

- (BOOL) hasData {
    return [[NSUserDefaults standardUserDefaults] boolForKey:self.key];
}

@end
