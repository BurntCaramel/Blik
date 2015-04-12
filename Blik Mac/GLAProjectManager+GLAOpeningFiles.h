//
//  GLAProjectManager+GLAOpeningFiles.h
//  Blik
//
//  Created by Patrick Smith on 9/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAProjectManager.h"


typedef NS_ENUM(NSUInteger, GLAOpenBehaviour) {
	GLAOpenBehaviourDefault = 0,
	GLAOpenBehaviourShowInFinder = 1,
	GLAOpenBehaviourAllowEditingApplications = 2
};


@interface GLAProjectManager (GLAOpeningFiles)

- (void)openCollectedFile:(GLACollectedFile *)collectedFile behaviour:(GLAOpenBehaviour)behaviour;
- (void)openCollectedFile:(GLACollectedFile *)collectedFile modifierFlags:(NSEventModifierFlags)modifierFlags;

- (BOOL)openHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile behaviour:(GLAOpenBehaviour)behaviour;
- (BOOL)openHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile modifierFlags:(NSEventModifierFlags)modifierFlags;

- (GLAOpenBehaviour)openBehaviourForModifierFlags:(NSEventModifierFlags)modifierFlags;

@end
