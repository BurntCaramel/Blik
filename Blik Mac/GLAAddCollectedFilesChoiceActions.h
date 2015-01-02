//
//  GLAAddCollectedFilesChoiceActions.h
//  Blik
//
//  Created by Patrick Smith on 9/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAPendingAddedCollectedFilesInfo.h"


@protocol GLAAddCollectedFilesChoiceActionsDelegate <NSObject>

- (void)performAddCollectedFilesToExistingCollection:(NSResponder *)responder info:(GLAPendingAddedCollectedFilesInfo *)info;
- (void)performAddCollectedFilesToNewCollection:(NSResponder *)responder info:(GLAPendingAddedCollectedFilesInfo *)info;

@end
