/*******************************************************************************
* IoGLiveDataRequestResponse.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the live implementation of the class
*						that encapsulates a URL request (possibly multiple
*						requests for multi-page data) and the resulting response
*						data
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	11/19/18		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

public class IoGLiveDataRequestResponse : IoGDataRequestResponse, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate
{

	private(set) var responseHeader : [AnyHashable : Any]?
	private var timeoutTimer : Timer?
	private var session : URLSession?
	private var dataTask : URLSessionDataTask?

	override public func processRequest()
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
	override public func continueMultiPartRequest()
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
					self.continueMultiPartRequest()
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

	// MARK: URLSessionDelegate methods

	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
	{
	}

	public func urlSessionDidFinishEvents(forBackgroundURLSession: URLSession)
	{
	}

	public func urlSession(_: URLSession, didReceive: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
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

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
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
		if let response = task.response as? HTTPURLResponse
			{
			let code = response.statusCode
			let header = response.allHeaderFields
			self.statusCode = code
			self.responseHeader = header
			}
		callback(self)
	}

	public func urlSession(_: URLSession, task: URLSessionTask, willPerformHTTPRedirection: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void)
	{
		completionHandler(newRequest)
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
	{
	}

	public func urlSession(_: URLSession, task: URLSessionTask, didReceive: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
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

	public func urlSession(_: URLSession, taskIsWaitingForConnectivity: URLSessionTask)
	{
	}

	public func urlSession(_: URLSession, task: URLSessionTask, didFinishCollecting: URLSessionTaskMetrics)
	{
	}

	// MARK: URLSessionDataTaskDelegate

	// TODO: May need to comment this one out
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
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

	public func urlSession(_: URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionDownloadTask)
	{
	}

	public func urlSession(_: URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionStreamTask)
	{
	}

	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
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

	public func urlSession(_: URLSession, dataTask: URLSessionDataTask, willCacheResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void)
	{
		completionHandler(nil)
	}
}
