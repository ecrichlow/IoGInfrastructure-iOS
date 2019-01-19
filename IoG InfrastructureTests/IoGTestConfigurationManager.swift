//
//  IoGTestConfigurationManager.swift
//  IoG InfrastructureTests
//
//  Created by Eric Crichlow on 11/11/18.
//  Copyright © 2018 Infusions of Grandeur. All rights reserved.
//

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
	static let dataRequestFastResponseCheck = 0.5 as TimeInterval
	static let dataRequestSlowResponseCheck = 7 as TimeInterval
	static let dataTestExpirationCheckTimeout = 10 as TimeInterval

	// Data Parsing
	static let parsingObjectData = "{\"model\":\"TRS-80 Color Computer 2\", \"processor\":\"6809\", \"year\":\"1980\"}"
	static let parsingObjectArrayData = "[{\"model\":\"TRS-80 Color Computer 2\", \"processor\":\"6809\", \"year\":\"1980\"}, {\"model\":\"TRS-80 Color Computer 3\", \"processor\":\"68B09E\", \"year\":\"1986\"}, {\"model\":\"MM/1\", \"processor\":\"68070\", \"year\":\"1990\"}]"

	static let sharedManager = IoGTestConfigurationManager()

	init()
	{
	}
}
