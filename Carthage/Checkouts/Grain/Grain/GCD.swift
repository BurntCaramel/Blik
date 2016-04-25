//
//  GCD.swift
//  Grain
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GCDService: ServiceProtocol {
	case background, utility, userInitiated, userInteractive
	case mainQueue
	case customQueue(dispatch_queue_t)
	
	public var queue: dispatch_queue_t {
		switch self {
		case .background:
			return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
		case .utility:
			return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
		case .userInitiated:
			return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
		case .userInteractive:
			return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
		case .mainQueue:
			return dispatch_get_main_queue()
		case let .customQueue(queue):
			return queue
		}
	}
	
	public func async(closure: () -> ()) {
		dispatch_async(queue, closure)
	}
}

let queue = dispatch_queue_create("com.example.results", DISPATCH_QUEUE_SERIAL)


public struct GCDExecutionCustomizer<Stage: StageProtocol>: ExecutionCustomizing {
	public var serviceForStage: Stage -> ServiceProtocol = { _ in GCDService.userInitiated }
	public var completionService: ServiceProtocol = GCDService.mainQueue
	
	public var shouldStopStage: Stage -> Bool = { _ in false }
	public var beforeStage: Stage -> () = { _ in }
	
	public init() {}
}

// Convenience method for GCD
extension StageProtocol {
	public func execute(completion: (() throws -> Completion) -> ()) {
		execute(customizer: GCDExecutionCustomizer(), completion: completion)
	}
}


extension StageProtocol {
	public func taskExecuting() -> Task<Completion>? {
		return .future({ self.execute($0) })
	}
}
