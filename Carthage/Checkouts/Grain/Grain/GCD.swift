//
//	GCD.swift
//	Grain
//
//	Created by Patrick Smith on 17/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GCDService : ServiceProtocol {
	case background, utility, userInitiated, userInteractive
	case mainQueue
	case customQueue(DispatchQueue)
	
	public var queue: DispatchQueue {
		switch self {
		case .background:
			return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
		case .utility:
			return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
		case .userInitiated:
			return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
		case .userInteractive:
			return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
		case .mainQueue:
			return DispatchQueue.main
		case let .customQueue(queue):
			return queue
		}
	}
	
	public func async(_ closure: @escaping () -> ()) {
		queue.async(execute: closure)
	}
	
	public func after(_ delay: Double, closure: @escaping () -> ()) {
		let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		queue.asyncAfter(deadline: time, execute: closure)
	}
	
	public func sync(_ closure: () -> ()) {
		queue.sync(execute: closure)
	}
	
	public func suspend() {
		queue.suspend()
	}
	
	public func resume() {
		queue.resume()
	}
	
	public static func serial(_ label: String) -> GCDService {
		let queue = DispatchQueue(label: label, attributes: [])
		return .customQueue(queue)
	}
}


extension GCDService : Environment {
	public func service
		<Stage : StageProtocol>
		(for stage: Stage) -> ServiceProtocol
	{
		return self
	}
}


// Used for + below
private struct GCDDelayedService : ServiceProtocol {
	fileprivate let underlyingService: GCDService
	fileprivate let delay: Double
	
	fileprivate func async(_ closure: @escaping () -> ()) {
		underlyingService.after(delay, closure: closure)
	}
}

// e.g. Delay by 4 seconds: `GCDService.mainQueue + 4.0`
public func + (lhs: GCDService, rhs: Double) -> ServiceProtocol {
	return GCDDelayedService(underlyingService: lhs, delay: rhs)
}


extension StageProtocol {
	// Convenience method for GCD
	public func execute(_ completion: @escaping (@escaping () throws -> Result) -> ()) {
		execute(environment: GCDService.utility, completionService: nil, completion: completion)
	}

	// Convenience method for GCD
	public func taskExecuting() -> Deferred<Result> {
		return .future{ self.execute($0) }
	}
}
