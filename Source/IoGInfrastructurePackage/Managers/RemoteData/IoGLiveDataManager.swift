/*
********************************************************************************
* IogLiveDataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the live implementation of the class
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

public class IoGLiveDataManager : IoGDataManager
{

	// MARK: Business Logic

	@discardableResult override public func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int
	{
		let reqID = requestID
		let requestResponse = IoGLiveDataRequestResponse(withRequestID: reqID, type: type, request: request, callback: dataRequestResponse)
		outstandingRequests[reqID] = requestResponse
		requestID += 1
		requestResponse.processRequest()
		return reqID
	}

	@discardableResult override public func transmitRequest(request: URLRequest, type: IoGDataRequestType, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		let reqID = requestID
		let requestResponse = IoGLiveDataRequestResponse(withRequestID: reqID, type: type, request: request, callback: dataRequestResponse)
		requestResponse.setCustomRequestType(customType: customTypeIdentifier)
		outstandingRequests[reqID] = requestResponse
		requestID += 1
		requestResponse.processRequest()
		return reqID
	}
}
