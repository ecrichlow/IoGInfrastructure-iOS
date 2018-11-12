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

	static let sharedManager = IoGTestConfigurationManager()

	init()
	{
	}
}
