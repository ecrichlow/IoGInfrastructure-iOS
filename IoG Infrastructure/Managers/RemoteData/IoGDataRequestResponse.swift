/*******************************************************************************
* IoGDataRequestResponse.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the class that encapsulates a URL
*						request (possibly multiple requests for multi-page data)
*						and the resulting response data
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	10/03/18		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

class IoGDataRequestResponse : NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate
{

	private(set) var requestID: Int
	private var callbackInfo : [String: Any]
	private var requestInfo : [String: Any]
	private(set) var responseInfo : [String: Any]?
	private(set) var statusCode : Int?
	private(set) var responseData : Data?
	private(set) var responseHeader : [AnyHashable : Any]?
	private var timeoutTimer : Timer?
	private var retryNumber : Int
	private var session : URLSession?
	private var dataTask : URLSessionDataTask?

	init(withRequestID reqID: Int, type: IoGDataManager.IoGDataRequestType, request: URLRequest, callback: @escaping (IoGDataRequestResponse) -> ())
	{
		requestID = reqID
		callbackInfo = [IoGConfigurationManager.requestResponseKeyCallback: callback]
		requestInfo = [IoGConfigurationManager.requestResponseKeyRequest: request, IoGConfigurationManager.requestResponseKeyRequestType: type]
		retryNumber = 0
	}

	func processRequest()
	{
		let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest] as! URLRequest
		let newSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
		dataTask = newSession.dataTask(with: request)
		guard let newDataTask = dataTask
			else
				{
				return
				}
		responseData = Data()
		timeoutTimer = Timer.scheduledTimer(withTimeInterval: IoGConfigurationManager.defaultRequestTimeoutDelay, repeats: false)
			{
			timer in
			self.retryNumber += 1
			if self.retryNumber <= IoGConfigurationManager.defaultRequestNumRetries
				{
				self.processRequest()
				}
			else
				{
				let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as! (IoGDataRequestResponse) -> ()
				self.responseInfo = [IoGConfigurationManager.requestResponseKeyError: NSError.init(domain: IoGConfigurationManager.requestResponseTimeoutErrorDescription, code: IoGConfigurationManager.requestResponseTimeoutErrorCode, userInfo: nil)]
				callback(self)
				}
			}
		session = newSession
		newDataTask.resume()
	}

	// When continuing a request for subsequent pages, target and callback always stay the same. Just URL changes for incrementing the page number
	func continueMultiPartRequest()
	{
		let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest] as! URLRequest
		if let currentSession = session
			{
			dataTask = currentSession.dataTask(with: request)
			guard let newDataTask = dataTask
				else
					{
					return
					}
			retryNumber = 0
			responseData = Data()
			timeoutTimer = Timer.scheduledTimer(withTimeInterval: IoGConfigurationManager.defaultRequestTimeoutDelay, repeats: false)
				{
				timer in
				self.retryNumber += 1
				if self.retryNumber <= IoGConfigurationManager.defaultRequestNumRetries
					{
					self.processRequest()
					}
				else
					{
					let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as! (IoGDataRequestResponse) -> ()
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
			newDataTask.resume()
			}
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

	// MARK: URLSessionDelegate methods

	func urlSession(_: URLSession, didBecomeInvalidWithError: Error?)
	{
	}

	func urlSessionDidFinishEvents(forBackgroundURLSession: URLSession)
	{
	}

	func urlSession(_: URLSession, didReceive: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
	{
		let authMethod = didReceive.protectionSpace.authenticationMethod
		guard authMethod == NSURLAuthenticationMethodServerTrust
			else
				{
				completionHandler(.performDefaultHandling, nil)
				return
				}
		let hostToValidate = didReceive.protectionSpace.host
		if let apiURL = IoGConfigurationManager.sharedManager.getAPIURL()
			{
			if apiURL.absoluteString.contains(hostToValidate)
				{
				if let serverTrust = didReceive.protectionSpace.serverTrust
					{
					let credential = URLCredential(trust: serverTrust)
					completionHandler(.useCredential, credential)
					return
					}
				}
			}
		completionHandler(.cancelAuthenticationChallenge, nil)
	}

	// MARK: URLSessionTaskDelegate methods

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
	{
		let callback = self.callbackInfo[IoGConfigurationManager.requestResponseKeyCallback] as! (IoGDataRequestResponse) -> ()
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
				}
			}
		callback(self)
	}

	func urlSession(_: URLSession, task: URLSessionTask, willPerformHTTPRedirection: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void)
	{
		completionHandler(nil)
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
	{
	}

//	func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void)
//	{
//		let flag = true
//	}

	func urlSession(_: URLSession, task: URLSessionTask, didReceive: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
	{
		let authMethod = didReceive.protectionSpace.authenticationMethod
		guard authMethod == NSURLAuthenticationMethodServerTrust
			else
				{
				completionHandler(.performDefaultHandling, nil)
				return
				}
		let hostToValidate = didReceive.protectionSpace.host
		if let apiURL = IoGConfigurationManager.sharedManager.getAPIURL()
			{
			if apiURL.absoluteString.contains(hostToValidate)
				{
				if let serverTrust = didReceive.protectionSpace.serverTrust
					{
					let credential = URLCredential(trust: serverTrust)
					completionHandler(.useCredential, credential)
					return
					}
				}
			}
		completionHandler(.cancelAuthenticationChallenge, nil)
	}

	func urlSession(_: URLSession, taskIsWaitingForConnectivity: URLSessionTask)
	{
	}

	func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting: URLSessionTaskMetrics)
	{
	}

	// MARK: URLSessionDataTaskDelegate

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
	{
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

	func urlSession(_: URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionDownloadTask)
	{
	}

	func urlSession(_: URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionStreamTask)
	{
	}

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
	{
		if let timer = timeoutTimer
			{
			timer.invalidate()
			timeoutTimer = nil
			}
		if var existingData = responseData
			{
			existingData.append(data)
			}
		else
			{
			responseData = data
			}
	}

	func urlSession(_: URLSession, dataTask: URLSessionDataTask, willCacheResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void)
	{
		completionHandler(nil)
	}

}
