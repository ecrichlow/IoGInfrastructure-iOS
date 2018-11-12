//
//  IoG_InfrastructureTests.swift
//  IoG InfrastructureTests
//
//  Created by Eric Crichlow on 11/6/18.
//  Copyright © 2018 Infusions of Grandeur. All rights reserved.
//

import XCTest
@testable import IoG_Infrastructure

class IoG_InfrastructureTests: XCTestCase
{

	var configurationManager: IoGConfigurationManager!
	var persitenceManager: IoGPersistenceManager!
	var persistenceSource: IoGPersistenceManager.PersistenceSource!

    override func setUp()
    {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        configurationManager = IoGConfigurationManager.sharedManager
        persitenceManager = IoGPersistenceManager.sharedManager
    }

    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        persitenceManager.clearValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
        persitenceManager = nil
        persistenceSource = nil
        configurationManager = nil
        super.tearDown()
    }

    func testSaveNumber()
    {
		let persistenceSource = IoGPersistenceManager.PersistenceSource.Memory
		let saveNumber = IoGTestConfigurationManager.persistenceTestNumericValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveNumber, type: IoGPersistenceManager.PersistenceDataType.Number, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: false)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! Int
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveNumber)
    }

    func testSaveString()
    {
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Session, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
    }

    func testSaveArray()
    {
		let persistenceSource = IoGPersistenceManager.PersistenceSource.FileStorage
		let saveArray = IoGTestConfigurationManager.persistenceTestArrayValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveArray, type: IoGPersistenceManager.PersistenceDataType.Array, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! [String]
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue.count, saveArray.count)
		for elementIndex in 0..<readValue.count
			{
			XCTAssertEqual(readValue[elementIndex], saveArray[elementIndex])
			}
    }

    func testSaveDictionary()
    {
		let persistenceSource = IoGPersistenceManager.PersistenceSource.Memory
		let saveDictionary = IoGTestConfigurationManager.persistenceTestDictionaryValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveDictionary, type: IoGPersistenceManager.PersistenceDataType.Dictionary, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Session, expiration: nil, overwrite: false)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! [String : Any]
		let keys = saveDictionary.keys
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue.count, saveDictionary.count)
		for nextKey in keys
			{
			if let newValue = readValue[nextKey] as? Int, let oldValue = saveDictionary[nextKey] as? Int
				{
				XCTAssertEqual(newValue, oldValue)
				}
			else if let newValue = readValue[nextKey] as? String, let oldValue = saveDictionary[nextKey] as? String
				{
				XCTAssertEqual(newValue, oldValue)
				}
			else
				{
				XCTFail()
				}
			}
    }

    func testSaveData()
    {
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let saveDictionary = IoGTestConfigurationManager.persistenceTestDictionaryValue
		do
			{
			let saveData = try JSONSerialization.data(withJSONObject: saveDictionary, options: [])
			let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveData, type: IoGPersistenceManager.PersistenceDataType.Data, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
			XCTAssertTrue(saveResult)
			}
		catch
			{
			XCTFail()
			}
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! Data
		do
			{
			if let returnedDictionary = try JSONSerialization.jsonObject(with: readValue, options: []) as? [String: String]
				{
				let keys = returnedDictionary.keys
				XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
				XCTAssertEqual(returnedDictionary.count, saveDictionary.count)
				for nextKey in keys
					{
					let originalValue = saveDictionary[nextKey] as! String
					XCTAssertEqual(returnedDictionary[nextKey], originalValue)
					}
				}
			else
				{
				XCTFail()
				}
			}
		catch
			{
			XCTFail()
			}
    }

	func testSaveToMemory()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.Memory
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
    }

	func testSaveToUserDefaults()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
    }

	func testSaveToFile()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.FileStorage
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
    }

	func testFailRead()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.NotFound)
		XCTAssertNil(readValue)
	}

	func testOverwriteSave()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let firstSaveString = IoGTestConfigurationManager.persistenceTestStringValue
		let secondSaveString = IoGTestConfigurationManager.persistenceTestSecondaryStringValue
		var saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: firstSaveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: secondSaveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, secondSaveString)
    }

	func testFailOverwrite()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let firstSaveString = IoGTestConfigurationManager.persistenceTestStringValue
		let secondSaveString = IoGTestConfigurationManager.persistenceTestSecondaryStringValue
		var saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: firstSaveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: secondSaveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: false)
		XCTAssertFalse(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, firstSaveString)
    }

	func testClearValueSucceed()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		var readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		var readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
		let clearResult = persitenceManager.clearValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		XCTAssertTrue(clearResult)
		readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		readResult = readResponse.result
		let readClearedValue = readResponse.value
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.NotFound)
		XCTAssertNil(readClearedValue)
    }

	func testClearValueFail()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let clearResult = persitenceManager.clearValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		XCTAssertFalse(clearResult)
	}

	func testCheckForValuePresent()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
		let checkResult = persitenceManager.checkForValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		XCTAssertTrue(checkResult)
    }

	func testCheckForValueMissing()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let checkResult = persitenceManager.checkForValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		XCTAssertFalse(checkResult)
	}

	func testImmortalSave()
	{
		configurationManager.setSessionActive(state: true)
		let persistenceSource = IoGPersistenceManager.PersistenceSource.Memory
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		configurationManager.setSessionActive(state: false)
		let readResponse = persitenceManager.readValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		let readResult = readResponse.result
		let readValue = readResponse.value as! String
		XCTAssertEqual(readResult, IoGPersistenceManager.PersistenceReadResultCode.Success)
		XCTAssertEqual(readValue, saveString)
	}

	func testSessionSave()
	{
		configurationManager.setSessionActive(state: true)
		let persistenceSource = IoGPersistenceManager.PersistenceSource.Memory
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		XCTAssertTrue(saveResult)
		configurationManager.setSessionActive(state: false)
		let checkResult = persitenceManager.checkForValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
		XCTAssertFalse(checkResult)
	}

	func testExpiringSave()
	{
		let persistenceSource = IoGPersistenceManager.PersistenceSource.UserDefaults
		let saveString = IoGTestConfigurationManager.persistenceTestStringValue
		let expiration = Date.init().addingTimeInterval(IoGTestConfigurationManager.persistenceTestExpiration)
		let saveResult = persitenceManager.saveValue(name: IoGTestConfigurationManager.persistenceTestSaveName, value: saveString, type: IoGPersistenceManager.PersistenceDataType.String, destination: persistenceSource, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Expiration, expiration: expiration, overwrite: true)
		XCTAssertTrue(saveResult)
		let expirationExpectation = expectation(description: "Expiration time achieved")
		Timer.scheduledTimer(withTimeInterval: IoGTestConfigurationManager.persistenceTestExpirationCheck, repeats: true)
			{
			timer in
			let checkResult = self.persitenceManager.checkForValue(name: IoGTestConfigurationManager.persistenceTestSaveName, from: persistenceSource)
			XCTAssertFalse(checkResult)
			expirationExpectation.fulfill()
			}
		waitForExpectations(timeout: IoGTestConfigurationManager.persistenceTestExpirationCheckTimeout, handler: nil)
    }
}
