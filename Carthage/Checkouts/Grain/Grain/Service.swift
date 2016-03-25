//
//  Service.swift
//  Grain
//
//  Created by Patrick Smith on 17/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ServiceProtocol {
	func async(closure: () -> ())
}
