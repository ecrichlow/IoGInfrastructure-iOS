//
//  IoGRetryManagerTests.swift
//  IoG InfrastructureTests
//
//  Created by Eric Crichlow on 12/10/18.
//  Copyright © 2018 Infusions of Grandeur. All rights reserved.
//

import XCTest
@testable import IoGInfrastructure

class IoGRetryManagerTests: XCTestCase, IoGRetryManagerDelegate
{

	var retryIdentifier = 0
	var decoyRetryIdentifier = 0
	var retrySucceeded : Bool?
	var callbackInvoked : Bool?
	var callbackTimer : Timer?
	var result : IoGRetryManager.RetryResult?

    override func setUp()
    {
        super.setUp()
        retryIdentifier = 0
        decoyRetryIdentifier = 0
        retrySucceeded = nil
        callbackInvoked = nil
        callbackTimer = nil
        result = nil
		IoGRetryManager.sharedManager.registerDelegate(delegate: self)
    }
    
    override func tearDown()
    {

        super.tearDown()
        if let timer = callbackTimer
        	{
			timer.invalidate()
			}
		IoGRetryManager.sharedManager.unregisterDelegate(delegate: self)
    }

	func testExpiringRetrySuccess()
	{
		let expiration = Date.init().addingTimeInterval(IoGTestConfigurationManager.retryTestExpiration)
		let preExpiration = Date.init().addingTimeInterval(IoGTestConfigurationManager.preExpiration)
		let successExpectation = expectation(description: "Retry succeeded")
		let callbackExpectation = expectation(description: "Callback delay achieved")
		var decoyRetryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			let currentTime = Date()
			if currentTime.timeIntervalSince(preExpiration) < 0
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Success)
				successExpectation.fulfill()
				Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: false) {timer in callbackExpectation.fulfill()}
				}
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .ExpirationLimited, maxCount: nil, timeSpan: nil, expiration: expiration, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		waitForExpectations(timeout: IoGTestConfigurationManager.retryTestExpirationCheckTimeout, handler: nil)
		XCTAssertTrue(retrySucceeded!)
		XCTAssertEqual(self.result!, IoGRetryManager.RetryResult.Success)
	}

	func testExpiringRetryFail()
	{
		let expiration = Date.init().addingTimeInterval(IoGTestConfigurationManager.retryTestExpiration)
		let callbackExpectation = expectation(description: "Callback invoked")
		var decoyRetryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .ExpirationLimited, maxCount: nil, timeSpan: nil, expiration: expiration, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		callbackTimer = Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: true) {timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					self.callbackTimer!.invalidate()
					if self.result != IoGRetryManager.RetryResult.Expired
						{
						XCTFail()
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.retryTestExpirationCheckTimeout, handler: nil)
		XCTAssertFalse(retrySucceeded!)
	}

	func testTimeLimitedRetrySuccess()
	{
		let preExpiration = Date.init().addingTimeInterval(IoGTestConfigurationManager.preExpiration)
		let successExpectation = expectation(description: "Retry succeeded")
		let callbackExpectation = expectation(description: "Callback delay achieved")
		var decoyRetryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			let currentTime = Date()
			if currentTime.timeIntervalSince(preExpiration) < 0
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Success)
				successExpectation.fulfill()
				Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: false) {timer in callbackExpectation.fulfill()}
				}
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .TimeLimited, maxCount: nil, timeSpan: IoGTestConfigurationManager.retryTestExpiration, expiration: nil, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		waitForExpectations(timeout: IoGTestConfigurationManager.retryTestExpirationCheckTimeout, handler: nil)
		XCTAssertTrue(retrySucceeded!)
		XCTAssertEqual(self.result!, IoGRetryManager.RetryResult.Success)
	}

	func testTimeLimitedRetryFail()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		var decoyRetryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .TimeLimited, maxCount: nil, timeSpan: IoGTestConfigurationManager.retryTestExpiration, expiration: nil, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		callbackTimer = Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: true) {timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					self.callbackTimer!.invalidate()
					if self.result != IoGRetryManager.RetryResult.TimeLimitExceeded
						{
						XCTFail()
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.retryTestExpirationCheckTimeout, handler: nil)
		XCTAssertFalse(retrySucceeded!)
	}

	func testCountLimitedRetrySuccess()
	{
		let successExpectation = expectation(description: "Retry succeeded")
		let callbackExpectation = expectation(description: "Callback delay achieved")
		var decoyRetryCount = 0
		var retryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if retryCount < IoGTestConfigurationManager.retrySuccessIteration
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Success)
				successExpectation.fulfill()
				Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: false) {timer in callbackExpectation.fulfill()}
				}
			retryCount += 1
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.maxCount, timeSpan: nil, expiration: nil, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		waitForExpectations(timeout: IoGTestConfigurationManager.retryTestExpirationCheckTimeout, handler: nil)
		XCTAssertTrue(retrySucceeded!)
		XCTAssertEqual(self.result!, IoGRetryManager.RetryResult.Success)
	}

	func testCountLimitedRetryFail()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		var decoyRetryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.maxCount, timeSpan: nil, expiration: nil, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		callbackTimer = Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: true) {timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					self.callbackTimer!.invalidate()
					if self.result != IoGRetryManager.RetryResult.CountExceeded
						{
						XCTFail()
						}
					callbackExpectation.fulfill()
					}
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.retryTestExpirationCheckTimeout, handler: nil)
		XCTAssertFalse(retrySucceeded!)
	}

	func testInfiniteRetrySuccess()
	{
		let successExpectation = expectation(description: "Retry succeeded")
		let callbackExpectation = expectation(description: "Callback delay achieved")
		var decoyRetryCount = 0
		var retryCount = 0
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if retryCount < IoGTestConfigurationManager.infiniteRetrySuccessIteration
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else
				{
				disposition(self.retryIdentifier, IoGRetryManager.Disposition.Success)
				successExpectation.fulfill()
				Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.retryCallbackDelay, repeats: false) {timer in callbackExpectation.fulfill()}
				}
			retryCount += 1
			}
		let decoyRetryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			if decoyRetryCount < IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Failure)
				}
			else if decoyRetryCount == IoGTestConfigurationManager.decoyRetrySuccessIteration
				{
				disposition(self.decoyRetryIdentifier, IoGRetryManager.Disposition.Success)
				}
			else
				{
				XCTFail()
				}
			decoyRetryCount += 1
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .Infinite, maxCount: nil, timeSpan: nil, expiration: nil, routine: retryRoutine)
		decoyRetryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.decoyRetryDelay, lifespan: .CountLimited, maxCount: IoGTestConfigurationManager.decoyMaxCount, timeSpan: nil, expiration: nil, routine: decoyRetryRoutine)
		XCTAssertEqual(decoyRetryIdentifier, retryIdentifier + 1)
		waitForExpectations(timeout: IoGTestConfigurationManager.infiniteRetryTestExpirationCheckTimeout, handler: nil)
		XCTAssertTrue(retrySucceeded!)
		XCTAssertEqual(self.result!, IoGRetryManager.RetryResult.Success)
	}

	func testExpirationNoExpirationDateFailure()
	{
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .ExpirationLimited, maxCount: nil, timeSpan: nil, expiration: nil, routine: retryRoutine)
		XCTAssertEqual(retryIdentifier, -1)
	}

	func testTimeLimitNoTimespanFailure()
	{
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .TimeLimited, maxCount: nil, timeSpan: nil, expiration: nil, routine: retryRoutine)
		XCTAssertEqual(retryIdentifier, -1)
	}

	func testCountLimitedNoMaxCountFailure()
	{
		let retryRoutine: IoGRetryManager.RetryRoutine = { (disposition: @escaping (_ identifier: Int, _ disp: IoGRetryManager.Disposition) -> ()) -> Void in
			}
		retryIdentifier = IoGRetryManager.sharedManager.startRetries(interval: IoGTestConfigurationManager.retryDelay, lifespan: .CountLimited, maxCount: nil, timeSpan: nil, expiration: nil, routine: retryRoutine)
		XCTAssertEqual(retryIdentifier, -1)
	}

	// Retry Manager Delegate method(s)

	func retrySessionCompleted(requestID: Int, result: IoGRetryManager.RetryResult)
	{
		if requestID == retryIdentifier
			{
			callbackInvoked = true
			self.result = result
			if result == .Success
				{
				retrySucceeded = true
				}
			else
				{
				retrySucceeded = false
				}
			}
	}

}
