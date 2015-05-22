//
//  GLAFolderContentsAssisting.h
//  Blik
//
//  Created by Patrick Smith on 21/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAFileCollecting.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GLAFolderContentsAssisting <GLAFileCollecting>

- (void)folderContentsSelectionDidChange;

@end

NS_ASSUME_NONNULL_END