/*
********************************************************************************
* IoGGQLManagerTests.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the GQLManager tests
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/26/22		*	EGC	*	File creation date
********************************************************************************
*/

import XCTest
@testable import IoGInfrastructure

class IoGGQLManagerTests: XCTestCase, IoGGQLManagerDelegate
{

	var callbackInvoked: Bool?
	var returnedData: Any?
	var returnedError: Error?
	var customRequestType: CustomGQLRequestType?

    override func setUpWithError() throws
	{
		super.setUp()
		callbackInvoked = nil
		returnedData = nil
		IoGGQLManager.sharedManager.registerDelegate(delegate: self)
    }

    override func tearDownWithError() throws
	{
		super.tearDown()
		IoGGQLManager.sharedManager.unregisterDelegate(delegate: self)
    }

	func testSuccessfulGQLObjectRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		let queryRequestID = IoGGQLManager.sharedManager.transmitTestQueryRequest(url: IoGTestConfigurationManager.gqlTestURL1, operationName: IoGTestConfigurationManager.gqlQueryName1, parameters: nil, type: .Version, target: FlightDetails.self, propertyParameters: nil)
		XCTAssertNotEqual(queryRequestID, -1)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData as? FlightDetails
						{
						if let flightID = data.flightID, let seats = data.seats, let pilot = data.pilot
							{
							let route = data.route
							let passengers = data.passenger
							if let passenger = passengers.first
								{
								XCTAssertEqual(flightID, IoGTestConfigurationManager.gqlQuery1FlightID)
								XCTAssertEqual(seats.intValue, IoGTestConfigurationManager.gqlQuery1Seats)
								XCTAssertEqual(pilot, IoGTestConfigurationManager.gqlQuery1Pilot)
								XCTAssertEqual(route?.origin, IoGTestConfigurationManager.gqlQuery1Origin)
								XCTAssertEqual(route?.destination, IoGTestConfigurationManager.gqlQuery1Destination)
								XCTAssertEqual(passengers.count, IoGTestConfigurationManager.gqlQuery1PassengerTotal)
								if passenger.name?.contains(IoGTestConfigurationManager.gqlQuery1PassengerLastName) == false
									{
									XCTFail()
									}
								}
							else
								{
								XCTFail()
								}
							}
						else
							{
							XCTFail()
							}
						}
					else
						{
						XCTFail()
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testSuccessfulGQLArrayRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		let queryRequestID = IoGGQLManager.sharedManager.transmitTestQueryRequest(url: IoGTestConfigurationManager.gqlTestURL2, operationName: IoGTestConfigurationManager.gqlQueryName2, parameters: "flightID = 2022", type: .Features, target: Flight.self, propertyParameters: nil)
		XCTAssertNotEqual(queryRequestID, -1)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData as? [Flight]
						{
						XCTAssertEqual(data.count, IoGTestConfigurationManager.gqlQuery2FlightTotal)
						XCTAssertNotNil(data.first?.flightID)
						XCTAssertNotNil(data.last?.seats)
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testFailedGQLDataRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		let queryRequestID = IoGGQLManager.sharedManager.transmitTestQueryRequest(url: IoGTestConfigurationManager.successURL1, operationName: IoGTestConfigurationManager.gqlQueryName1, parameters: nil, type: .Version, target: FlightDetails.self, propertyParameters: nil)
		XCTAssertNotEqual(queryRequestID, -1)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let _ = self.returnedData as? [Flight]
						{
						XCTFail()
						}
					else
						{
						if let data = self.returnedData as? Data
							{
							do
								{
								let jsonDict = try JSONSerialization.jsonObject(with: data, options: [])
								if let dataDictionary = jsonDict as? [String: Any]
									{
									if let error = dataDictionary[IoGConfigurationManager.requestResponseKeyError] as? Error
										{
										let nserror = error as NSError
										XCTAssertEqual(nserror.description, IoGConfigurationManager.gqlRequestResponseParsingErrorDescription)
										XCTAssertEqual(nserror.code, IoGConfigurationManager.gqlRequestResponseParsingErrorCode)
										}
									else
										{
										XCTFail()
										}
									}
								else
									{
									XCTFail()
									}
								}
							catch
								{
								XCTFail()
								}
							}
						else
							{
							if let error = self.returnedError
								{
								let nserror = error as NSError
								XCTAssertEqual(nserror.code, IoGConfigurationManager.gqlRequestResponseParsingErrorCode)
								}
							else
								{
								XCTFail()
								}
							}
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testCustomTypeGQLObjectRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		let propertyParameters = ["passenger": "page: 1, limit: 10"]
		let queryRequestID = IoGGQLManager.sharedManager.transmitTestQueryRequest(url: IoGTestConfigurationManager.gqlTestURL1, name: IoGTestConfigurationManager.gqlQueryName1, parameters: nil, customTypeIdentifier: IoGTestConfigurationManager.dataRequestCustomType, target: FlightDetails.self, propertyParameters: [propertyParameters])
		XCTAssertNotEqual(queryRequestID, -1)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData as? FlightDetails
						{
						if let flightID = data.flightID, let seats = data.seats, let pilot = data.pilot
							{
							let route = data.route
							let passengers = data.passenger
							if let passenger = passengers.first
								{
								XCTAssertEqual(flightID, IoGTestConfigurationManager.gqlQuery1FlightID)
								XCTAssertEqual(seats.intValue, IoGTestConfigurationManager.gqlQuery1Seats)
								XCTAssertEqual(pilot, IoGTestConfigurationManager.gqlQuery1Pilot)
								XCTAssertEqual(route?.origin, IoGTestConfigurationManager.gqlQuery1Origin)
								XCTAssertEqual(route?.destination, IoGTestConfigurationManager.gqlQuery1Destination)
								XCTAssertEqual(passengers.count, IoGTestConfigurationManager.gqlQuery1PassengerTotal)
								XCTAssertEqual(self.customRequestType, IoGTestConfigurationManager.dataRequestCustomType)
								XCTAssertNotNil(self.customRequestType)
								if passenger.name?.contains(IoGTestConfigurationManager.gqlQuery1PassengerLastName) == false
									{
									XCTFail()
									}
								}
							else
								{
								XCTFail()
								}
							}
						else
							{
							XCTFail()
							}
						}
					else
						{
						XCTFail()
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}
	
	func testSuccessfulGQLObjectMutation()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		// First, retrieve a GQL object
		let queryRequestID = IoGGQLManager.sharedManager.transmitTestQueryRequest(url: IoGTestConfigurationManager.gqlTestURL1, operationName: IoGTestConfigurationManager.gqlQueryName1, parameters: nil, type: .Version, target: FlightDetails.self, propertyParameters: nil)
		XCTAssertNotEqual(queryRequestID, -1)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData as? FlightDetails
						{
						// Then, mutate the GQL object
						self.callbackInvoked = false
						self.returnedData = nil
						self.returnedError = nil
						self.customRequestType = nil
						data.setProperty(propertyName: "pilot", value: IoGTestConfigurationManager.gqlMutationPilot)
						let mutationRequestID = IoGGQLManager.sharedManager.transmitTestMutationRequest(url: IoGTestConfigurationManager.gqlTestURL3, name: IoGTestConfigurationManager.gqlMutationName1, customTypeIdentifier: IoGTestConfigurationManager.dataRequestCustomType, target: data, returnType: FlightDetails.self, returnTypePropertyParameters: nil)
						XCTAssertNotEqual(mutationRequestID, -1)
						Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
							{
							timer in
							if let calledBack = self.callbackInvoked
								{
								if calledBack
									{
									if let data = self.returnedData as? FlightDetails
										{
										if let flightID = data.flightID, let seats = data.seats, let pilot = data.pilot
											{
											let route = data.route
											let passengers = data.passenger
											if let passenger = passengers.first
												{
												XCTAssertEqual(flightID, IoGTestConfigurationManager.gqlQuery1FlightID)
												XCTAssertEqual(seats.intValue, IoGTestConfigurationManager.gqlQuery1Seats)
												XCTAssertEqual(pilot, IoGTestConfigurationManager.gqlMutationPilot)
												XCTAssertEqual(route?.origin, IoGTestConfigurationManager.gqlQuery1Origin)
												XCTAssertEqual(route?.destination, IoGTestConfigurationManager.gqlQuery1Destination)
												XCTAssertEqual(passengers.count, IoGTestConfigurationManager.gqlQuery1PassengerTotal)
												if passenger.name?.contains(IoGTestConfigurationManager.gqlQuery1PassengerLastName) == false
													{
													XCTFail()
													}
												}
											else
												{
												XCTFail()
												}
											}
										else
											{
											XCTFail()
											}
										}
									else
										{
										XCTFail()
										}
									callbackExpectation.fulfill()
									}
								}
							}
						}
					else
						{
						XCTFail()
						}
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.gqlMutationExpirationCheckTimeout, handler: nil)
	}

	func testFailedGQLObjectMutation()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		// First, retrieve a GQL object
		let queryRequestID = IoGGQLManager.sharedManager.transmitTestQueryRequest(url: IoGTestConfigurationManager.gqlTestURL1, operationName: IoGTestConfigurationManager.gqlQueryName1, parameters: nil, type: .Version, target: FlightDetails.self, propertyParameters: nil)
		XCTAssertNotEqual(queryRequestID, -1)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData as? FlightDetails
						{
						// Then, mutate the GQL object
						self.callbackInvoked = false
						self.returnedData = nil
						self.returnedError = nil
						self.customRequestType = nil
						let mutationRequestID = IoGGQLManager.sharedManager.transmitTestMutationRequest(url: IoGTestConfigurationManager.gqlTestURL3, name: IoGTestConfigurationManager.gqlMutationName1, customTypeIdentifier: IoGTestConfigurationManager.dataRequestCustomType, target: data, returnType: FlightDetails.self, returnTypePropertyParameters: nil)
						XCTAssertNotEqual(mutationRequestID, -1)
						Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
							{
							timer in
							if let calledBack = self.callbackInvoked
								{
								if calledBack
									{
									if let data = self.returnedData as? FlightDetails
										{
										if let flightID = data.flightID, let seats = data.seats, let pilot = data.pilot
											{
											let route = data.route
											let passengers = data.passenger
											if let passenger = passengers.first
												{
												XCTAssertEqual(flightID, IoGTestConfigurationManager.gqlQuery1FlightID)
												XCTAssertEqual(seats.intValue, IoGTestConfigurationManager.gqlQuery1Seats)
												XCTAssertEqual(pilot, IoGTestConfigurationManager.gqlQuery1Pilot)
												XCTAssertEqual(route?.origin, IoGTestConfigurationManager.gqlQuery1Origin)
												XCTAssertEqual(route?.destination, IoGTestConfigurationManager.gqlQuery1Destination)
												XCTAssertEqual(passengers.count, IoGTestConfigurationManager.gqlQuery1PassengerTotal)
												if passenger.name?.contains(IoGTestConfigurationManager.gqlQuery1PassengerLastName) == false
													{
													XCTFail()
													}
												}
											else
												{
												XCTFail()
												}
											}
										else
											{
											XCTFail()
											}
										}
									else
										{
										XCTFail()
										}
									callbackExpectation.fulfill()
									}
								}
							}
						}
					else
						{
						XCTFail()
						}
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.gqlMutationExpirationCheckTimeout, handler: nil)
	}

	// GQL Manager Delegate method(s)

	func gqlRequestResponseReceived(requestID: Int, requestType: IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: CustomGQLRequestType?, responseData: Any?, error: Error?)
	{
		callbackInvoked = true
		returnedData = responseData
		returnedError = error
		customRequestType = customRequestIdentifier
	}
}
