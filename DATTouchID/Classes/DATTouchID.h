//
//  DATTouchID.h
//  DATTouchID
//
//  Created by Peter Gulyas on 2016-06-08.
//  Copyright © 2016 DATInc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DATTouchIDAuthenticationType){
    DATTouchIDAuthenticationTypeTouchID,
    DATTouchIDAuthenticationTypePasscode,
    DATTouchIDAuthenticationTypeTouchIDAndPasscode,
};

@interface DATTouchID : NSObject

+ (BOOL) touchIdAvailable:(DATTouchIDAuthenticationType) type error:(NSError * __nullable * __nullable)error;
- (BOOL) isAvailable:(NSError * __nullable * __nullable)error;

- (instancetype __nullable) initWithKey:(NSString* __nonnull) key type:(DATTouchIDAuthenticationType) type;
- (instancetype __nullable) initWithKey:(NSString* __nonnull) key;

@property (nonatomic, readonly, nonnull) NSString* key;
@property (nonatomic, readonly) DATTouchIDAuthenticationType type;
@property (nonatomic, readonly) BOOL hasData;

- (void) setData:(NSData* __nullable)data complete:(void(^ __nullable)(BOOL success, NSError * __nullable error))complete;
- (void) getDataWithComplete:(void(^ __nullable)(NSData* __nullable data, NSError * __nullable error))complete;
- (void) getDataWithPrompt:(NSString* __nullable) prompt complete:(void(^ __nullable)(NSData* __nullable data, NSError * __nullable error))complete;

@end
