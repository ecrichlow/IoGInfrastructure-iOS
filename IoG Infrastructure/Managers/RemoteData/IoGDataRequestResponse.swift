/*******************************************************************************
* IoGDataRequestResponse.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the base class that encapsulates
*						a URL request (possibly multiple requests for multi-page
*						data) and the resulting response data
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	10/03/18		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

class IoGDataRequestResponse : NSObject
{

	internal var requestID: Int
	internal var callbackInfo : [String: Any]
	internal var requestInfo : [String: Any]
	internal var retryNumber : Int
	internal var statusCode : Int?
	internal var responseInfo : [String: Any]?
	internal var responseData : Data?

	init(withRequestID reqID: Int, type: IoGDataManager.IoGDataRequestType, request: URLRequest, callback: @escaping (IoGDataRequestResponse) -> ())
	{
		requestID = reqID
		retryNumber = 0
		callbackInfo = [IoGConfigurationManager.requestResponseKeyCallback : callback]
		requestInfo = [IoGConfigurationManager.requestResponseKeyRequest : request, IoGConfigurationManager.requestResponseKeyRequestType : type]
	}

	func processRequest()
	{
	}

	func continueMultiPartRequest()
	{
	}

	func didRequestSucceed() -> Bool
	{
		guard let code = statusCode
			else
				{
				return false
				}
		if code >= 200 && code < 300
			{
			return true
			}
		else
			{
			return false
			}
	}

	func getRequestInfo() -> [String: Any]
	{
		return requestInfo
	}
}
