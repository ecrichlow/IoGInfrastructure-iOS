/*******************************************************************************
* IoGRetryManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for scheduling failed
*						workflows to be attempted again
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	11/26/18		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

public protocol IoGRetryManagerDelegate : class
{
	func retrySessionCompleted(requestID: Int, result: IoGRetryManager.RetryResult)
}

public class IoGRetryManager
{
	public enum RetryLifespan : Int
	{
		case Infinite
		case CountLimited
		case TimeLimited
		case ExpirationLimited
	}

	public enum RetryResult
	{
		case Success
		case CountExceeded
		case TimeLimitExceeded
		case Expired
	}

	public enum Disposition : Int
	{
		case Success
		case Failure
	}

	static let retryItemFieldLifespan = "Lifespan"
	static let retryItemFieldRetryMaxCount = "Retries"
	static let retryItemFieldRetryCurrentCount = "RetryNumber"
	static let retryItemFieldExpiration = "Expiration"
	static let retryItemFieldTimeLimit = "TimeLimit"
	static let retryItemFieldRoutine = "Routine"
	static let retryItemFieldIdentifier = "Identifier"

	public static let sharedManager = IoGRetryManager()

	public typealias RetryRoutine = (@escaping (Int, Disposition) -> ()) -> ()

	var delegateList = NSPointerArray.weakObjects()

	var requestID = 0

	var retryStore = [Int: Dictionary<String, Any>]()

	init()
	{
	}

	public func registerDelegate(delegate: IoGRetryManagerDelegate)
	{
		for nextDelegate in delegateList.allObjects
			{
			let del = nextDelegate as! IoGRetryManagerDelegate
			if del === delegate
				{
				return
				}
			}
		let pointer = Unmanaged.passUnretained(delegate as AnyObject).toOpaque()
		delegateList.addPointer(pointer)
	}

	public func unregisterDelegate(delegate: IoGRetryManagerDelegate)
	{
		var index = 0
		for nextDelegate in delegateList.allObjects
			{
			let del = nextDelegate as! IoGRetryManagerDelegate
			if del === delegate
				{
				break
				}
			index += 1
			}
		if index < delegateList.count
			{
			delegateList.removePointer(at: index)
			}
	}

	@discardableResult public func startRetries(interval: TimeInterval, lifespan: RetryLifespan, maxCount: Int?, timeSpan: TimeInterval?, expiration: Date?, routine: @escaping RetryRoutine) -> Int
	{
		// Make sure the proper delimiter was passed in for the selected lifespan
		if lifespan == .ExpirationLimited && expiration == nil || lifespan == .TimeLimited && timeSpan == nil || lifespan == .CountLimited && maxCount == nil
			{
			return -1
			}
		let request = requestID
		var newRetryEntry = [String: Any]()
		requestID += 1
		newRetryEntry[IoGConfigurationManager.retryItemFieldLifespan] = lifespan.rawValue
		if let max = maxCount
			{
			newRetryEntry[IoGConfigurationManager.retryItemFieldRetryMaxCount] = max
			}
		// If both expiration and timespan values are set, expiration will override timespan
		if let exp = expiration
			{
			newRetryEntry[IoGConfigurationManager.retryItemFieldExpiration] = exp
			}
		else if let span = timeSpan
			{
			let exp = Date(timeIntervalSinceNow: span)
			newRetryEntry[IoGConfigurationManager.retryItemFieldTimeLimit] = exp
			}
		newRetryEntry[IoGConfigurationManager.retryItemFieldRoutine] = routine
		if let max = maxCount
			{
			newRetryEntry[IoGConfigurationManager.retryItemFieldRetryCurrentCount] = 0
			if max > 1
				{
				Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {timer in self.makeRetryAttempt(timer: timer, requestNumber: request)}
				}
			else
				{
				Timer.scheduledTimer(withTimeInterval: interval, repeats: false) {timer in self.makeRetryAttempt(timer: timer, requestNumber: request)}
				}
			}
		else
			{
			Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {timer in self.makeRetryAttempt(timer: timer, requestNumber: request)}
			}
		retryStore[request] = newRetryEntry
		return request
	}

	@discardableResult public func startRetries(interval: TimeInterval, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .Infinite, maxCount: nil, timeSpan: nil, expiration: nil, routine: routine)
	}

	@discardableResult public func startRetries(interval: TimeInterval, maxCount: Int, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .CountLimited, maxCount: maxCount, timeSpan: nil, expiration: nil, routine: routine)
	}

	@discardableResult public func startRetries(interval: TimeInterval, timeSpan: TimeInterval, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .TimeLimited, maxCount: nil, timeSpan: timeSpan, expiration: nil, routine: routine)
	}

	@discardableResult public func startRetries(interval: TimeInterval, expiration: Date, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .ExpirationLimited, maxCount: nil, timeSpan: nil, expiration: expiration, routine: routine)
	}

	public func cancelRetries(identifier: Int)
	{
		retryStore[identifier] = nil
	}

	func makeRetryAttempt(timer: Timer, requestNumber: Int)
	{
		if let retryEntry = retryStore[requestNumber]
			{
			if let exp = retryEntry[IoGConfigurationManager.retryItemFieldExpiration] as? Date		// Expiration limited
				{
				if exp.timeIntervalSinceNow > 0
					{
					if let retryRoutine = retryEntry[IoGConfigurationManager.retryItemFieldRoutine] as? RetryRoutine
						{
						retryRoutine(dispositionAttempt)
						}
					}
				else
					{
					delegateList.compact()
					for nextDelegate in delegateList.allObjects
						{
						let delegate = nextDelegate as! IoGRetryManagerDelegate
						delegate.retrySessionCompleted(requestID: requestNumber, result: .Expired)
						}
					timer.invalidate()
					retryStore[requestNumber] = nil
					}
				}
			else if let exp = retryEntry[IoGConfigurationManager.retryItemFieldTimeLimit] as? Date		// Time limited
				{
				if exp.timeIntervalSinceNow > 0
					{
					if let retryRoutine = retryEntry[IoGConfigurationManager.retryItemFieldRoutine] as? RetryRoutine
						{
						retryRoutine(dispositionAttempt)
						}
					}
				else
					{
					delegateList.compact()
					for nextDelegate in delegateList.allObjects
						{
						let delegate = nextDelegate as! IoGRetryManagerDelegate
						delegate.retrySessionCompleted(requestID: requestNumber, result: .TimeLimitExceeded)
						}
					timer.invalidate()
					retryStore[requestNumber] = nil
					}
				}
			else if let count = retryEntry[IoGConfigurationManager.retryItemFieldRetryMaxCount] as? Int		// Count limited
				{
				if let lastRetry = retryEntry[IoGConfigurationManager.retryItemFieldRetryCurrentCount] as? Int
					{
					if lastRetry < count
						{
						if var modEntry = retryStore[requestNumber]
							{
							modEntry[IoGConfigurationManager.retryItemFieldRetryCurrentCount] = lastRetry + 1
							retryStore[requestNumber] = modEntry
							}
						if let retryRoutine = retryEntry[IoGConfigurationManager.retryItemFieldRoutine] as? RetryRoutine
							{
							retryRoutine(dispositionAttempt)
							}
						}
					else
						{
						delegateList.compact()
						for nextDelegate in delegateList.allObjects
							{
							let delegate = nextDelegate as! IoGRetryManagerDelegate
							delegate.retrySessionCompleted(requestID: requestNumber, result: .CountExceeded)
							}
						timer.invalidate()
						retryStore[requestNumber] = nil
						}
					}
				}
			else if let _ = retryEntry[IoGRetryManager.retryItemFieldLifespan] as? Int		// Infinite
				{
				if let retryRoutine = retryEntry[IoGRetryManager.retryItemFieldRoutine] as? RetryRoutine
					{
					retryRoutine(dispositionAttempt)
					}
				}
			}
		else
			{
			timer.invalidate()
			}
	}

	func dispositionAttempt(requestNumber: Int, result: Disposition) -> Void
	{
		if retryStore[requestNumber] != nil
			{
			if result == .Success
				{
				delegateList.compact()
				for nextDelegate in delegateList.allObjects
					{
					let delegate = nextDelegate as! IoGRetryManagerDelegate
					delegate.retrySessionCompleted(requestID: requestNumber, result: .Success)
					}
				retryStore[requestNumber] = nil
				}
			}
	}
}
