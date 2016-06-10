# DATTouchID

[![CI Status](http://img.shields.io/travis/Peter Gulyas/DATTouchID.svg?style=flat)](https://travis-ci.org/Peter Gulyas/DATTouchID)
[![Version](https://img.shields.io/cocoapods/v/DATTouchID.svg?style=flat)](http://cocoapods.org/pods/DATTouchID)
[![License](https://img.shields.io/cocoapods/l/DATTouchID.svg?style=flat)](http://cocoapods.org/pods/DATTouchID)
[![Platform](https://img.shields.io/cocoapods/p/DATTouchID.svg?style=flat)](http://cocoapods.org/pods/DATTouchID)

Use DATTouchID to access or store data using biometrics or passcode to authenticate

## Example Project

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Example Implementation

```ObjC

- (void) viewDidLoad{
  ...
  self.touchId = [DATTouchID new];
  if (self.touchId.hasData){
    ... update interface
  }
}

- (void) loadData{
  [self.touchId getDataWithPrompt:@"Load stored credentials" complete:^(NSData *data, NSError *error) {
    ...
  }];
}

- (void) saveData{
  NSData* data = ...;
  [self.touchId setData:data complete:^(BOOL success, NSError * error) {
    ...
  }];
}
```

## Installation

DATTouchID is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "DATTouchID"
```

## Author

Peter Gulyas, peter@datinc.ca

## License

DATTouchID is available under the MIT license. See the LICENSE file for more info.
