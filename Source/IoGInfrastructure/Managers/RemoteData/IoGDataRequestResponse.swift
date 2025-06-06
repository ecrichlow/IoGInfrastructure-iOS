/*
********************************************************************************
* IoGDataRequestResponse.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the base class that encapsulates
*						a URL request (possibly multiple requests for multi-page
*						data) and the resulting response data
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	10/03/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for custom request type
*	06/19/22		*	EGC	*	Added DocC support
*	06/04/25		*	EGC	*	Added ability for client to get session cookies
********************************************************************************
*/

import Foundation

/// The base class that encapsulates a URL request and response, which IoGDataManagerDelegate classes can query to get raw data about the transaction
public class IoGDataRequestResponse : NSObject
{

	internal var requestID: Int
	internal var callbackInfo: [String: Any]
	internal var requestInfo: [String: Any]
	internal var retryNumber: Int
	internal var statusCode: Int?
	internal var responseInfo: [String: Any]?
	internal var responseData: Data?
	internal var customRequestType: CustomDataRequestType?
	internal var start: Date?
	internal var end: Date?
	internal var sentDataSize = 0
	internal var receivedDataSize = 0
	internal var responseCookies: [HTTPCookie]?

	// MARK: Instance Methods

	init(withRequestID reqID: Int, type: IoGDataManager.IoGDataRequestType, request: URLRequest, callback: @escaping (IoGDataRequestResponse) -> ())
	{
		requestID = reqID
		retryNumber = 0
		callbackInfo = [IoGConfigurationManager.requestResponseKeyCallback : callback]
		requestInfo = [IoGConfigurationManager.requestResponseKeyRequest : request, IoGConfigurationManager.requestResponseKeyRequestType : type]
	}

	// MARK: Business Logic

	internal func processRequest()
	{
	}

	public func continueMultiPartRequest()
	{
	}

	public func cancelRequest()
	{
	}

	/// Retrieve the success status of the request
	///
	///  - Returns: Whether or not the URL request was successful
	public func didRequestSucceed() -> Bool
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

	/// Retrieve the request's unique identifier
	///
	///  - Returns: The requestID
	public func getRequestID() -> Int
	{
		return requestID
	}

	/// Retrieve the request info
	///
	///  - Returns: A dictionary containing the raw URLRequest and the request type
	public func getRequestInfo() -> [String: Any]
	{
		return requestInfo
	}

	/// Retrieve the response info
	///
	///  - Returns: A dictionary containing the raw URLRequest response and any error response
	public func getResponseInfo() -> [String: Any]?
	{
		return responseInfo
	}

	/// Retrieve the URLRequest status code after the request has completed
	///
	///  - Returns: The http status code response of the request
	public func getStatusCode() -> Int?
	{
		return statusCode
	}

	/// Retrieve the custom request type name
	public func getCustomRequestType() -> CustomDataRequestType?
	{
		return customRequestType
	}

	/// Set the custom request type name
	///
	///  - Parameters:
	///  	- customType: A custom name to associate with the request to identify it when receiving a response
	public func setCustomRequestType(customType: CustomDataRequestType)
	{
		customRequestType = customType
	}

	/// Retrieve the time that the operation took to complete
	///
	///  - Returns: If the opertation has completed, the time it took to complete
	public func getDuration() -> TimeInterval?
	{
		guard let startTime = start, let endTime = end
			else
				{
				return nil
				}
		return startTime.distance(to: endTime)
	}

	/// Retrieve the size of the body sent in an HTTP POST
	///
	///  - Returns: The number of bytes sent as the HTTP POST body
	public func getSentDataSize() -> Int
	{
		return sentDataSize
	}

	/// Retrieve the size of the data returned from an HTTP request
	///
	///  - Returns: The number of bytes received in response to a successful HTTP request
	public func getReceivedDataSize() -> Int
	{
		return receivedDataSize
	}

	/// Retrieve the cookies from an HTTP response
	///
	///  - Returns: The HTTP cookies from the response
	public func getResponseCookies() -> [HTTPCookie]?
	{
		return responseCookies
	}
}
