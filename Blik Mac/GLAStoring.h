//
//  GLAStoring.h
//  Blik
//
//  Created by Patrick Smith on 17/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;


typedef NS_ENUM(NSUInteger, GLAStoringLoadState) {
	GLAStoringLoadStateNeedsLoading,
	GLAStoringLoadStateCurrentlyLoading,
	GLAStoringLoadStateFinishedLoading
};

typedef NS_ENUM(NSUInteger, GLAStoringSaveState) {
	GLAStoringSaveStateNeedsSaving,
	GLAStoringSaveStateCurrentlySaving,
	GLAStoringSaveStateFinishedSaving
};