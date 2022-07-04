/*
********************************************************************************
* TestFlightDetails.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the sample GQL Flight Details object
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/27/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation
@testable import IoGInfrastructure

class FlightDetails : IoGGQLDataObject
{
	var flightID: String? = ""
	var seats: NSNumber? = 0
	var route: Route = Route.init()
	var passenger: [Passenger] = [Passenger.init()]
	var pilot: String? = ""

	// MARK: Instance Methods

	required public init()
	{
	}

	// MARK: Business Logic

	override public func setProperty(name: String, value: Any?)
	{
		switch name
			{
			case "flightID":
				flightID = value as? String
			case "seats":
				seats = value as? NSNumber
			case "route":
				route = value as! Route
			case "passenger":
				passenger = value as! [Passenger]
			case "pilot":
				pilot = value as? String
			default:
				break
			}
	}
}
