/*
********************************************************************************
* EncryptionKeyManagerTests.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the EncryptionKeyManager tests
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	02/19/22		*	EGC	*	File creation date
********************************************************************************
*/

import XCTest
import CryptoKit
@testable import IoG_Infrastructure

class EncryptionKeyManagerTests: XCTestCase
{

    override func setUp()
    {
        super.setUp()
    }

    override func tearDown()
    {
        super.tearDown()
    }

    func testEncryptDecryptWithDefaultKey()
    {
		let encodedString = EncryptionKeyManager.sharedManager.encryptAndEncodeString(string: IoGTestConfigurationManager.stringToEncrypt)
		XCTAssertNotNil(encodedString)
		XCTAssertNotEqual(encodedString, IoGTestConfigurationManager.stringToEncrypt)
		let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString!)
		XCTAssertNotNil(decodedString)
		XCTAssertEqual(decodedString, IoGTestConfigurationManager.stringToEncrypt)
    }

    func testEncryptDecryptWithCustomKey()
    {
		let key = SymmetricKey(size: IoGConfigurationManager.symmetricKeySize)
		let encodedString = EncryptionKeyManager.sharedManager.encryptAndEncodeString(string: IoGTestConfigurationManager.stringToEncrypt, key: key)
		XCTAssertNotNil(encodedString)
		XCTAssertNotEqual(encodedString, IoGTestConfigurationManager.stringToEncrypt)
		let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString!, key: key)
		XCTAssertNotNil(decodedString)
		XCTAssertEqual(decodedString, IoGTestConfigurationManager.stringToEncrypt)
    }
}
