/*
********************************************************************************
* TestRoute.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the sample GQL Route object
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/27/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation
@testable import IoGInfrastructure

class Route: IoGGQLDataObject
{
	var origin: String? = ""
	var destination: String? = ""

	// MARK: Instance Methods

	required public init()
	{
	}

	// MARK: Business Logic
	override public func setProperty(name: String, value: Any?)
	{
		switch name
			{
			case "origin":
				origin = value as? String
			case "destination":
				destination = value as? String
			default:
				break
			}
	}
}
