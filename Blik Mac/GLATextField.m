//
//  GLATextField.m
//  Blik
//
//  Created by Patrick Smith on 8/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLATextField.h"


@implementation GLATextField

- (BOOL)becomeFirstResponder
{
	//[[NSNotificationCenter defaultCenter] postNotificationName:GLATextFieldWillBecomeFirstResponder object:self];
	
	BOOL flag = [super becomeFirstResponder];
	if (flag) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GLATextFieldDidBecomeFirstResponder object:self];
	}
	return flag;
}

- (BOOL)resignFirstResponder
{
	BOOL flag = [super resignFirstResponder];
	if (flag) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GLATextFieldDidResignFirstResponder object:self];
	}
	return flag;
}

@end

NSString *GLATextFieldWillBecomeFirstResponder = @"GLATextFieldWillBecomeFirstResponder";
NSString *GLATextFieldDidBecomeFirstResponder = @"GLATextFieldDidBecomeFirstResponder";
NSString *GLATextFieldDidResignFirstResponder = @"GLATextFieldDidResignFirstResponder";