/*
********************************************************************************
* EncryptionKeyManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for Encryption functions
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	02/16/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation
import Security
import CryptoKit

internal class EncryptionKeyManager
{

	public static let sharedManager = EncryptionKeyManager()

	init()
	{
	}

	private func createSymmetricKey() -> SymmetricKey
	{
		let key = SymmetricKey(size: IoGConfigurationManager.symmetricKeySize)
		let keyString = key.withUnsafeBytes {Data(Array($0)).base64EncodedString()}
		IoGPersistenceManager.sharedManager.saveValue(name: IoGConfigurationManager.symmetricKeyIdentifier, value: keyString, type: IoGPersistenceManager.PersistenceDataType.String, destination: IoGPersistenceManager.PersistenceSource.UserDefaults, protection: IoGPersistenceManager.PersistenceProtectionLevel.Unsecured, lifespan: IoGPersistenceManager.PersistenceLifespan.Immortal, expiration: nil, overwrite: true)
		return key
	}

	private func getKey() -> SymmetricKey
	{
		if IoGPersistenceManager.sharedManager.checkForValue(name: IoGConfigurationManager.symmetricKeyIdentifier, from: IoGPersistenceManager.PersistenceSource.UserDefaults)
			{
			let readResponse = IoGPersistenceManager.sharedManager.readValue(name: IoGConfigurationManager.symmetricKeyIdentifier, from: IoGPersistenceManager.PersistenceSource.UserDefaults)
			let readResult = readResponse.result
			if readResult == IoGPersistenceManager.PersistenceReadResultCode.Success
				{
				if let encodedKey = readResponse.value as? String
					{
					if let keyData = Data(base64Encoded: encodedKey)
						{
						let key = SymmetricKey(data: keyData)
						return key
						}
					else
						{
						return createSymmetricKey()
						}
					}
				else
					{
					return createSymmetricKey()
					}
				}
			else
				{
				return createSymmetricKey()
				}
			}
		else
			{
			return createSymmetricKey()
			}
	}

	public func encryptAndEncodeString(string: String) -> String?
	{
		let key = getKey()
		do
			{
			if let data = string.data(using: .utf8)
				{
				let encryptedBoxData = try ChaChaPoly.seal(data, using: key)
				return encryptedBoxData.combined.base64EncodedString()
				}
			else
				{
				return nil
				}
			}
		catch
			{
			return nil
			}
	}

	public func decodeAndDecryptString(encodedString: String) -> String?
	{
		let key = getKey()
		if let encryptedData = Data(base64Encoded: encodedString, options: .ignoreUnknownCharacters)
			{
			do
				{
				let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedData)
				let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
				let decryptedString = String(data: decryptedData, encoding: .utf8)
				return decryptedString
				}
			catch
				{
				return nil
				}
			}
		return nil
	}
}
