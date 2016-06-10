//
//  DATViewController.m
//  DATTouchID
//
//  Created by Peter Gulyas on 06/10/2016.
//  Copyright (c) 2016 Peter Gulyas. All rights reserved.
//

#import "DATViewController.h"
#import "DATTouchID.h"

@interface DATViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loadCredentialsButton;
@property (weak, nonatomic) IBOutlet UIButton *clearCredentialsButton;

@property (nonatomic, nullable, strong) DATTouchID* touchId;
@end

@implementation DATViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.touchId = [DATTouchID new];
    [self updateButtons];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.usernameField becomeFirstResponder];
}

#pragma mark -

- (void) updateButtons{
    BOOL hasData = self.touchId.hasData;
    self.loadCredentialsButton.enabled = hasData;
    self.clearCredentialsButton.enabled = hasData;
}

- (void) presentErrorWithTitle:(NSString*) title message:(NSString*) message complete:(dispatch_block_t) complete{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (complete){
            complete();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) saveUsername:(nonnull NSString*) username password:(nonnull NSString*) password{
    NSDictionary* info = @{@"username" : username,
                           @"password" : password};
    NSData* data = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];
    
    __weak DATViewController* this = self;
    [self.touchId setData:data complete:^(BOOL success, NSError * _Nullable error) {
        [this updateButtons];
        if (!success && error){
            [this presentErrorWithTitle:@"Error" message:error.localizedDescription complete:nil];
        }
    }];
}

- (void) presentSavedUsername:(NSString*) username password:(NSString*) password{
    
    NSString* message = [NSString stringWithFormat:@"Username: %@\nPassword: %@", username, password];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Saved credentials" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - IBAction

- (IBAction)loginUsingStoredCredentials {
    __weak DATViewController* this = self;
    [self.touchId getDataWithComplete:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (data){
            NSDictionary* info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [this presentSavedUsername:info[@"username"] password:info[@"password"]];
            [this updateButtons];
        } else if (error){
            [this presentErrorWithTitle:@"Error" message:error.localizedDescription complete:nil];
        }
        
    }];
}

- (IBAction)loginUsingProvidedCredentials {
    __weak DATViewController* this = self;
    
    if (self.usernameField.text.length == 0){
        [self presentErrorWithTitle:nil message:@"Username is required" complete:^{
            [this.usernameField becomeFirstResponder];
        }];
        return;
    }
    
    if (self.passwordField.text.length == 0){
        [self presentErrorWithTitle:nil message:@"Password is required" complete:^{
            [this.passwordField becomeFirstResponder];
        }];
        return;
    }
    
    NSString* message = [NSString stringWithFormat:@"Would you like to save the following credentials?\nUsername: %@\nPassword: %@", self.usernameField.text, self.passwordField.text];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Provided credentials?" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [this saveUsername:this.usernameField.text password:this.passwordField.text];
        
        this.usernameField.text = nil;
        this.passwordField.text = nil;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction) clearSavedCredentials {
    __weak DATViewController* this = self;
    [self.touchId setData:nil complete:^(BOOL success, NSError * _Nullable error) {
        [this updateButtons];
        if (!success && error){
            [this presentErrorWithTitle:@"Error" message:error.localizedDescription complete:nil];
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Cleared credentials" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
            [this presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    if (textField == self.usernameField){
        [self.passwordField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self loginUsingProvidedCredentials];
    }
    
    return NO;
}

@end