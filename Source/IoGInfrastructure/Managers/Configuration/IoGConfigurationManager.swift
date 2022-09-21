/*
********************************************************************************
* IoGConfigurationManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for framework
*						configuration
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	05/05/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for multiple API URLs and secure
*								storage
*	06/18/22		*	EGC	*	Added DocC support
********************************************************************************
*/

import Foundation
import CryptoKit

/// Singleton class that controls the configuration of the IoG Infrastructure Framework.
public class IoGConfigurationManager
{
	// Persistence Manager
	static let persistenceFolderPath = "/Documents/IoGPersistence"
	static let persistencElementValue = "Value"
	static let persistencElementType = "Type"
	static let persistencElementSource = "Source"
	static let persistencElementProtection = "Protection"
	static let persistencElementLifespan = "Lifespan"
	static let persistencElementExpiration = "Expiration"
	static let persistenceManagementExpiringItems = "ExpiringItems"
	static let persistenceManagementSessionItems = "SessionItems"
	static let persistenceExpirationItemName = "ExpiringItemName"
	static let persistenceExpirationItemSource = "ExpiringItemSource"
	static let persistenceExpirationItemExpirationDate = "ExpiringItemExpirationDate"
	static let timerPeriodPersistenceExpirationCheck = 60.0

	// Data Manager
	static let defaultDataManagerType = IoGDataManager.IoGDataManagerType.IoGDataManagerTypeLive
	static let defaultRequestTimeoutDelay = 10 as TimeInterval
	static let defaultRequestNumRetries = 3
	static let requestResponseKeyRequest = "Request"
	static let requestResponseKeyRequestType = "RequestType"
	static let requestResponseKeyCallback = "Callback"
	static let requestResponseKeyError = "Error"
	static let requestResponseKeyResponse = "Response"
	static let requestResponseTimeoutErrorDescription = "HTTP Timeout Error"
	static let requestResponseTimeoutErrorCode = 408
	static let requestResponseGeneralErrorDescription = "HTTP Request Returned Error"
	static let requestResponseGeneralErrorCode = 400
	static let httpHeaderKeyAcceptLanguage = "Accept-Language"
	static let httpHeaderKeyContentType = "Content-Type"
	static let httpHeaderKeyUserAgent = "User-Agent"
	static let httpHeaderDefaultAcceptLanguage = "en;q=1"
	static let httpHeaderDefaultContentType = "application/json"
	static let httpHeaderDeviceNameKey = "DTPlatformName"
	static let httpHeaderDeviceOSVersionKey = "DTPlatformVersion"
	static let httpHeaderAppNameKey = "CFBundleExecutable"
	static let httpHeaderAppMajorVersionKey = "CFBundleShortVersionString"
	static let httpHeaderAppMinorVersionKey = "CFBundleVersion"
	static let mockFastDataRequestResponseTime = 0.1 as TimeInterval
	static let mockSlowDataRequestResponseTime = 5 as TimeInterval
	static let mockResponseIndicator1 = "/1"
	static let mockResponseIndicator2 = "/2"
	static let mockResponseIndicator3 = "/3"
	static let mockSlowResponseIndicator = "www.success.com/3"
	static let mockSuccessfulCallIndicator = "www.success.com"
	static let mockFailedCallIndicator = "www.failure.com"
	static let mockGQLCallIndicator = "www.iogtests.com/graphql"
	static let mockDataResponse1 = "{\"Generation\":\"1\", \"Computers\":[\"Color Computer 2\", \"Color Computer 3\", \"MM/1\"], \"Manufacturer\":null, \"Conventions\":\"Rainbowfest\"}"
	static let mockDataResponse2 = "{\"Generation\":\"2\", \"Computers\":[\"Mac Performa 6400\", \"Powerbook G4\", \"Power Mac G4\", \"iMac\", \"Macbook Pro\"], \"Manufacturer\":\"Apple\"}"

	// Retry Manager
	static let retryItemFieldLifespan = "Lifespan"
	static let retryItemFieldRetryMaxCount = "Retries"
	static let retryItemFieldRetryCurrentCount = "RetryNumber"
	static let retryItemFieldExpiration = "Expiration"
	static let retryItemFieldTimeLimit = "TimeLimit"
	static let retryItemFieldRoutine = "Routine"
	static let retryItemFieldIdentifier = "Identifier"

	// Encryption Manager
	static let symmetricKeySize = SymmetricKeySize.bits256
	static let symmetricKeyIdentifier = "com.iog.symmetrickey"

	// Data Object Manager
	static let dataParsingRawStringKey = "rawString"

	// GQL Manager
	static let gqlManagerCustomDataManagerType: CustomDataRequestType = "GQLDataRequestType"
	static let gqlRequestKeyDataRequestID = "DataRequestID"
	static let gqlRequestKeyRequestType = "RequestType"
	static let gqlRequestKeyCustomRequestType = "CustomRequestType"
	static let gqlRequestKeyTargetType = "TargetType"
	static let gqlRequestKeyReturnTargetType = "ReturnTargetType"
	static let gqlRequestKeyTestMutationName = "TestMutationName"
	static let gqlRequestKeyTestMutationString = "TestMutationString"
	static let gqlRequestResponseParsingErrorDescription = "GraphQL Response Parsing Error"
	static let gqlRequestResponseParsingErrorCode = 9999
	static let mockGQLQueryResponse1 =
"""
{
	"data" : {
		"flightID": "1272",
		"seats": 168,
		"route": {
		   "origin": "LAS",
		   "destination": "PHX"
		},
		"passenger": [
			{
				"passengerID": "1",
				"name": "Trista Crichlow",
				"age": 36,
				"dependent": [
					{
						"passengerID": "4",
						"name": "Carson Crichlow",
						"age": 11
					},
					{
						"passengerID": "5",
						"name": "Kinsey Crichlow",
						"age": 5
					}
				]
			},
			{
				"passengerID": "2",
				"name": "Haylie Crichlow",
				"age": 29
			},
			{
				"passengerID": "3",
				"name": "Timara Crichlow",
				"age": 23
			},
			{
				"passengerID": "4",
				"name": "Carson Crichlow",
				"age": 11
			},
			{
				"passengerID": "5",
				"name": "Kinsey Crichlow",
				"age": 5
			}
		],
		"pilot": "Eric Crichlow"
	}
}
"""
	static let mockGQLQueryResponse2 =
"""
	"data" : {
		"flights": [
			{
				"flightID": "1272",
				"seats": 168,
				"route": {
					"origin": "LAS",
					"destination": "PHX"
				}
			},
			{
				"flightID": "121985",
				"seats": 158,
				"route": {
					"origin": "PHX",
					"destination": "CMH"
				}
			},
			{
				"flightID": "6809",
				"seats": 180,
				"route": {
					"origin": "SEA",
					"destination": "LAS"
				}
			},
		]
	}
"""

	/// Returns the shared Configuration Manager instance.
	public static let sharedManager = IoGConfigurationManager()

	private var sessionActive = false

// 02-16-22 - EGC - Deprecated single API URL in favor of an array of supported URLs
//	private var currentAPIURL : String
	private var APIURLs = [String]()

	// MARK: Instance Methods

	/// Default Initializer
	init()
	{
// 02-16-22 - EGC - Deprecated single API URL in favor of an array of supported URLs
//		currentAPIURL = "http://"
	}

	// MARK: Business Logic

	/// Check the version of IoGInfrastructure in use in the application
	///
	///  - Returns: The version number of the framework in use
	public func getVersion() -> String
	{
		let infoDictionary = Bundle.main.infoDictionary
		if let version = infoDictionary!["CFBundleShortVersionString"] as? String
			{
			return version
			}
		else
			{
			return "Unknown"
			}
	}

	/// Toggle the state of the session
	///
	/// The Persistence Manager has an option to set the lifetime of a stored value to end when the session ends.
	/// This method is used to set the state of the session.
	///
	/// > Note: The default state of the session is off
	///
	///  - Parameters:
	///		- state: The new state of the session
	public func setSessionActive(state: Bool)
	{
		sessionActive = state
		if state == false
			{
			IoGPersistenceManager.sharedManager.removeSessionItems()
			}
	}

	/// Check the session state
	///
	/// - Returns: The current state of the session
	public func getSessionActive() -> Bool
	{
		return sessionActive
	}

// 02-16-22 - EGC - Deprecated single API URL in favor of an array of supported URLs
/*
	public func setAPIURL(address: String)
	{
		currentAPIURL = address
	}

	public func getAPIURLString() -> String
	{
		return currentAPIURL
	}

	public func getAPIURL() -> URL?
	{
		return URL(string: currentAPIURL)
	}
*/

	/// Adds a base URL to the list of supported base URLs
	///
	/// Server authentication can request verification of the server being accessed. Only requests from servers with addresses listed
	/// in the saved list of API URLs are authenticated.
	///
	/// - Parameters:
	/// 	- address: The base URL to add to the authorized list, as a string
	public func addAPIURL(address: String)
	{
		var found = false

		for url in APIURLs
		{
			if url == address
			{
				found = true
				break
			}
		}
		if !found
		{
			APIURLs.append(address)
		}
	}

	/// Retrieve the list of supported base URLs
	///
	/// - Returns: a list of strings that make up the list of registered base URLs
	public func getAPIURLStrings() -> [String]
	{
		return APIURLs
	}

	/// Retrieve the list of supported base URLs
	///
	/// - Returns: a list of URLs that make up the list of registered base URLs
	public func getAPIURLs() -> [URL]
	{
		var urlList = [URL]()
		for nextURLString in APIURLs
			{
			if let url = URL(string: nextURLString)
				{
				urlList.append(url)
				}
			}
		return urlList
	}

}
