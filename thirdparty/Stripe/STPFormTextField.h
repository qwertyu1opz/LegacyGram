//
//  STPFormTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPFormTextField;

typedef NS_ENUM(NSInteger, STPFormTextFieldAutoFormattingBehavior) {
    STPFormTextFieldAutoFormattingBehaviorNone,
    STPFormTextFieldAutoFormattingBehaviorPhoneNumbers,
    STPFormTextFieldAutoFormattingBehaviorCardNumbers,
    STPFormTextFieldAutoFormattingBehaviorExpiration,
};

@protocol STPFormTextFieldDelegate <UITextFieldDelegate>
@optional
- (void)formTextFieldDidBackspaceOnEmpty:(STPFormTextField *)formTextField;
- (NSAttributedString *)formTextField:(STPFormTextField *)formTextField
           modifyIncomingTextChange:(NSAttributedString *)input;
- (void)formTextFieldTextDidChange:(STPFormTextField *)textField;
@end

@interface STPFormTextField : UITextField

@property(nonatomic, readwrite) UIColor *defaultColor;
@property(nonatomic, readwrite) UIColor *errorColor;
@property(nonatomic, readwrite) UIColor *placeholderColor;

@property(nonatomic, readwrite, assign)BOOL selectionEnabled; // defaults to NO
@property(nonatomic, readwrite, assign)BOOL preservesContentsOnPaste; // defaults to NO
@property(nonatomic, readwrite, assign)STPFormTextFieldAutoFormattingBehavior autoFormattingBehavior;
@property(nonatomic, readwrite, assign)BOOL validText;
@property(nonatomic, readwrite, weak)id<STPFormTextFieldDelegate>formDelegate;

- (CGSize)measureTextSize;

@end
