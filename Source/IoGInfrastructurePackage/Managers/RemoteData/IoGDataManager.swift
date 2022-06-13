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
********************************************************************************
*/

import Foundation

public protocol IoGDataManagerDelegate : AnyObject
{
	func dataRequestResponseReceived(requestID: Int, requestType: IoGDataManager.IoGDataRequestType, responseData: Data?, error: Error?, response: IoGDataRequestResponse)
}

public typealias CustomDataRequestType = String

public class IoGDataManager
{

	public enum IoGDataManagerType
	{
		case IoGDataManagerTypeLive
		case IoGDataManagerTypeMock
	}

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

	public static var sharedManager : IoGDataManager!

	var delegateList = NSPointerArray.weakObjects()
	var outstandingRequests = [Int: IoGDataRequestResponse]()
	var requestID = 0

	// MARK: Class Methods

	public class func dataManagerOfType(type: IoGDataManagerType) -> IoGDataManager
	{
		switch (type)
			{
			case .IoGDataManagerTypeLive:
				if sharedManager == nil || !(sharedManager is IoGLiveDataManager)
					{
					sharedManager = IoGLiveDataManager()
					}
			case .IoGDataManagerTypeMock:
				if sharedManager == nil || !(sharedManager is IoGMockDataManager)
					{
					sharedManager = IoGMockDataManager()
					}
			}
		return sharedManager
	}

	public class func dataManagerOfDefaultType() -> IoGDataManager
	{
		return IoGDataManager.dataManagerOfType(type: IoGConfigurationManager.defaultDataManagerType)
	}

	// MARK: Instance Methods

	init()
	{
	}

	public func registerDelegate(delegate: IoGDataManagerDelegate)
	{
		for nextDelegate in delegateList.allObjects
			{
			let del = nextDelegate as! IoGDataManagerDelegate
			if del === delegate
				{
				return
				}
			}
		let pointer = Unmanaged.passUnretained(delegate as AnyObject).toOpaque()
		delegateList.addPointer(pointer)
	}

	public func unregisterDelegate(delegate: IoGDataManagerDelegate)
	{
		var index = 0
		for nextDelegate in delegateList.allObjects
			{
			let del = nextDelegate as! IoGDataManagerDelegate
			if del === delegate
				{
				break
				}
			index += 1
			}
		if index < delegateList.count
			{
			delegateList.removePointer(at: index)
			}
	}

	@discardableResult public func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int
	{
		return 0
	}

	@discardableResult public func transmitRequest(request: URLRequest, type: IoGDataRequestType, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		return 0
	}

	public func continueMultiPartRequest(multiPartResponse: IoGDataRequestResponse)
	{
		multiPartResponse.continueMultiPartRequest()
	}

	// MARK: Data Request Callback

	func dataRequestResponse(_ response: IoGDataRequestResponse)
	{
		delegateList.compact()
		for nextDelegate in delegateList.allObjects
			{
			let delegate = nextDelegate as! IoGDataManagerDelegate
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
}
