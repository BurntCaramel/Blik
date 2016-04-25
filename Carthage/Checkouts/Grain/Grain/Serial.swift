//
//  SerialStage.swift
//  Grain
//
//  Created by Patrick Smith on 19/04/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Serial<
	Stage : StageProtocol,
	ExecutionCustomizer : ExecutionCustomizing
	where
	ExecutionCustomizer.Stage == Stage
	>
{
	public typealias Completion = [() throws -> Stage.Completion]
	
	case start(stages: [Stage], executionCustomizer: ExecutionCustomizer)
	case running(remainingStages: [Stage], activeStage: Stage, completedSoFar: [() throws -> Stage.Completion], executionCustomizer: ExecutionCustomizer)
	case completed(Completion)
}

extension Serial : StageProtocol {
	public var nextTask: Task<Serial>? {
		switch self {
		case let .start(stages, executionCustomizer):
			if stages.count == 0 {
				return Task{ .completed([]) }
			}
			
			var remainingStages = stages
			let nextStage = remainingStages.removeAtIndex(0)
			
			return Task{
				.running(remainingStages: remainingStages, activeStage: nextStage, completedSoFar: [], executionCustomizer: executionCustomizer)
			}
		case let .running(remainingStages, activeStage, completedSoFar, executionCustomizer):
			return activeStage.taskExecuting(customizer: executionCustomizer).flatMap { useCompletion in
				var completedSoFar = completedSoFar
				completedSoFar.append(useCompletion)
				
				if remainingStages.count == 0 {
					return Task{ .completed(completedSoFar) }
				}
				
				var remainingStages = remainingStages
				let nextStage = remainingStages.removeAtIndex(0)
				
				return Task{ .running(remainingStages: remainingStages, activeStage: nextStage, completedSoFar: completedSoFar, executionCustomizer: executionCustomizer) }
			}
		case .completed:
			return nil
		}
	}
	
	public var completion: Completion? {
		guard case let .completed(completion) = self else { return nil }
		return completion
	}
}


extension SequenceType where Generator.Element : StageProtocol {
	public func executeSerially<
		IC : ExecutionCustomizing,
		SC : ExecutionCustomizing
		where
		IC.Stage == Generator.Element,
		SC.Stage == Serial<Generator.Element, IC>
		>(
		elementCustomizer: IC,
		serialCustomizer: SC,
		completion: (() throws -> [() throws -> Generator.Element.Completion]) -> ()
		)
	{
		Serial.start(stages: Array(self), executionCustomizer: elementCustomizer)
			.execute(customizer: serialCustomizer, completion: completion)
	}
}
