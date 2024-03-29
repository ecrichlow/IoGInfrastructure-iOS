/*
********************************************************************************
* IoGMockDataRequestResponse.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the mock implementation for the class
*						that encapsulates a URL request (possibly multiple
*						requests for multi-page data) and the resulting response
*						data
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	12/11/18		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation

internal class IoGMockDataRequestResponse : IoGDataRequestResponse
{

	// MARK: Business Logic

	override public func processRequest()
	{
		start = Date()
		statusCode = 200
		sendResponse()
	}

	override public func continueMultiPartRequest()
	{
		self.responseData = nil
		sendResponse()
	}

	override internal func cancelRequest()
	{
	}

	private func sendResponse()
	{
		let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as! (IoGDataRequestResponse) -> ()
		let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest] as! URLRequest
		let requestString = request.description
		let responseDelay = requestString.hasSuffix(IoGConfigurationManager.mockSlowResponseIndicator) == true ? IoGConfigurationManager.mockSlowDataRequestResponseTime : IoGConfigurationManager.mockFastDataRequestResponseTime
		Timer.scheduledTimer(withTimeInterval: responseDelay, repeats: false)
			{
			timer in
			if requestString.contains(IoGConfigurationManager.mockFailedCallIndicator)
				{
				if var respInfo = self.responseInfo
					{
					respInfo[IoGConfigurationManager.requestResponseKeyError] = NSError.init(domain: IoGConfigurationManager.requestResponseGeneralErrorDescription, code: IoGConfigurationManager.requestResponseTimeoutErrorCode, userInfo: nil)
					self.responseInfo = respInfo
					}
				else
					{
					self.responseInfo = [IoGConfigurationManager.requestResponseKeyError: NSError.init(domain: IoGConfigurationManager.requestResponseGeneralErrorDescription, code: IoGConfigurationManager.requestResponseTimeoutErrorCode, userInfo: nil)]
					}
				}
			else if requestString.contains(IoGConfigurationManager.mockSuccessfulCallIndicator)
				{
				let resp = (requestString.hasSuffix(IoGConfigurationManager.mockResponseIndicator1) == true || requestString.hasSuffix(IoGConfigurationManager.mockSlowResponseIndicator) == true) ? Data(IoGConfigurationManager.mockDataResponse1.utf8) : Data(IoGConfigurationManager.mockDataResponse2.utf8)
				if var respInfo = self.responseInfo
					{
					respInfo[IoGConfigurationManager.requestResponseKeyResponse] = resp
					self.responseInfo = respInfo
					}
				else
					{
					self.responseInfo = [IoGConfigurationManager.requestResponseKeyResponse: resp]
					}
				self.responseData = resp
				}
			else if requestString.contains(IoGConfigurationManager.mockGQLCallIndicator)
				{
				var resp: Data
				if requestString.hasSuffix(IoGConfigurationManager.mockResponseIndicator1) || requestString.hasSuffix(IoGConfigurationManager.mockResponseIndicator3)
					{
					resp = Data(IoGConfigurationManager.mockGQLQueryResponse1.utf8)
					}
				else
					{
					resp =  Data(IoGConfigurationManager.mockGQLQueryResponse2.utf8)
					}
				if var respInfo = self.responseInfo
					{
					respInfo[IoGConfigurationManager.requestResponseKeyResponse] = resp
					self.responseInfo = respInfo
					}
				else
					{
					self.responseInfo = [IoGConfigurationManager.requestResponseKeyResponse: resp]
					}
				self.responseData = resp
				self.sentDataSize = resp.count
				}
			self.end = Date()
			callback(self)
			}
	}
}
