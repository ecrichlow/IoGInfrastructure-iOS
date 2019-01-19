//
//  IoGDataManagerTests.swift
//  IoG InfrastructureTests
//
//  Created by Eric Crichlow on 1/12/19.
//  Copyright © 2018 Infusions of Grandeur. All rights reserved.
//

import XCTest
@testable import IoG_Infrastructure

class IoGDataManagerTests: XCTestCase, IoGDataManagerDelegate
{

	var callbackInvoked : Bool?
	var callbackResponse : IoGDataRequestResponse?
	var returnedData : Data?

    override func setUp()
    {
        super.setUp()
        callbackInvoked = nil
        callbackResponse = nil
        returnedData = nil
        IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).registerDelegate(delegate: self)
    }

    override func tearDown()
    {
        super.tearDown()
        IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).unregisterDelegate(delegate: self)
    }

	func testSuccessfulFastDataRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).transmitRequest(request: URLRequest(url: URL(string: IoGTestConfigurationManager.successURL1)!), type: .Login)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData
						{
						if let returnedString = String(data: data, encoding: .utf8)
							{
							if returnedString != IoGConfigurationManager.mockDataResponse1
								{
								XCTFail()
								}
							}
						}
					}
				callbackExpectation.fulfill()
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testFailedFastDataRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).transmitRequest(request: URLRequest(url: URL(string: IoGTestConfigurationManager.failureURL1)!), type: .Login)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let _ = self.returnedData
						{
						XCTFail()
						}
					else if let response = self.callbackResponse
						{
						if let responseInfo = response.responseInfo
							{
							if let error = responseInfo[IoGConfigurationManager.requestResponseKeyError]
								{
								let nserror = error as! NSError
								if nserror.code != IoGConfigurationManager.requestResponseTimeoutErrorCode
									{
									XCTFail()
									}
								}
							else
								{
								XCTFail()
								}
							}
						else
							{
							XCTFail()
							}
						}
					else
						{
						XCTFail()
						}
					}
				callbackExpectation.fulfill()
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testSuccessfulSlowDataRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).transmitRequest(request: URLRequest(url: URL(string: IoGTestConfigurationManager.successURL1Slow)!), type: .Login)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestSlowResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData
						{
						if let returnedString = String(data: data, encoding: .utf8)
							{
							if returnedString != IoGConfigurationManager.mockDataResponse1
								{
								XCTFail()
								}
							}
						}
					}
				callbackExpectation.fulfill()
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testFailedSlowDataRetrieval()
	{
		let callbackExpectation = expectation(description: "Callback invoked")
		IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).transmitRequest(request: URLRequest(url: URL(string: IoGTestConfigurationManager.failureURLSlow)!), type: .Login)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestSlowResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let _ = self.returnedData
						{
						XCTFail()
						}
					else if let response = self.callbackResponse
						{
						if let responseInfo = response.responseInfo
							{
							if let error = responseInfo[IoGConfigurationManager.requestResponseKeyError]
								{
								let nserror = error as! NSError
								if nserror.code != IoGConfigurationManager.requestResponseTimeoutErrorCode
									{
									XCTFail()
									}
								}
							else
								{
								XCTFail()
								}
							}
						else
							{
							XCTFail()
							}
						}
					else
						{
						XCTFail()
						}
					}
				callbackExpectation.fulfill()
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testSuccessfulMultiPageDataRetrieval()
	{
		let callback1Expectation = expectation(description: "Callback 1 invoked")
		let callback2Expectation = expectation(description: "Callback 2 invoked")
		IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).transmitRequest(request: URLRequest(url: URL(string: IoGTestConfigurationManager.successURL1)!), type: .Register)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData
						{
						if let returnedString = String(data: data, encoding: .utf8)
							{
							if returnedString != IoGConfigurationManager.mockDataResponse1
								{
								XCTFail()
								}
							else
								{
								if let response = self.callbackResponse
									{
									var requestInfo = response.requestInfo
									if let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest]
										{
										var urlrequest = request as! URLRequest
										urlrequest.url = URL(string: IoGTestConfigurationManager.successURL2)
										requestInfo[IoGConfigurationManager.requestResponseKeyRequest] = urlrequest
										response.requestInfo = requestInfo
										self.callbackInvoked = nil
										self.callbackResponse = nil
										self.returnedData = nil
										IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).continueMultiPartRequest(multiPartResponse: response)
										Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
											{
											timer in
											if let calledBack = self.callbackInvoked
												{
												if calledBack
													{
													if let data = self.returnedData
														{
														if let returnedString = String(data: data, encoding: .utf8)
															{
															if returnedString != IoGConfigurationManager.mockDataResponse2
																{
																XCTFail()
																}
															}
														}
													}
												callback2Expectation.fulfill()
												}
											}
										}
									}
								else
									{
									XCTFail()
									}
								}
							}
						else
							{
							XCTFail()
							}
						}
					else
						{
						XCTFail()
						}
					}
				callback1Expectation.fulfill()
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	func testFailedMultiPageDataRetrieval()
	{
		let callback1Expectation = expectation(description: "Callback 1 invoked")
		let callback2Expectation = expectation(description: "Callback 2 invoked")
		IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).transmitRequest(request: URLRequest(url: URL(string: IoGTestConfigurationManager.successURL1)!), type: .Register)
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
			{
			timer in
			if let calledBack = self.callbackInvoked
				{
				if calledBack
					{
					if let data = self.returnedData
						{
						if let returnedString = String(data: data, encoding: .utf8)
							{
							if returnedString != IoGConfigurationManager.mockDataResponse1
								{
								XCTFail()
								}
							else
								{
								if let response = self.callbackResponse
									{
									var requestInfo = response.requestInfo
									if let request = requestInfo[IoGConfigurationManager.requestResponseKeyRequest]
										{
										var urlrequest = request as! URLRequest
										urlrequest.url = URL(string: IoGTestConfigurationManager.failureURL1)
										requestInfo[IoGConfigurationManager.requestResponseKeyRequest] = urlrequest
										response.requestInfo = requestInfo
										self.callbackInvoked = nil
										self.callbackResponse = nil
										self.returnedData = nil
										IoGDataManager.dataManagerOfType(type: IoGDataManager.IoGDataManagerType.IoGDataManagerTypeMock).continueMultiPartRequest(multiPartResponse: response)
										Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.dataRequestFastResponseCheck, repeats: false)
											{
											timer in
											if let calledBack = self.callbackInvoked
												{
												if calledBack
													{
													if let _ = self.returnedData
														{
														XCTFail()
														}
													else if let response = self.callbackResponse
														{
														if let responseInfo = response.responseInfo
															{
															if let error = responseInfo[IoGConfigurationManager.requestResponseKeyError]
																{
																let nserror = error as! NSError
																if nserror.code != IoGConfigurationManager.requestResponseTimeoutErrorCode
																	{
																	XCTFail()
																	}
																}
															else
																{
																XCTFail()
																}
															}
														else
															{
															XCTFail()
															}
														}
													else
														{
														XCTFail()
														}
													}
												callback2Expectation.fulfill()
												}
											}
										}
									}
								else
									{
									XCTFail()
									}
								}
							}
						else
							{
							XCTFail()
							}
						}
					else
						{
						XCTFail()
						}
					}
				callback1Expectation.fulfill()
				}
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.dataTestExpirationCheckTimeout, handler: nil)
	}

	// Data Manager Delegate method(s)

	func dataRequestResponseReceived(requestID: Int, requestType: IoGDataManager.IoGDataRequestType, responseData: Data?, error: Error?, response: IoGDataRequestResponse)
	{
		callbackInvoked = true
		callbackResponse = response
		returnedData = responseData
	}
}
