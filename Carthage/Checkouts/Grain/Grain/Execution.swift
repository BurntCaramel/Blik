//
//  Executor.swift
//  Grain
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ExecutionCustomizing {
	associatedtype Stage: StageProtocol
	
	var serviceForStage: Stage -> ServiceProtocol { get }
	var completionService: ServiceProtocol { get }
	
	var shouldStopStage: Stage -> Bool { get }
	var beforeStage: Stage -> () { get }
}


public enum ExecutionError: ErrorType {
	case stopped
}


extension StageProtocol {
	public func execute<ExecutionCustomizer: ExecutionCustomizing where ExecutionCustomizer.Stage == Self>(customizer customizer: ExecutionCustomizer, completion: (() throws -> Completion) -> ()) {
		func complete(useStage: (() throws -> Self)) {
			customizer.completionService.async {
				completion({
					try useStage().requireCompletion()
				})
			}
		}
		
		func handleResult(getStage: () throws -> Self) {
			do {
				let nextStage = try getStage()
				runStage(nextStage)
			}
			catch let error {
				complete { throw error }
			}
		}
		
		func runStage(stage: Self) {
			customizer.serviceForStage(stage).async {
				if customizer.shouldStopStage(stage) {
					complete { throw ExecutionError.stopped }
					return
				}
				
				customizer.beforeStage(stage)
				
				if let nextTask = stage.nextTask {
					nextTask.perform(handleResult)
				}
				else {
					complete { stage }
				}
			}
		}
		
		runStage(self)
	}
	
	public func taskExecuting<ExecutionCustomizer: ExecutionCustomizing where ExecutionCustomizer.Stage == Self>(customizer customizer: ExecutionCustomizer) -> Task<Completion> {
		return Task.future{ resolve in
			self.execute(customizer: customizer, completion: resolve)
		}
	}
}
