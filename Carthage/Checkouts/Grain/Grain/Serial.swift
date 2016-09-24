//
//	SerialStage.swift
//	Grain
//
//	Created by Patrick Smith on 19/04/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Serial<Stage : StageProtocol> {
	public typealias Result = [() throws -> Stage.Result]
	
	case start(stages: [Stage], environment: Environment)
	case running(remainingStages: [Stage], activeStage: Stage, completedSoFar: [() throws -> Stage.Result], environment: Environment)
	case completed(Result)
}

extension Serial : StageProtocol {
	public func next() -> Deferred<Serial> {
		switch self {
		case let .start(stages, environment):
			return Deferred{
				if stages.count == 0 {
					return .completed([])
				}
				
				var remainingStages = stages
				let nextStage = remainingStages.remove(at: 0)
				
				return .running(remainingStages: remainingStages, activeStage: nextStage, completedSoFar: [], environment: environment)
			}
		case let .running(remainingStages, activeStage, completedSoFar, environment):
			return activeStage.taskExecuting(environment).flatMap { useCompletion in
				var completedSoFar = completedSoFar
				completedSoFar.append(useCompletion)
				
				if remainingStages.count == 0 {
					return Deferred{ .completed(completedSoFar) }
				}
				
				var remainingStages = remainingStages
				let nextStage = remainingStages.remove(at: 0)
				
				return Deferred{ .running(remainingStages: remainingStages, activeStage: nextStage, completedSoFar: completedSoFar, environment: environment) }
			}
		case .completed:
			completedStage(self)
		}
	}
	
	public var result: Result? {
		guard case let .completed(result) = self else { return nil }
		return result
	}
}


extension Sequence where Iterator.Element : StageProtocol {
	public func executeSerially(
		_ environment: Environment,
		completion: @escaping (() throws -> [() throws -> Iterator.Element.Result]) -> ()
		)
	{
		Serial.start(stages: Array(self), environment: environment)
			.execute(environment: environment, completionService: nil, completion: completion)
	}
}
