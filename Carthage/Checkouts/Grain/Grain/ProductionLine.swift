//
//	ProductionLine.swift
//	Grain
//
//	Created by Patrick Smith on 19/04/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


open class ProductionLine<Stage : StageProtocol> {
	fileprivate let maxCount: Int
	fileprivate let environment: Environment
	fileprivate var pending: [Stage] = []
	fileprivate var active: [Stage] = []
	fileprivate var completed: [() throws -> Stage.Result] = []
	fileprivate var stateService = GCDService.serial("ProductionLine \(String(describing: Stage.self))")
	
	public init(maxCount: Int, environment: Environment) {
		precondition(maxCount > 0, "maxCount must be greater than zero")
		self.maxCount = maxCount
		self.environment = environment
	}
	
	fileprivate func executeStage(_ stage: Stage) {
		stage.execute(environment: self.environment, completionService: self.stateService) {
			[weak self] useCompletion in
			guard let receiver = self else { return }
			
			receiver.completed.append(useCompletion)
			receiver.activateNext()
		}
	}
	
	open func add(_ stage: Stage) {
		stateService.async {
			if self.active.count < self.maxCount {
				self.executeStage(stage)
			}
			else {
				self.pending.append(stage)
			}
		}
	}
	
	fileprivate func activateNext() {
		stateService.async {
			let dequeueCount = self.maxCount - self.active.count
			guard dequeueCount > 0 else { return }
			let dequeued = self.pending.prefix(dequeueCount)
			self.pending.removeFirst(dequeueCount)
			dequeued.forEach(self.executeStage)
		}
	}
	
	open func add(_ stages: [Stage]) {
		for stage in stages {
			add(stage)
		}
	}
	
	open func clearPending() {
		stateService.async {
			self.pending.removeAll()
		}
	}
	
	open func suspend() {
		stateService.suspend()
	}
	
	open func resume() {
		stateService.resume()
	}
}
