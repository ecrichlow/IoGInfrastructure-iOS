/*******************************************************************************
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
*******************************************************************************/

import Foundation

class IoGConfigurationManager
{
	// Persistence Manager
	static let persistencElementValue = "Value"
	static let persistencElementType = "Type"
	static let persistencElementSource = "Source"
	static let persistencElementProtection = "Protection"
	static let persistencElementLifespan = "Lifespan"
	static let persistencElementExpiration = "Expiration"
	static let persistenceManagementExpiringItems = "ExpiringItems"
	static let persistenceManagementSessionItems = "SessionItems"
	static let persistenceExpirationItemName = "ExpiringItemName"
	static let persistenceExpirationItemType = "ExpiringItemType"
	static let persistenceExpirationItemExpirationDate = "ExpiringItemExpirationDate"
	static let timerPeriodPersistenceExpirationCheck = 60.0

	// Data Manager
	static let defaultDataManagerType = DataManager.DataManagerType.DataManagerTypeLive
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

	static let sharedManager = IoGConfigurationManager()

	private var sessionActive = false

	private var currentAPIURL : String

	init()
	{
		currentAPIURL = "http://"
	}

	func setSessionActive(state: Bool)
	{
		sessionActive = state
		if state == false
			{
			IoGPersistenceManager.sharedManager.removeSessionItems()
			}
	}

	func getSessionActive() -> Bool
	{
		return sessionActive
	}

	func setAPIURL(address: String)
	{
		currentAPIURL = address
	}

	func getAPIURLString() -> String
	{
		return currentAPIURL
	}

	func getAPIURL() -> URL?
	{
		return URL(string: currentAPIURL)
	}

}
