/*
********************************************************************************
* IoGConfigurationManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for framework
*						configuration
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	05/05/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for multiple API URLs
********************************************************************************
*/

import Foundation

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
	static let mockSlowResponseIndicator = "/3"
	static let mockSuccessfulCallIndicator = "www.success.com"
	static let mockFailedCallIndicator = "www.failure.com"
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

	public static let sharedManager = IoGConfigurationManager()

	private var sessionActive = false

// 02-16-22 - EGC - Deprecated single API URL in favor of an array of supported URLs
//	private var currentAPIURL : String
	private var APIURLs = [String]()

	init()
	{
// 02-16-22 - EGC - Deprecated single API URL in favor of an array of supported URLs
//		currentAPIURL = "http://"
	}

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

	public func setSessionActive(state: Bool)
	{
		sessionActive = state
		if state == false
			{
			IoGPersistenceManager.sharedManager.removeSessionItems()
			}
	}

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
	public func addAPIURL(address: String)
	{
		APIURLs.append(address)
	}

	public func getAPIURLStrings() -> [String]
	{
		return APIURLs
	}

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
