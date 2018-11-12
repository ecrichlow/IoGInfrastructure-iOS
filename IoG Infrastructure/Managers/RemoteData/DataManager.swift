/*******************************************************************************
* DataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the base class for the manager for
*						retrieving remote data
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	09/27/18		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

protocol DataManagerDelegate : class
{
	func dataRequestResponseReceived(requestID: Int, requestType: DataManager.DataRequestType, responseData: Data?, error: Error?, response: DataRequestResponse)
}

class DataManager
{

	enum DataManagerType
	{
		case DataManagerTypeLive
		case DataManagerTypeMock
	}

	enum DataRequestType
	{
		case Register
		case Login
	}

	private static var sharedManager : DataManager!

//	var delegateList : Array<DataManagerDelegate> = Array()
	var delegateList = NSPointerArray.weakObjects()
	var outstandingRequests = [Int: DataRequestResponse]()
	var requestID = 0

	// MARK: Class Methods

	class func dataManagerOfType(type: DataManagerType) -> DataManager
	{
		switch (type)
			{
			case .DataManagerTypeLive:
				if sharedManager == nil || !(sharedManager is LiveDataManager)
					{
					sharedManager = LiveDataManager()
					}
			case .DataManagerTypeMock:
				if sharedManager == nil || !(sharedManager is MockDataManager)
					{
					sharedManager = MockDataManager()
					}
			}
		return sharedManager
	}

	class func dataManagerOfDefaultType() -> DataManager
	{
		return DataManager.dataManagerOfType(type: IoGConfigurationManager.defaultDataManagerType)
	}

	// MARK: Instance Methods

	init()
	{
	}

	func registerDelegate(delegate: DataManagerDelegate)
	{
		for nextDelegate in delegateList.allObjects
			{
			let del = nextDelegate as! DataManagerDelegate
			if del === delegate
				{
				return
				}
			}
		let pointer = Unmanaged.passUnretained(delegate as AnyObject).toOpaque()
		delegateList.addPointer(pointer)
	}

	func unregisterDelegate(delegate: DataManagerDelegate)
	{
		var index = 0
		for nextDelegate in delegateList.allObjects
			{
			let del = nextDelegate as! DataManagerDelegate
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

	// MARK: "Abstract" Client Methods to be overridden

	@discardableResult func transmitRequest(request: URLRequest, type: DataRequestType) -> Int?
	{
		return nil
	}

	func continueMultiPartRequest(multiPartResponse: DataRequestResponse)
	{
	}
}
