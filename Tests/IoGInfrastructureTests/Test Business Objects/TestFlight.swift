/*
********************************************************************************
* TestFlight.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the sample GQL Flight Summary object
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/27/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation
@testable import IoGInfrastructure

class Flight : IoGGQLDataObject
{

	var flightID: String? = ""
	var seats: NSNumber? = 0
	var route: Route? = Route.init()

	// MARK: Instance Methods

	required public init()
	{
	}

	// MARK: Business Logic
	override public func setProperty(propertyName: String, value: Any?)
	{
		switch propertyName
			{
			case "flightID":
				flightID = value as? String
			case "seats":
				seats = value as? NSNumber
			case "route":
				route = value as? Route
			default:
				break
			}
	}

	override public func clearArray(propertyName: String)
	{
	}
}
