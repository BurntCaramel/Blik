//
//  Task.swift
//  Grain
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Task<Result> {
	public typealias UseResult = () throws -> Result
	
	case unit(UseResult)
	case future((UseResult -> ()) -> ())
}

extension Task {
	public init(_ subroutine: UseResult) {
			self = .unit(subroutine)
	}
	
	public init(_ error: ErrorType) {
		self = .unit({ throw error })
	}
}

extension Task {
	public func perform(handleResult: UseResult -> ()) {
		switch self {
		case let .unit(useResult):
			handleResult(useResult)
		case let .future(requestResult):
			requestResult(handleResult)
		}
	}
	
	public func map<Output>(transform: Result throws -> Output) -> Task<Output> {
		switch self {
		case let .unit(useResult):
			return .unit({
				return try transform(useResult())
			})
		case let .future(requestResult):
			return .future({ resolve in
				requestResult{ useResult in
					resolve{ try transform(useResult()) }
				}
			})
		}
	}
	
	public func flatMap<Output>(transform: UseResult throws -> Task<Output>) -> Task<Output> {
		switch self {
		case let .unit(useResult):
			do {
				return try transform(useResult)
			}
			catch {
				return Task<Output>(error)
			}
		case let .future(requestResult):
			return .future({ resolve in
				requestResult{ useResult in
					do {
						let transformedTask = try transform(useResult)
						transformedTask.perform(resolve)
					}
					catch {
						resolve{ throw error }
					}
				}
			})
		}
	}
}



public protocol CompletingProtocol {
	associatedtype Completion
	
	func requireCompletion() throws -> Completion
}

extension Task where Result: CompletingProtocol {
	public func ensureCompleted() -> Task<Result.Completion> {
		return self.map{ try $0.requireCompletion() }
	}
}
