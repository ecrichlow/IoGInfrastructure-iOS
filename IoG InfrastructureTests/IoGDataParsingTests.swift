//
//  IoGDataParsingTests.swift
//  IoG InfrastructureTests
//
//  Created by Eric Crichlow on 1/16/19.
//  Copyright © 2018 Infusions of Grandeur. All rights reserved.
//

import XCTest
@testable import IoG_Infrastructure

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
}
