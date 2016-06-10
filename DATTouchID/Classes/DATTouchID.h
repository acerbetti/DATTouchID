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

+ (BOOL) touchIdAvailable:(DATTouchIDAuthenticationType) type error:(NSError **)error;
- (BOOL) isAvailable:(NSError **)error;

- (instancetype) initWithKey:(NSString* ) key type:(DATTouchIDAuthenticationType) type;
- (instancetype) initWithKey:(NSString* ) key;

@property (nonatomic, readonly) NSString* key;
@property (nonatomic, readonly) DATTouchIDAuthenticationType type;
@property (nonatomic, readonly) BOOL hasData;

- (void) setData:(NSData*)data complete:(void(^)(BOOL success, NSError * error))complete;
- (void) getDataWithPrompt:(NSString*) prompt complete:(void(^)(NSData* data, NSError * error))complete;

@end
