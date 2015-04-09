//
//  GLAProjectMenuController.h
//  Blik
//
//  Created by Patrick Smith on 8/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAProject.h"


@interface GLAProjectMenuController : NSObject <NSMenuDelegate>

- (instancetype)initWithMenu:(NSMenu *)menu project:(GLAProject *)project;

@property(readonly, nonatomic) NSMenu *menu;
@property(readonly, nonatomic) GLAProject *project;

- (void)updateMenu;

@end
