/*
********************************************************************************
* IoGDataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the base class for the manager for
*						retrieving remote data
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	09/27/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for custom request type
*	06/19/22		*	EGC	*	Added DocC support
*	12/17/24		*	EGC	*	Added support for customizing retry logic
*	08/14/25		*	EGC	*	Added support for thread safety
*	07/23/26		*	EGC	*	Replaced NSPointerArray with NSHashTable for
*								delegate list
 *	08/10/26		*	EGC	*	Copilot added support for multipart/form-data
********************************************************************************
*/

import Foundation

/// Protocol the delegates of the Data Manager must conform to in order to be notified of the final status of
/// a URLRequest
public protocol IoGDataManagerDelegate : AnyObject
{
	func dataRequestResponseReceived(requestID: Int, requestType: IoGDataManager.IoGDataRequestType, responseData: Data?, error: Error?, response: IoGDataRequestResponse)
}

public typealias CustomDataRequestType = String

/// Base class that manages back end communications
///
/// > Note: Clients of IogInfrastructure do not directly instantiate this class. There is a Mock subclass used strictly for
/// testing. Clients should call the class method dataManagerOfDefaultType to get the "live" subclass.
public class IoGDataManager
{

	/// The subclass type of the Data Manager to instantiate
	public enum IoGDataManagerType
	{
		/// The Live Data Manager, used by clients
		case IoGDataManagerTypeLive
		/// The Mock Data Manager, used for testing
		case IoGDataManagerTypeMock
	}

	/// The request type, which is an identifier used by clients to differentiate between responses in the delegate method
	public enum IoGDataRequestType
	{
		case Custom
		case Register
		case Login
		case Logout
		case ResetPassword
		case UserInfo
		case UpdateUserInfo
		case Features
		case Version
		case Analytics
		case Score
		case Catalog
		case Charge
		case Purchase
		case Cart
		case Extra
		case Station
		case Vehicle
		case Block
		case Chat
		case Customer
		case Admin
		case Video
		case Audio
		case Unregister
		case Delete
		case Selections
		case Location
		case Profile
		case Shop
		case Receipt
		case Store
		case Department
		case Category
		case Image
		case Thumbnail
		case Gallery
		case Price
		case Offer
		case Discount
		case Address
		case Contact
		case Lookup
		case Save
		case Open
		case Close
		case Time
		case Schedule
		case Service
		case Order
		case Log
		case Diagnostics
		case Notification
		case Alert
		case Event
		case Map
		case Route
		case Lock
		case Unlock
		case Transfer
		case Upload
		case Download
		case Send
		case Receive
		case Directory
		case Verify
		case List
		case Trip
		case Details
		case Pass
		case Cancel
		case Confirm
		case Comment
		case Rating
		case Search
		case Info
		case Validate
		case Flight
		case Seat
		case Date
		case Token
		case Authenticate
		case Authorization
		case Permissions
		case Secret
		case Settings
		case Account
		case Claim
		case Resource
		case Task
		case Reminder
		case Link
		case Theme
		case Language
		case Policy
		case Terms
		case Privacy
		case Report
		case Post
		case Defaults
		case Team
		case Member
		case Project
		case Book
		case Confirmation
		case Accessories
		case Scheme
		case Data
		case Storage
		case Cache
		case Form
		case Calendar
		case Submit
		case Assignment
		case Web
		case Page
		case Manage
		case Manager
		case Dictionary
		case App
		case Configuration
		case Revert
		case Retry
		case Build
		case Erase
	}

	/// Returns the shared Data Manager instance.
	private static var sharedManager : IoGDataManager!

	var delegateList = NSHashTable<AnyObject>.weakObjects()
	var outstandingRequests = [Int: IoGDataRequestResponse]()
	var requestID = 0
	var retryOnFailure = true
	var numAutoRetries = IoGConfigurationManager.defaultRequestNumRetries
	internal let processingQueue = DispatchQueue(label: IoGConfigurationManager.processingQueueIdentifier)

	// MARK: Class Methods

	/// Retrieve an instance of the Data Manager
	///
	///  - Parameters:
	///   - type: The type of Data Manager to return, Mock or Live
	///
	///	- Returns: A Data Manager instance of the requested type
	public class func dataManagerOfType(type: IoGDataManagerType) -> IoGDataManager
	{
		switch (type)
			{
			case .IoGDataManagerTypeLive:
// 06-19-22 - EGC - Changed sharedManager to instantiate a dataManager of the default type
//				if sharedManager == nil || !(sharedManager is IoGLiveDataManager)
				if !(sharedManager is IoGLiveDataManager)
					{
					sharedManager = IoGLiveDataManager()
					}
			case .IoGDataManagerTypeMock:
// 06-19-22 - EGC - Changed sharedManager to instantiate a dataManager of the default type
//				if sharedManager == nil || !(sharedManager is IoGMockDataManager)
				if !(sharedManager is IoGMockDataManager)
					{
					sharedManager = IoGMockDataManager()
					}
			}
		return sharedManager
	}

	/// Retrieve an instance of the Data Manager
	///
	///  - Returns: An instance of the Data Manager of the default type
	public class func dataManagerOfDefaultType() -> IoGDataManager
	{
		return IoGDataManager.dataManagerOfType(type: IoGConfigurationManager.defaultDataManagerType)
	}

	// MARK: Instance Methods

	init()
	{
	}

	// MARK: Business Logic

	/// Register a delegate to receive a callback when the data operation completes
	/// - Parameters:
	///   - delegate: object conforming to IoGDataManagerDelegate protocol that requests to be called when data operations complete
	public func registerDelegate(delegate: IoGDataManagerDelegate)
	{
		guard !delegateList.contains(delegate as AnyObject) else { return }
		delegateList.add(delegate as AnyObject)
	}

	/// Unregister a delegate from receiving a callback when the data operation completes
	/// - Parameters:
	///   - delegate: object conforming to IoGDataManagerDelegate protocol that requests to stop being called when data operations complete
	public func unregisterDelegate(delegate: IoGDataManagerDelegate)
	{
		delegateList.remove(delegate as AnyObject)
	}

	/// Sets whether or not to automatically retry on failed requests
	/// - Parameters:
	///   - retry: whether or not to attempt automatic retries
	public func setRetryOnFailure(retry: Bool)
	{
		retryOnFailure = retry
	}

	func getRetryOnFailure() -> Bool
	{
		return retryOnFailure
	}

	/// Sets the number of retries to automatically attempt on request failure
	/// - Parameters:
	///   - retries: the number of times to automatically retry a failed attempt
	public func setNumberOfRetries(retries: Int)
	{
		numAutoRetries = retries
	}

	func getNumberofRetries() -> Int
	{
		return numAutoRetries
	}

	@discardableResult public func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int
	{
		return 0
	}

	@discardableResult public func transmitRequest(request: URLRequest, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		return 0
	}

	/// Build and send a `multipart/form-data` POST request.
	///
	/// - Parameters:
	///   - url: The endpoint URL.
	///   - formData: An ``IoGMultipartFormData`` containing all fields and file parts.
	///   - type: One of the pre-defined identifiers used by delegates to differentiate the kind of request.
	///
	/// - Returns: An identifier for the request.
	@discardableResult public func transmitMultipartRequest(url: URL, formData: IoGMultipartFormData, type: IoGDataRequestType) -> Int
	{
		return transmitRequest(request: formData.buildRequest(url: url), type: type)
	}

	/// Build and send a `multipart/form-data` POST request with a custom type identifier.
	///
	/// - Parameters:
	///   - url: The endpoint URL.
	///   - formData: An ``IoGMultipartFormData`` containing all fields and file parts.
	///   - customTypeIdentifier: A custom identifier used by delegates to differentiate the kind of request.
	///
	/// - Returns: An identifier for the request.
	@discardableResult public func transmitMultipartRequest(url: URL, formData: IoGMultipartFormData, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		return transmitRequest(request: formData.buildRequest(url: url), customTypeIdentifier: customTypeIdentifier)
	}

	/// Build and send a `multipart/form-data` POST request with additional HTTP headers.
	///
	/// - Parameters:
	///   - url: The endpoint URL.
	///   - formData: An ``IoGMultipartFormData`` containing all fields and file parts.
	///   - headers: Additional HTTP header fields to set on the request (e.g. auth cookies).
	///   - type: One of the pre-defined identifiers used by delegates to differentiate the kind of request.
	///
	/// - Returns: An identifier for the request.
	@discardableResult public func transmitMultipartRequest(url: URL, formData: IoGMultipartFormData, headers: [String: String]?, type: IoGDataRequestType) -> Int
	{
		return transmitRequest(request: formData.buildRequest(url: url, headers: headers), type: type)
	}

	/// Build and send a `multipart/form-data` POST request with additional HTTP headers and a custom type identifier.
	///
	/// - Parameters:
	///   - url: The endpoint URL.
	///   - formData: An ``IoGMultipartFormData`` containing all fields and file parts.
	///   - headers: Additional HTTP header fields to set on the request (e.g. auth cookies).
	///   - customTypeIdentifier: A custom identifier used by delegates to differentiate the kind of request.
	///
	/// - Returns: An identifier for the request.
	@discardableResult public func transmitMultipartRequest(url: URL, formData: IoGMultipartFormData, headers: [String: String]?, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		return transmitRequest(request: formData.buildRequest(url: url, headers: headers), customTypeIdentifier: customTypeIdentifier)
	}

	public func cancelRequest(targetRequestID: Int)
	{
	}

	/// Execute data request for the next page of data in a multi-page request
	///
	/// > Note: For multi-page requests, the client must manually modify the URLRequest string to properly request the next page
	public func continueMultiPartRequest(multiPartResponse: IoGDataRequestResponse)
	{
		multiPartResponse.continueMultiPartRequest()
	}

	// MARK: Data Request Callback

	func dataRequestResponse(_ response: IoGDataRequestResponse)
	{
		let reqID = response.requestID
		for nextDelegate in delegateList.allObjects
			{
			if let delegate = nextDelegate as? IoGDataManagerDelegate
				{
				let responseData = response.responseData
				if let responseInfo = response.responseInfo, let err = responseInfo[IoGConfigurationManager.requestResponseKeyError] as? Error
					{
					delegate.dataRequestResponseReceived(requestID: response.requestID, requestType: response.getRequestInfo()[IoGConfigurationManager.requestResponseKeyRequestType] as! IoGDataManager.IoGDataRequestType, responseData: responseData, error: err, response: response)
					}
				else
					{
					delegate.dataRequestResponseReceived(requestID: response.requestID, requestType: response.getRequestInfo()[IoGConfigurationManager.requestResponseKeyRequestType] as! IoGDataManager.IoGDataRequestType, responseData: responseData, error: nil, response: response)
					}
				}
			}
		processingQueue.sync {
			if outstandingRequests[reqID] != nil
				{
				outstandingRequests[reqID] = nil
				}
			}
	}
}
