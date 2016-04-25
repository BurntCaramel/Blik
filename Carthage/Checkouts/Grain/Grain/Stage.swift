//
//  Stage.swift
//  Grain
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol StageProtocol: CompletingProtocol {
	var nextTask: Task<Self>? { get }
	
	var completion: Completion? { get }
}

public enum StageError<Stage: StageProtocol>: ErrorType {
	case stageAlreadyCompleted(Stage)
	case expectedCompletion(Stage)
	case stageInvalid(Stage)
}

extension StageProtocol {
	public func requireCompletion() throws -> Self.Completion {
		guard let completion = completion else {
			throw StageError.expectedCompletion(self)
		}
		
		return completion
	}
}

extension StageProtocol {
	public func mapNext<OtherStage: StageProtocol>(transform: Self throws -> OtherStage) -> Task<OtherStage> {
		guard let nextTask = self.nextTask else {
			return .unit({ throw StageError.stageAlreadyCompleted(self) })
		}
		
		return nextTask.map(transform)
	}
}
