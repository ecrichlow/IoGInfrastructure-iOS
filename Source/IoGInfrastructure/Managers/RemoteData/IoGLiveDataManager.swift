/*
********************************************************************************
* IoGLiveDataManager.swift
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
*	06/19/22		*	EGC	*	Added DocC support
********************************************************************************
*/

import Foundation

/// The "live" subclass of IoGDataManager that manages back end communications to real servers
public class IoGLiveDataManager : IoGDataManager
{
	
	// MARK: Business Logic
	
	/// Send URLRequest
	///
	///  - Parameters:
	///   - request: The URLRequest to process
	///   - type: One of the pre-defined identifiers used by delegates to differentiate the kind of request they are being notified about
	///
	///  - Returns: An identifier for the request
	@discardableResult override public func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int
	{
		let reqID = requestID
		requestID += 1
		let requestResponse = IoGLiveDataRequestResponse(withRequestID: reqID, type: type, request: request, callback: dataRequestResponse)
		outstandingRequests[reqID] = requestResponse
		requestResponse.processRequest()
		return reqID
	}
	
	/// Send URLRequest with custom type
	///
	///  - Parameters:
	///   - request: The URLRequest to process
	///   - customTypeIdentifier: A custom identifier used by delegates to differentiate the kind of request they are being notified about
	///
	///  - Returns: An identifier for the request
	@discardableResult override public func transmitRequest(request: URLRequest, customTypeIdentifier: CustomDataRequestType) -> Int
	{
		let reqID = requestID
		requestID += 1
		let requestResponse = IoGLiveDataRequestResponse(withRequestID: reqID, type: .Custom, request: request, callback: dataRequestResponse)
		requestResponse.setCustomRequestType(customType: customTypeIdentifier)
		outstandingRequests[reqID] = requestResponse
		requestResponse.processRequest()
		return reqID
	}
	
	/// Cancel URLRequest
	///
	///  - Parameters:
	///   - targetRequestID: The ID of the URLRequest to cancel
	override public func cancelRequest(targetRequestID: Int)
	{
		if let foundRequest = outstandingRequests[targetRequestID]
			{
			foundRequest.cancelRequest()
			}
	}
}
