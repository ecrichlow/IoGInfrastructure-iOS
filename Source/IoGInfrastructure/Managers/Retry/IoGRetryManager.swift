/*
********************************************************************************
* IoGRetryManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for scheduling failed
*						workflows to be attempted again
* Author:			Eric Crichlow
* Version:			1.1
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	11/26/18		*	EGC	*	File creation date
*	06/18/22		*	EGC	*	Added DocC support
********************************************************************************
*/

import Foundation

/// Protocol the delegates of the Retry Manager must conform to in order to be notified of the final status of
/// a series of retry attempts
public protocol IoGRetryManagerDelegate : AnyObject
{
	func retrySessionCompleted(requestID: Int, result: IoGRetryManager.RetryResult)
}

/// Singleton class that manages attempts to execute sections of code that previously failed to complete
public class IoGRetryManager
{

	/// Designates how long retry attempts will be made
	public enum RetryLifespan : Int
	{
		/// Retry attempts will be repeated indefinitely
		case Infinite
		/// Retry attempts will be made a designated number times
		case CountLimited
		/// Retry attempts will be made for a designated length of time
		case TimeLimited
		/// Retry attempts will be made until a designated time
		case ExpirationLimited
	}

	/// The disposition of the retry request after it has completed
	public enum RetryResult
	{
		/// The retry attempt completed successfully
		case Success
		/// The rety attempt ended when it failed to succeed after the designated number of attempts
		case CountExceeded
		/// The retry attempt ended when it failed to succeed after the designated length of time
		case TimeLimitExceeded
		/// The retry attempt ended when it failed to succeed after the designated end time
		case Expired
	}

	/// The result of the retry attempt returned to the Retry Manager from the closure being retried
	public enum Disposition : Int
	{
		/// The retry attempt succeeded
		case Success
		/// The retry attempt failed
		case Failure
	}

	static let retryItemFieldLifespan = "Lifespan"
	static let retryItemFieldRetryMaxCount = "Retries"
	static let retryItemFieldRetryCurrentCount = "RetryNumber"
	static let retryItemFieldExpiration = "Expiration"
	static let retryItemFieldTimeLimit = "TimeLimit"
	static let retryItemFieldRoutine = "Routine"
	static let retryItemFieldIdentifier = "Identifier"

	/// Returns the shared Data Object Manager instance.
	public static let sharedManager = IoGRetryManager()

	/// Alias for closures passed into the Retry Manager for delayed execution
	public typealias RetryRoutine = (@escaping (Int, Disposition) -> ()) -> ()

	var delegateList = NSPointerArray.weakObjects()

	var requestID = 0

	var retryStore = [Int: Dictionary<String, Any>]()

	// MARK: Instance Methods

	init()
	{
	}

	// MARK: Business Logic

	/// Register a delegate to receive a callback when the retry operation completes
	public func registerDelegate(delegate: IoGRetryManagerDelegate)
	{
		for nextDelegate in delegateList.allObjects
			{
			if let del = nextDelegate as? IoGRetryManagerDelegate
				{
				if del === delegate
					{
					return
					}
				}
			}
		let pointer = Unmanaged.passUnretained(delegate as AnyObject).toOpaque()
		delegateList.addPointer(pointer)
	}

	/// Unregister a relegate from receiving a callback when the retry operation completes
	public func unregisterDelegate(delegate: IoGRetryManagerDelegate)
	{
		var index = 0
		for nextDelegate in delegateList.allObjects
			{
			if let del = nextDelegate as? IoGRetryManagerDelegate
				{
				if del === delegate
					{
					break
					}
				index += 1
				}
			}
		if index < delegateList.count
			{
			delegateList.removePointer(at: index)
			}
	}

	/// Begin attempts to execute closure
	///
	///  - Parameters:
	///  	- interval: The length of time to wait between attempts to execute the closure
	///  	- lifespan: The designation for what factor will determine when attempts to execute the closure will stop
	///  	- maxCount: If the lifespan is CountLimited, the maximum number of attempts to make
	///  	- timeSpan: If the lifespan is TimeLimited, the maximum amount of time to spend making attempts
	///  	- expiration: If the lifespan is ExpirationLimited, the time to stop making attempts
	///  	- routine: The closure to attempt to execute on each retry attempt
	///
	///	- Returns:An identifier for the request
	@discardableResult public func startRetries(interval: TimeInterval, lifespan: RetryLifespan, maxCount: Int?, timeSpan: TimeInterval?, expiration: Date?, routine: @escaping RetryRoutine) -> Int
	{
		// Make sure the proper delimiter was passed in for the selected lifespan
		if (lifespan == .ExpirationLimited && expiration == nil) || (lifespan == .TimeLimited && timeSpan == nil) || (lifespan == .CountLimited && maxCount == nil)
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

	/// Begin attempts to execute closure with an infinite lifespan
	///
	///  - Parameters:
	///  	- interval: The length of time to wait between attempts to execute the closure
	///  	- routine: The closure to attempt to execute on each retry attempt
	///
	///	- Returns:An identifier for the request
	@discardableResult public func startRetries(interval: TimeInterval, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .Infinite, maxCount: nil, timeSpan: nil, expiration: nil, routine: routine)
	}

	/// Begin attempts to execute closure for a maximum number of times
	///
	///  - Parameters:
	///  	- interval: The length of time to wait between attempts to execute the closure
	///  	- maxCount: If the lifespan is CountLimited, the maximum number of attempts to make
	///  	- routine: The closure to attempt to execute on each retry attempt
	///
	///	- Returns:An identifier for the request
	@discardableResult public func startRetries(interval: TimeInterval, maxCount: Int, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .CountLimited, maxCount: maxCount, timeSpan: nil, expiration: nil, routine: routine)
	}

	/// Begin attempts to execute closure for a designated period of time
	///
	///  - Parameters:
	///  	- interval: The length of time to wait between attempts to execute the closure
	///  	- timeSpan: If the lifespan is TimeLimited, the maximum amount of time to spend making attempts
	///  	- routine: The closure to attempt to execute on each retry attempt
	///
	///	- Returns:An identifier for the request
	@discardableResult public func startRetries(interval: TimeInterval, timeSpan: TimeInterval, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .TimeLimited, maxCount: nil, timeSpan: timeSpan, expiration: nil, routine: routine)
	}

	/// Begin attempts to execute closure until a designated end time
	///
	///  - Parameters:
	///  	- interval: The length of time to wait between attempts to execute the closure
	///  	- expiration: If the lifespan is ExpirationLimited, the time to stop making attempts
	///  	- routine: The closure to attempt to execute on each retry attempt
	///
	///	- Returns:An identifier for the request
	@discardableResult public func startRetries(interval: TimeInterval, expiration: Date, routine: @escaping RetryRoutine) -> Int
	{
		return startRetries(interval: interval, lifespan: .ExpirationLimited, maxCount: nil, timeSpan: nil, expiration: expiration, routine: routine)
	}

	/// Stop attempts to execute closure
	///
	/// - Parameters:
	/// 	- identifier: The identifier of the retry attempt to cancel, returned from a call to startRetries
	public func cancelRetries(identifier: Int)
	{
		retryStore[identifier] = nil
	}

	private func makeRetryAttempt(timer: Timer, requestNumber: Int)
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
						if let delegate = nextDelegate as? IoGRetryManagerDelegate
							{
							delegate.retrySessionCompleted(requestID: requestNumber, result: .Expired)
							}
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
						if let delegate = nextDelegate as? IoGRetryManagerDelegate
							{
							delegate.retrySessionCompleted(requestID: requestNumber, result: .TimeLimitExceeded)
							}
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
							if let delegate = nextDelegate as? IoGRetryManagerDelegate
								{
								delegate.retrySessionCompleted(requestID: requestNumber, result: .CountExceeded)
								}
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

	internal func dispositionAttempt(requestNumber: Int, result: Disposition) -> Void
	{
		if retryStore[requestNumber] != nil
			{
			if result == .Success
				{
				delegateList.compact()
				for nextDelegate in delegateList.allObjects
					{
					if let delegate = nextDelegate as? IoGRetryManagerDelegate
						{
						delegate.retrySessionCompleted(requestID: requestNumber, result: .Success)
						}
					}
				retryStore[requestNumber] = nil
				}
			}
	}
}
