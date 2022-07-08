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
	var name: String? = ""
	var age: NSNumber? = 0
	var dependent: [Dependent] = [Dependent.init()]

	// MARK: Instance Methods

	required public init()
	{
	}

	// MARK: Business Logic
	override public func setProperty(propertyName: String, value: Any?)
	{
		switch propertyName
			{
			case "passengerID":
				passengerID = value as? String
			case "name":
				name = value as? String
			case "age":
				age = value as? NSNumber
			case "dependent":
				dependent = value as! [Dependent]
			default:
				break
			}
	}

	override public func clearArray(propertyName: String)
	{
		switch propertyName
			{
			case "dependent":
				self.dependent.removeAll()
			default:
				break
			}
	}
}

