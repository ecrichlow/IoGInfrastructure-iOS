/*
********************************************************************************
* TestComputerObject.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the sample data object
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	01/16/19		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation
@testable import IoGInfrastructure

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

	required init(from decoder: Decoder) throws
	{
		try super .init(from: decoder)
	}
}
