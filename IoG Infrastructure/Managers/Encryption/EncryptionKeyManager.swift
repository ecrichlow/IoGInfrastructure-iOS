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

internal class EncryptionKeyManager
{

	public static let sharedManager = EncryptionKeyManager()

	init()
	{
	}

	private func getPublicKey() -> SecKey?
	{
		if let privateKey = getPrivateKey()
			{
			if let publicKey = SecKeyCopyPublicKey(privateKey)
				{
				return (publicKey)
				}
			else
				{
				if let private_key = getPrivateKey()
					{
					return SecKeyCopyPublicKey(private_key)
					}
				else
					{
					return nil
					}
				}
			}
		else
			{
			if let private_key = getPrivateKey()
				{
				return SecKeyCopyPublicKey(private_key)
				}
			else
				{
				return nil
				}
			}
	}

	private func getPrivateKey() -> SecKey?
	{
		let getquery: [String: Any] = [kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: IoGConfigurationManager.privateKeyIdentifier, kSecAttrKeyType as String: kSecAttrKeyTypeRSA, kSecReturnRef as String: true]
		var item: CFTypeRef?
		let status = SecItemCopyMatching(getquery as CFDictionary, &item)
		if status == errSecSuccess
			{
			let privateKey = item as! SecKey
			return privateKey
			}
		else
			{
			let keyPair = createKeypair()
			if let private_key = keyPair.privateKey
				{
				return private_key
				}
			else
				{
				return nil
				}
			}
	}

	private func createKeypair() -> (publicKey: SecKey?, privateKey: SecKey?)
    {
		let tag = IoGConfigurationManager.privateKeyIdentifier.data(using: .utf8)!
		let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA, kSecAttrKeySizeInBits as String: IoGConfigurationManager.rsaKeySize, kSecPrivateKeyAttrs as String:[kSecAttrIsPermanent as String: true, kSecAttrApplicationTag as String: tag]]
		var error: Unmanaged<CFError>?
		if let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
			{
			if let publicKey = SecKeyCopyPublicKey(privateKey)
				{
				return (publicKey, privateKey)
				}
			}
		return (nil, nil)
	}

	public func encryptAndEncodeString(string: String) -> String?
	{
		guard let publicKey = getPublicKey()
			else
				{
				return nil
				}
		let buffer = [UInt8](string.utf8)

		var keySize   = SecKeyGetBlockSize(publicKey)
		var keyBuffer = [UInt8](repeating: 0, count: keySize)

		guard SecKeyEncrypt(publicKey, SecPadding.PKCS1, buffer, buffer.count, &keyBuffer, &keySize) == errSecSuccess
		else
			{
			return nil
			}
		return Data(bytes: keyBuffer, count: keySize).base64EncodedString()
	}

	public func decodeAndDecryptString(encodedString: String) -> String?
	{
		if let privateKey = getPrivateKey()
			{
			var error: Unmanaged<CFError>? = nil
			let encryptedData = Data(base64Encoded: encodedString)! as CFData
			if let decryptedData = SecKeyCreateDecryptedData(privateKey, SecKeyAlgorithm.rsaEncryptionPKCS1, encryptedData, &error)
				{
				if let decodedString = String(data: decryptedData as Data, encoding: .utf8)
					{
					return decodedString
					}
				}
			}

		return nil
	}
}
