//
//	Stage.swift
//	Grain
//
//	Created by Patrick Smith on 17/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol StageProtocol {
	associatedtype Result
	
	func next() -> Deferred<Self>
	
	var result: Result? { get }
}


extension StageProtocol {
	public func compose
    <Other>(
    transformNext: @escaping (Self) throws -> Other,
    transformResult: (Result) -> Deferred<Other>
    ) -> Deferred<Other>
	{
		if let result = result {
			return transformResult(result)
		}
		else {
			return next().map(transformNext)
		}
	}
}


extension StageProtocol {
	public func execute(
    environment: Environment,
    completionService: ServiceProtocol?,
    completion: @escaping (@escaping () throws -> Result) -> ()
    )
	{
		func complete(_ useResult: (@escaping () throws -> Result)) {
			if let completionService = completionService {
				completionService.async{
					completion(useResult)
				}
			}
			else {
				completion(useResult)
			}
		}
		
		func handleResult(_ getStage: () throws -> Self) {
			do {
				let nextStage = try getStage()
				run(nextStage)
			}
			catch let error {
				complete{ throw error }
			}
		}
		
		func run(_ stage: Self) {
			environment.service(for: stage).async {
				if environment.shouldStop(stage) {
					complete{ throw EnvironmentError.stopped }
					return
				}
				
				environment.before(stage)
				
				if let result = stage.result {
					complete{ result }
				}
				else {
					let nextDeferred = stage.next()
					nextDeferred.perform(handleResult)
				}
			}
		}
		
		run(self)
	}
	
	public func taskExecuting
		(_ environment: Environment) -> Deferred<Result>
	{
		return Deferred.future{ resolve in
			self.execute(environment: environment, completionService: nil, completion: resolve)
		}
	}
}


public func *
	<Result, Stage : StageProtocol>
	(lhs: Stage, rhs: Environment) -> Deferred<Result> where Stage.Result == Result
{
	return lhs.taskExecuting(rhs)
}


public func completedStage
	<Stage : StageProtocol>
	(_ stage: Stage) -> Never
{
	fatalError("No next task for completed stage \(stage)")
}
