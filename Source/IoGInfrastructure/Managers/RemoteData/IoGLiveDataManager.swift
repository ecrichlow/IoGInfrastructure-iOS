/*
********************************************************************************
* IoGLiveDataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the live implementation of the class
*						for the manager for retrieving remote data
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	10/01/18		*	EGC	*	File creation date
*	02/16/22		*	EGC	*	Added support for custom request type
*	06/19/22		*	EGC	*	Added DocC support
*	08/14/25		*	EGC	*	Added support for thread safety
*	03/15/26		*	EGC	*	Refactored to use shared URLSession (Copilot)
********************************************************************************
*/

import Foundation

/// Delegate class that routes URLSession callbacks to the appropriate IoGLiveDataRequestResponse instance
internal class IoGSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate
{
	weak var dataManager: IoGLiveDataManager?
	
	init(dataManager: IoGLiveDataManager)
	{
		self.dataManager = dataManager
		super.init()
	}
	
	// MARK: URLSessionDelegate methods
	
	func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
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
		let apiURLs = IoGConfigurationManager.sharedManager.getAPIURLs()
		for nextURL in apiURLs
			{
			if nextURL.absoluteString.contains(hostToValidate)
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
		guard let requestResponse = dataManager?.requestResponseForTask(task) else { return }
		requestResponse.handleDidCompleteWithError(session: session, task: task, error: error)
	}
	
	func urlSession(_: URLSession, task: URLSessionTask, willPerformHTTPRedirection: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void)
	{
		completionHandler(newRequest)
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
	{
	}
	
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
		let apiURLs = IoGConfigurationManager.sharedManager.getAPIURLs()
		for nextURL in apiURLs
			{
			if hostToValidate.contains(nextURL.absoluteString)
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
		guard let requestResponse = dataManager?.requestResponseForTask(dataTask) else
			{
			completionHandler(.cancel)
			return
			}
		requestResponse.handleDidReceiveResponse(session: session, dataTask: dataTask, response: response, completionHandler: completionHandler)
	}
	
	func urlSession(_: URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionDownloadTask)
	{
	}
	
	func urlSession(_: URLSession, dataTask: URLSessionDataTask, didBecome: URLSessionStreamTask)
	{
	}
	
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
	{
		guard let requestResponse = dataManager?.requestResponseForTask(dataTask) else { return }
		requestResponse.handleDidReceiveData(data: data)
	}
	
	func urlSession(_: URLSession, dataTask: URLSessionDataTask, willCacheResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void)
	{
		completionHandler(nil)
	}
}

/// The "live" subclass of IoGDataManager that manages back end communications to real servers
public class IoGLiveDataManager : IoGDataManager
{
	/// Default maximum number of concurrent requests
	public static let defaultMaxConcurrentRequests = 4
	
	private var sessionDelegate: IoGSessionDelegate!
	private(set) var sharedSession: URLSession!
	private var taskToRequestID = [Int: Int]()  // Maps URLSessionTask.taskIdentifier to requestID
	private let taskMappingQueue = DispatchQueue(label: "com.iog.taskMappingQueue")
	internal let requestOperationQueue: OperationQueue
	
	override init()
	{
		requestOperationQueue = OperationQueue()
		requestOperationQueue.name = "com.iog.requestOperationQueue"
		requestOperationQueue.maxConcurrentOperationCount = IoGLiveDataManager.defaultMaxConcurrentRequests
		super.init()
		sessionDelegate = IoGSessionDelegate(dataManager: self)
		sharedSession = URLSession(configuration: URLSessionConfiguration.default, delegate: sessionDelegate, delegateQueue: nil)
	}
	
	// MARK: Configuration
	
	/// Set the maximum number of concurrent requests
	///
	///  - Parameters:
	///   - maxConcurrent: The maximum number of requests that can execute simultaneously
	public func setMaxConcurrentRequests(_ maxConcurrent: Int)
	{
		requestOperationQueue.maxConcurrentOperationCount = maxConcurrent
	}
	
	/// Get the current maximum number of concurrent requests
	///
	///  - Returns: The maximum number of requests that can execute simultaneously
	public func getMaxConcurrentRequests() -> Int
	{
		return requestOperationQueue.maxConcurrentOperationCount
	}
	
	// MARK: Task Mapping
	
	internal func registerTask(_ task: URLSessionTask, forRequestID requestID: Int)
	{
		taskMappingQueue.sync {
			taskToRequestID[task.taskIdentifier] = requestID
		}
	}
	
	internal func unregisterTask(_ task: URLSessionTask)
	{
		taskMappingQueue.sync {
			taskToRequestID[task.taskIdentifier] = nil
		}
	}
	
	internal func requestResponseForTask(_ task: URLSessionTask) -> IoGLiveDataRequestResponse?
	{
		var reqID: Int?
		taskMappingQueue.sync {
			reqID = taskToRequestID[task.taskIdentifier]
		}
		guard let requestID = reqID else { return nil }
		var result: IoGLiveDataRequestResponse?
		processingQueue.sync {
			result = outstandingRequests[requestID] as? IoGLiveDataRequestResponse
		}
		return result
	}
	
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
		processingQueue.sync {
			let requestResponse = IoGLiveDataRequestResponse(withRequestID: reqID, type: type, request: request, session: sharedSession, dataManager: self, callback: dataRequestResponse)
			outstandingRequests[reqID] = requestResponse
			requestResponse.processRequest()
			}
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
		processingQueue.sync {
			let requestResponse = IoGLiveDataRequestResponse(withRequestID: reqID, type: .Custom, request: request, session: sharedSession, dataManager: self, callback: dataRequestResponse)
			requestResponse.setCustomRequestType(customType: customTypeIdentifier)
			outstandingRequests[reqID] = requestResponse
			requestResponse.processRequest()
			}
		return reqID
	}
	
	/// Cancel URLRequest
	///
	///  - Parameters:
	///   - targetRequestID: The ID of the URLRequest to cancel
	override public func cancelRequest(targetRequestID: Int)
	{
		processingQueue.sync {
			if let foundRequest = outstandingRequests[targetRequestID]
				{
				foundRequest.cancelRequest()
				}
			}
	}
}
