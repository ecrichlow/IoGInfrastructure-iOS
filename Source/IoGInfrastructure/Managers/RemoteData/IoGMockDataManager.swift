/*
********************************************************************************
* IoGMockDataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the mock implementation of the class
*						for the manager for retrieving remote data
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	10/01/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for custom request type
********************************************************************************
*/

import Foundation

internal class IoGMockDataManager : IoGDataManager
{
	
	// MARK: Business Logic
	
	@discardableResult override internal func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int
	{
		let reqID = requestID
		requestID += 1
		let requestResponse = IoGMockDataRequestResponse(withRequestID: reqID, type: type, request: request, callback: dataRequestResponse)
		requestResponse.processRequest()
		return reqID
	}
	
	@discardableResult override internal func transmitRequest(request: URLRequest, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		let reqID = requestID
		requestID += 1
		let requestResponse = IoGMockDataRequestResponse(withRequestID: reqID, type: .Custom, request: request, callback: dataRequestResponse)
		requestResponse.setCustomRequestType(customType: customTypeIdentifier)
		requestResponse.processRequest()
		return reqID
	}
	
	override internal func cancelRequest(targetRequestID: Int)
	{
	}
}
