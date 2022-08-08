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
	}

	/// Returns the shared Data Manager instance.
	private static var sharedManager : IoGDataManager!

	var delegateList = NSPointerArray.weakObjects()
	var outstandingRequests = [Int: IoGDataRequestResponse]()
	var requestID = 0

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

	/// Unregister a relegate from receiving a callback when the data operation completes
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

	@discardableResult internal func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int
	{
		return 0
	}

	@discardableResult internal func transmitRequest(request: URLRequest, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		return 0
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
