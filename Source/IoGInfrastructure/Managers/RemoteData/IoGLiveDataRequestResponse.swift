/*
********************************************************************************
* IoGLiveDataRequestResponse.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the live implementation of the class
*						that encapsulates a URL request (possibly multiple
*						requests for multi-page data) and the resulting response
*						data
* Author:			Eric Crichlow
* Version:			4.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	11/19/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for multiple API URLs
*	06/19/22		*	EGC	*	Added DocC support
*	12/17/24		*	EGC	*	Added support for customizing retry logic
*	06/04/25		*	EGC	*	Added ability for client to get session cookies
 *	03/15/26		*	EGC	*	Refactored to use shared URLSession (Copilot)
*	03/15/26		*	EGC	*	Added OperationQueue to limit simulataneous calls
********************************************************************************
*/

import Foundation

/// The "live" subclass of IoGDataRequestResponse that encapsulates a URL request and response, which
/// IoGDataManagerDelegate classes can query to get raw data about the transaction
public class IoGLiveDataRequestResponse : IoGDataRequestResponse
{

	private(set) var responseHeader : [AnyHashable : Any]?
	private var timeoutTimer : Timer?
	private weak var session : URLSession?
	private weak var dataManager: IoGLiveDataManager?
	private var dataTask : URLSessionDataTask?
	private var requestOperation: Operation?
	private weak var operationQueue: OperationQueue?

	// MARK: Instance Methods
	
	init(withRequestID reqID: Int, type: IoGDataManager.IoGDataRequestType, request: URLRequest, session: URLSession, dataManager: IoGLiveDataManager, callback: @escaping (IoGDataRequestResponse) -> ())
	{
		self.session = session
		self.dataManager = dataManager
		self.operationQueue = dataManager.requestOperationQueue
		super.init(withRequestID: reqID, type: type, request: request, callback: callback)
	}

	// MARK: Business Logic

	override internal func processRequest()
	{
		guard let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest] as? URLRequest,
			  let currentSession = session,
			  let queue = operationQueue
			else
				{
				return
				}
		
		// Wrap the request execution in an operation to manage concurrency
		let operation = BlockOperation { [weak self] in
			guard let self = self else { return }
			
			self.dataTask = currentSession.dataTask(with: request)
			guard let newDataTask = self.dataTask
				else
					{
					return
					}
			self.dataManager?.registerTask(newDataTask, forRequestID: self.requestID)
			self.responseData = Data()
			
			// Schedule timeout timer on main run loop
			DispatchQueue.main.async { [weak self] in
				guard let self = self else { return }
				self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: IoGConfigurationManager.defaultRequestTimeoutDelay, repeats: false)
					{ [weak self] timer in
					guard let self = self else { return }
					self.retryNumber += 1
					if IoGDataManager.dataManagerOfDefaultType().getRetryOnFailure() && self.retryNumber <= IoGDataManager.dataManagerOfDefaultType().getNumberofRetries()
						{
						self.processRequest()
						}
					else
						{
						guard let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as? (IoGDataRequestResponse) -> () else { return }
						self.end = Date()
						self.responseInfo = [IoGConfigurationManager.requestResponseKeyError: NSError.init(domain: IoGConfigurationManager.requestResponseTimeoutErrorDescription, code: IoGConfigurationManager.requestResponseTimeoutErrorCode, userInfo: nil)]
						callback(self)
						}
					}
			}
			
			self.start = Date()
			if let body = request.httpBody
				{
				self.sentDataSize = body.count
				}
			newDataTask.resume()
		}
		
		requestOperation = operation
		queue.addOperation(operation)
	}

	// When continuing a request for subsequent pages, target and callback always stay the same. Just URL changes for incrementing the page number
	override public func continueMultiPartRequest()
	{
		if let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest] as? URLRequest,
		   let currentSession = session
			{
			dataTask = currentSession.dataTask(with: request)
			guard let newDataTask = dataTask
				else
					{
					return
					}
			dataManager?.registerTask(newDataTask, forRequestID: requestID)
			retryNumber = 0
			responseData = Data()
			timeoutTimer = Timer.scheduledTimer(withTimeInterval: IoGConfigurationManager.defaultRequestTimeoutDelay, repeats: false)
				{ [weak self] timer in
				guard let self = self else { return }
				self.retryNumber += 1
				if IoGDataManager.dataManagerOfDefaultType().getRetryOnFailure() && self.retryNumber <= IoGDataManager.dataManagerOfDefaultType().getNumberofRetries()
					{
					self.continueMultiPartRequest()
					}
				else
					{
					guard let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as? (IoGDataRequestResponse) -> () else { return }
					self.end = Date()
					if var respInfo = self.responseInfo
						{
						respInfo[IoGConfigurationManager.requestResponseKeyError] = NSError.init(domain: IoGConfigurationManager.requestResponseTimeoutErrorDescription, code: IoGConfigurationManager.requestResponseTimeoutErrorCode, userInfo: nil)
						self.responseInfo = respInfo
						}
					else
						{
						self.responseInfo = [IoGConfigurationManager.requestResponseKeyError: NSError.init(domain: IoGConfigurationManager.requestResponseTimeoutErrorDescription, code: IoGConfigurationManager.requestResponseTimeoutErrorCode, userInfo: nil)]
						}
					callback(self)
					}
				}
			start = Date()
			if let body = request.httpBody
				{
				sentDataSize = body.count
				}
			newDataTask.resume()
			}
	}

	override public func cancelRequest()
	{
		// Invalidate the timeout timer
		if let timer = timeoutTimer
			{
			timer.invalidate()
			timeoutTimer = nil
			}
		// Cancel the operation if it hasn't started yet
		requestOperation?.cancel()
		requestOperation = nil
		if let task = dataTask
			{
			dataManager?.unregisterTask(task)
			}
		dataTask?.cancel()
		dataTask = nil
	}

	// MARK: URLSession Callback Handlers (called by IoGSessionDelegate)

	internal func handleDidCompleteWithError(session: URLSession, task: URLSessionTask, error: Error?)
	{
		if let timer = timeoutTimer
			{
			timer.invalidate()
			timeoutTimer = nil
			}
		// Clean up references
		requestOperation = nil
		dataTask = nil
		dataManager?.unregisterTask(task)
		end = Date()
		guard let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as? (IoGDataRequestResponse) -> () else { return }
		if let err = error
			{
			if var respInfo = self.responseInfo
				{
				respInfo[IoGConfigurationManager.requestResponseKeyError] = err
				self.responseInfo = respInfo
				}
			else
				{
				self.responseInfo = [IoGConfigurationManager.requestResponseKeyError: err]
				}
			}
		else
			{
			if let resp = self.responseData
				{
				if var respInfo = self.responseInfo
					{
					respInfo[IoGConfigurationManager.requestResponseKeyResponse] = resp
					self.responseInfo = respInfo
					}
				else
					{
					self.responseInfo = [IoGConfigurationManager.requestResponseKeyResponse: resp]
					}
				receivedDataSize = resp.count
				}
			}
		if let response = task.response as? HTTPURLResponse
			{
			let code = response.statusCode
			let header = response.allHeaderFields
			self.statusCode = code
			self.responseHeader = header
			self.responseCookies = session.configuration.httpCookieStorage?.cookies
			}
		callback(self)
	}

	internal func handleDidReceiveResponse(session: URLSession, dataTask: URLSessionDataTask, response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
	{
		if let timer = timeoutTimer
			{
			timer.invalidate()
			timeoutTimer = nil
			}
		guard let httpResponse = response as? HTTPURLResponse
			else
				{
				completionHandler(.cancel)
				return
				}
		let code = httpResponse.statusCode
		let header = httpResponse.allHeaderFields
		self.statusCode = code
		self.responseHeader = header
		// If the status is outside of the success category, bail now
		if code < 200 || code > 299
			{
			completionHandler(.cancel)
			}
		else
			{
			completionHandler(.allow)
			}
	}

	internal func handleDidReceiveData(data: Data)
	{
		if let timer = timeoutTimer
			{
			timer.invalidate()
			timeoutTimer = nil
			}
		if var existingData = responseData
			{
			existingData.append(data)
			responseData = existingData
			}
		else
			{
			responseData = data
			}
	}
}
