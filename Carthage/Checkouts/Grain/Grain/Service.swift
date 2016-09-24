//
//	Service.swift
//	Grain
//
//	Created by Patrick Smith on 17/03/2016.
//	Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ServiceProtocol {
	func async(_ closure: @escaping () -> ())
}


public func + <Result>(lhs: Deferred<Result>, rhs: ServiceProtocol) -> Deferred<Result> {
	return Deferred.future{ resolve in
		lhs.perform{ useResult in
			rhs.async{
				resolve(useResult)
			}
		}
	}
}

public func += <Result>(lhs: inout Deferred<Result>, rhs: ServiceProtocol) {
	lhs = lhs + rhs
}
