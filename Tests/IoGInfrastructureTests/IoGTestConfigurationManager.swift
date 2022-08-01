/*
********************************************************************************
* IoGTestConfigurationManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for test configuration
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	11/11/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for encryption tests and version 2
*								enhancement tests
*	06/26/22		*	EGC	*	Addition of GraphQL management tests
********************************************************************************
*/

import Foundation

class IoGTestConfigurationManager
{
	// Persistence Manager Test Data
	static let persistenceFolderPath = "/Documents/IoGPersistence"
	static let persistenceTestSaveName = "TestIdentifier"
	static let persistenceTestInvalidSaveName = "TestIdentifier"
	static let persistenceTestNumericValue = 42
	static let persistenceTestStringValue = "Forty Two"
	static let persistenceTestSecondaryStringValue = "Nineteen Eighty Nine"
	static let persistenceTestArrayValue = ["Infusions", "Of", "Grandeur"]
	static let persistenceTestDictionaryValue = ["NumericValue": 42, "StringValue": "IoG"] as [String : Any]
	static let persistenceTestExpiration = (2 * 60) as TimeInterval
	static let persistenceTestExpirationCheck = (3 * 60) as TimeInterval
	static let persistenceTestExpirationCheckTimeout = (4 * 60) as TimeInterval

	// Retry Manager Test Data
	static let retryTestExpiration = 8.0
	static let preExpiration = retryTestExpiration - 2.0
	static let retryTestExpirationCheckTimeout = 30.0
	static let infiniteRetryTestExpirationCheckTimeout = 120.0
	static let retryDelay = 1.0
	static let decoyRetryDelay = 0.5
	static let retryCallbackDelay = 1.0
	static let decoyMaxCount = 3
	static let decoyRetrySuccessIteration = 4
	static let maxCount = 12
	static let retrySuccessIteration = 6
	static let infiniteRetrySuccessIteration = 99

	// Data Manager Test Data
	static let successURL1 = "http://www.success.com/1"
	static let successURL2 = "http://www.success.com/2"
	static let successURL1Slow = "http://www.success.com/3"
	static let failureURL1 = "http://www.failure.com/1"
	static let failureURLSlow = "http://www.failure.com/2"
	static let secondaryURL = "http://www.alternate.com"
	static let dataRequestFastResponseCheck = 0.5 as TimeInterval
	static let dataRequestSlowResponseCheck = 7 as TimeInterval
	static let dataTestExpirationCheckTimeout = 10 as TimeInterval
	static let dataRequestCustomType = "CustomTypeTestX"

	// Data Parsing
	static let parsingObjectData = "{\"model\":\"TRS-80 Color Computer 2\", \"processor\":\"6809\", \"year\":\"1980\"}"
	static let parsingObjectArrayData = "[{\"model\":\"TRS-80 Color Computer 2\", \"processor\":\"6809\", \"year\":\"1980\"}, {\"model\":\"TRS-80 Color Computer 3\", \"processor\":\"68B09E\", \"year\":\"1986\"}, {\"model\":\"MM/1\", \"processor\":\"68070\", \"year\":\"1990\"}]"

	// Encryption
	static let stringToEncrypt = "Test encryption string"

	// GraphQL Manager
	static let gqlTestURL1 = "http://www.iogtests.com/graphql/1"
	static let gqlTestURL2 = "http://www.iogtests.com/graphql/2"
	static let gqlTestURL3 = "http://www.iogtests.com/graphql/3"
	static let gqlQueryName1 = "ObjectRequest"
	static let gqlQueryName2 = "ArrayRequest"
	static let gqlMutationName1 = "mutationChangePilot"
	static let gqlQuery1FlightID = "1272"
	static let gqlQuery1Seats = 168
	static let gqlQuery1Pilot = "Eric Crichlow"
	static let gqlQuery1Origin = "LAS"
	static let gqlQuery1Destination = "PHX"
	static let gqlQuery1PassengerTotal = 5
	static let gqlQuery1PassengerLastName = "Crichlow"
	static let gqlQuery2FlightTotal = 3
	static let gqlMutationPilot = "Ric Gerard"

	static let sharedManager = IoGTestConfigurationManager()

	init()
	{
	}
}
