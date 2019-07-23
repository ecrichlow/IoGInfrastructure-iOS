//
//  TestComputerObject.swift
//  FMInfrastructureTests
//
//  Created by Eric Crichlow on 1/16/19.
//  Copyright © 2018 Infusions of Grandeur. All rights reserved.
//

import Foundation
@testable import IoG_Infrastructure

class TestComputerObject : IoGDataObject
{
	var model : String
	{
		get
		{
			return getValue("model") as! String
		}
	}
	var processor : String
	{
		get
		{
			return getValue("processor") as! String
		}
	}

	required init(withString source: String)
	{
		super.init(withString: source)
	}
}
