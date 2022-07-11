/*
********************************************************************************
* IoGDataParsingTests.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the Data Parsing tests
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	01/16/19		*	EGC	*	File creation date
********************************************************************************
*/

import XCTest
@testable import IoGInfrastructure

class IoGDataParsingTests: XCTestCase
{

    override func setUp()
    {
        super.setUp()
    }

    override func tearDown()
    {
        super.tearDown()
    }

	func testParseSingleObject()
	{
		let computer = IoGDataObjectManager.sharedManager.parseObject(objectString: IoGTestConfigurationManager.parsingObjectData, toObject: TestComputerObject.self)
		XCTAssertNotNil(computer)
		XCTAssertEqual(computer.model, "TRS-80 Color Computer 2")
		XCTAssertEqual(computer.processor, "6809")
	}

	func testFailedObjectParse()
	{
		let computer = IoGDataObjectManager.sharedManager.parseObject(objectString: "", toObject: TestComputerObject.self)
		XCTAssertNotNil(computer)
		XCTAssertEqual(computer.model, "")
		XCTAssertEqual(computer.processor, "")
	}

	func testParseObjectArray()
	{
		let computerArray = IoGDataObjectManager.sharedManager.parseArray(arrayString: IoGTestConfigurationManager.parsingObjectArrayData, forObject: TestComputerObject.self)
		XCTAssertEqual(computerArray.count, 3)
		var index = 0
		for nextComputer in computerArray
			{
			switch index
				{
				case 0:
					XCTAssertNotNil(nextComputer)
					XCTAssertEqual(nextComputer.model, "TRS-80 Color Computer 2")
					XCTAssertEqual(nextComputer.processor, "6809")
				case 1:
					XCTAssertNotNil(nextComputer)
					XCTAssertEqual(nextComputer.model, "TRS-80 Color Computer 3")
					XCTAssertEqual(nextComputer.processor, "68B09E")
				case 2:
					XCTAssertNotNil(nextComputer)
					XCTAssertEqual(nextComputer.model, "MM/1")
					XCTAssertEqual(nextComputer.processor, "68070")
				default:
					break
				}
			index += 1
			}
	}

	func testFailedArrayParse()
	{
		let computerArray = IoGDataObjectManager.sharedManager.parseArray(arrayString: "", forObject: TestComputerObject.self)
		XCTAssertEqual(computerArray.count, 0)
	}

	func testRetrieveUnlabeledProperty()
	{
		let computer = IoGDataObjectManager.sharedManager.parseObject(objectString: IoGTestConfigurationManager.parsingObjectData, toObject: TestComputerObject.self)
		let year = computer.getValue("year") as! String
		XCTAssertNotNil(computer)
		XCTAssertEqual(year, "1980")
	}

	func testSuccessfulDataStore()
	{
		let computer = IoGDataObjectManager.sharedManager.parseObject(objectString: IoGTestConfigurationManager.parsingObjectData, toObject: TestComputerObject.self)
		XCTAssertNotNil(computer)
		XCTAssertEqual(computer.model, "TRS-80 Color Computer 2")
		XCTAssertEqual(computer.processor, "6809")
		computer.setValue(key: "model", value: "TRS-80 Color Computer 3")
		computer.setValue(key: "processor", value: "68B09E")
		XCTAssertEqual(computer.model, "TRS-80 Color Computer 3")
		XCTAssertEqual(computer.processor, "68B09E")
		let encoder = JSONEncoder()
		if let data = try? encoder.encode(computer)
			{
			UserDefaults.standard.set(data, forKey: "TestData")
			}
		else
			{
			XCTFail()
			}
		if UserDefaults.standard.object(forKey: "TestData") != nil
			{
			if let savedObjectData = UserDefaults.standard.object(forKey: "TestData") as? Data
				{
				let decoder = JSONDecoder()
				if let savedComputer = try? decoder.decode(TestComputerObject.self, from: savedObjectData)
					{
					XCTAssertEqual(savedComputer.model, "TRS-80 Color Computer 3")
					XCTAssertEqual(savedComputer.processor, "68B09E")
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

}
