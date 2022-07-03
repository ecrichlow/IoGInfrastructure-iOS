/*
********************************************************************************
* TestPassenger.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the sample GQL Passenger object
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/27/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation
@testable import IoGInfrastructure

class Passenger: IoGGQLDataObject
{
	var passengerID: String? = ""
	var passengerName: String? = ""
	var age: NSNumber? = 0
	var dependent: [Dependent]? = [Dependent.init()]

	// MARK: Instance Methods

	required public init()
	{
	}

	// MARK: Business Logic
	override public func setProperty(name: String, value: Any?)
	{
		switch name
			{
			case "passengerID":
				passengerID = value as? String
			case "passengerName":
				passengerName = value as? String
			case "age":
				age = value as? NSNumber
			case "dependent":
				dependent = value as? [Dependent]
			default:
				break
			}
	}
}

