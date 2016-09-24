//
//	Environment.swift
//	Grain
//
//	Created by Patrick Smith on 17/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol Environment {
	func service
		<Stage : StageProtocol>
		(for stage: Stage) -> ServiceProtocol
	
	func shouldStop
		<Stage : StageProtocol>
		(_ stage: Stage) -> Bool
	
	func before
		<Stage : StageProtocol>
		(_ stage: Stage) -> ()
	
	func adjust
		<Stage : StageProtocol>(_ stage: Stage) -> Stage
}

extension Environment {
	public func shouldStop
		<Stage : StageProtocol>
		(_ stage: Stage) -> Bool
	{
		return false
	}
	
	public func before
		<Stage : StageProtocol>
		(_ stage: Stage) -> ()
	{}
	
	public func adjust
		<Stage : StageProtocol>
		(_ stage: Stage) -> Stage
	{
		return stage
	}
}


public enum EnvironmentError : Error {
	case stopped
}


extension ServiceProtocol where Self : Environment {
	func service
		<Stage : StageProtocol>
		(for stage: Stage) -> ServiceProtocol
	{
		return self
	}
}
