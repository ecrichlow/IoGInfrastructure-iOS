/*
********************************************************************************
* IoGDataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the base class for the manager for
*						retrieving remote data
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	09/27/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for custom request type
*	06/19/22		*	EGC	*	Added DocC support
*	12/17/24		*	EGC	*	Added support for customizing retry logic
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
	}

	/// Returns the shared Data Manager instance.
	private static var sharedManager : IoGDataManager!

	var delegateList = NSPointerArray.weakObjects()
	var outstandingRequests = [Int: IoGDataRequestResponse]()
	var requestID = 0
	var retryOnFailure = true
	var numAutoRetries = IoGConfigurationManager.defaultRequestNumRetries

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
		for nextDelegate in delegateList.allObjects
			{
			if let del = nextDelegate as? IoGDataManagerDelegate
				{
				if del === delegate
					{
					return
					}
				}
			}
		let pointer = Unmanaged.passUnretained(delegate as AnyObject).toOpaque()
		delegateList.addPointer(pointer)
	}

	/// Unregister a delegate from receiving a callback when the data operation completes
    /// - Parameters:
    ///   - delegate: object conforming to IoGDataManagerDelegate protocol that requests to stop being called when data operations complete
	public func unregisterDelegate(delegate: IoGDataManagerDelegate)
	{
		var index = 0
		for nextDelegate in delegateList.allObjects
			{
			if let del = nextDelegate as? IoGDataManagerDelegate
				{
				if del === delegate
					{
					break
					}
				index += 1
				}
			}
		if index < delegateList.count
			{
			delegateList.removePointer(at: index)
			}
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
		delegateList.compact()
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
		outstandingRequests[reqID] = nil
	}
}
