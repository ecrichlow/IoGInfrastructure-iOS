/*
********************************************************************************
* IoGPersistenceManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for memory, User Defaults
*						and file storage
* Author:			Eric Crichlow
* Version:			2.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	05/05/18		*	EGC	*	File creation date
*	11/06/18		*	EGC	*	Addition of file support
*	02/16/22		*	EGC	*	Added support for secure storage
*	06/18/22		*	EGC	*	Added DocC support
********************************************************************************
*/

import Foundation
import CryptoKit

/// Singleton class that manages storage in memory, in User Defaults, or in a file
///
/// > Note: Secure storage only applies to string values
public class IoGPersistenceManager
{

	/// Location of the data storage
	public enum PersistenceSource : Int
	{
		/// Data to be stored in memory, does not persist beyond application shutdown
		case Memory
		/// Data to be stored in User Defaults, susceptible to app actions that affect the application's User Defaults space
		case UserDefaults
		/// Data to be stored in a file, in the application's private file storage area
		case FileStorage
	}

	/// Designation of whether or not data is encrupted
	public enum PersistenceProtectionLevel : Int
	{
		/// Data is stored unencrypted
		case Unsecured
		/// Data is stored encrypted
		case Secured
	}

	/// Designation of the length of time data is stored
	public enum PersistenceLifespan : Int
	{
		/// Data is stored for the lifetime of the application
		case Immortal
		/// Data is deleted once the session is ended
		case Session
		/// Data is deleted at a specified time
		case Expiration
	}

	/// Designates the type of data stored in a given record
	public enum PersistenceDataType : Int
	{
		case Number
		case String
		case Array
		case Dictionary
		case Data
	}

	/// Denotes the result of a data read request
	public enum PersistenceReadResultCode : Int
	{
		/// Data was read successfully
		case Success
		/// No data was found corresponding to the requested name
		case NotFound
// 06-18-22 - EGC - Removing "expired" as a potential result, as there is no way of determining that an expired item ever existed
//		case Expired
// 02-17-22 - EGC - Added case to cover secure storage retrieval failures
		/// Decryption of secured data failed
		case ProtectionError
	}

	/// Returns the shared Persistence Manager instance.
	public static let sharedManager = IoGPersistenceManager()

	var memoryStore = [String: Dictionary<String, Any>]()

	init()
	{
		Timer.scheduledTimer(withTimeInterval: IoGConfigurationManager.timerPeriodPersistenceExpirationCheck, repeats: true) {timer in self.checkForExpiredItems()}
	}

	/// Store a value to storage
	///
	///  - Parameters:
	///  	- name: Key name to store value under
	///  	- value: Data to be stored
	///  	- type: The Foundation or Swift Standard Library type of the data to be stored
	///  	- destination: The location of the data to be stored
	///  	- protection: Designates whether the data is secured or unsecured
	///  	- lifespan: Designates when and if the data is deleted
	///  	- expiration: If the lifespan is Expiration bound, the time at which the data should expire and be deleted
	///  	- overwrite: If a record with the given name already exists, whether or not to overwrite it with the new data
	///  	- key: If using a custom symmetric key instead of the default key created by IoGInfrastructure, the key to encrypt the secured data with
	///
	///  - Returns: Whether or not the save operation was successful
	@discardableResult public func saveValue(name: String, value: Any, type: PersistenceDataType, destination: PersistenceSource, protection: PersistenceProtectionLevel, lifespan: PersistenceLifespan, expiration: Date?, overwrite: Bool, key: SymmetricKey? = nil) -> Bool
	{
		var savedDataElement = [String: Any]()
		if protection == .Secured
			{
			if let plainString = value as? String
				{
				if let symmetricKey = key
					{
					if let encryptedEncodedString = EncryptionKeyManager.sharedManager.encryptAndEncodeString(string: plainString, key: symmetricKey)
						{
						savedDataElement[IoGConfigurationManager.persistencElementValue] = encryptedEncodedString
						}
					else
						{
						return false
						}
					}
				else
					{
					if let encryptedEncodedString = EncryptionKeyManager.sharedManager.encryptAndEncodeString(string: plainString)
						{
						savedDataElement[IoGConfigurationManager.persistencElementValue] = encryptedEncodedString
						}
					else
						{
						return false
						}
					}
				}
			else
				{
				return false
				}
			}
		else
			{
			savedDataElement[IoGConfigurationManager.persistencElementValue] = value
			}
		savedDataElement[IoGConfigurationManager.persistencElementType] = type.rawValue
		savedDataElement[IoGConfigurationManager.persistencElementSource] = destination.rawValue
		savedDataElement[IoGConfigurationManager.persistencElementProtection] = protection.rawValue
		savedDataElement[IoGConfigurationManager.persistencElementLifespan] = lifespan.rawValue
		savedDataElement[IoGConfigurationManager.persistencElementExpiration] = expiration
		if lifespan == .Expiration && expiration == nil
			{
			return false
			}
		if destination == .Memory
			{
			if memoryStore[name] == nil || overwrite
				{
				memoryStore[name] = savedDataElement
				}
			else if memoryStore[name] != nil && !overwrite
				{
				return false
				}
			}
		else if destination == .UserDefaults
			{
			if UserDefaults.standard.object(forKey: name) == nil || overwrite
				{
				UserDefaults.standard.set(savedDataElement, forKey: name)
				UserDefaults.standard.synchronize()
				}
			else if UserDefaults.standard.object(forKey: name) != nil && !overwrite
				{
				return false
				}
			}
		else if destination == .FileStorage
			{
			let homePathString = NSHomeDirectory()
			let persistencePathString = homePathString + IoGConfigurationManager.persistenceFolderPath
			let destFilePathString = persistencePathString + "/" + name
			let dictionary = savedDataElement as NSDictionary
			if !FileManager.default.fileExists(atPath: persistencePathString)
				{
				do
					{
					try FileManager.init().createDirectory(atPath: persistencePathString, withIntermediateDirectories: true, attributes: nil)
					}
				catch
					{
					return (false);
					}
				}
			if !FileManager.default.fileExists(atPath: destFilePathString)
				{
				let destFileURL = URL(fileURLWithPath: destFilePathString)
				if dictionary.write(to: destFileURL, atomically: true) == false
					{
					return false
					}
				}
			else if overwrite
				{
				do
					{
					try FileManager.default.removeItem(atPath: destFilePathString)
					let destFileURL = URL(fileURLWithPath: destFilePathString)
					if dictionary.write(to: destFileURL, atomically: true) == false
						{
						return false
						}
					}
				catch
					{
					return (false);
					}
				}
			else
				{
				return false
				}
			}
		if lifespan == .Session
			{
			if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementSessionItems) == nil
				{
				let sessionItemEntry = [[IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue]]
				UserDefaults.standard.set(sessionItemEntry, forKey: IoGConfigurationManager.persistenceManagementSessionItems)
				UserDefaults.standard.synchronize()
				}
			else
				{
				if let items = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementSessionItems) as? [[String: Any]]
					{
					var sessionItems = items
					sessionItems.append([IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue])
					UserDefaults.standard.set(sessionItems, forKey: IoGConfigurationManager.persistenceManagementSessionItems)
					UserDefaults.standard.synchronize()
					}
				}
			}
		else if lifespan == .Expiration
			{
			if let expirationDate = expiration
				{
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
				var dirty = false
				// First, remove any expiring item already existing for the same name
				if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) != nil
					{
					var expiringItemEntries = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) as! Dictionary<String, [[String: Any]]>
					for nextExpirationDate in expiringItemEntries.keys
						{
						if let _ = dateFormatter.date(from: nextExpirationDate)
							{
							let expiringItemList = expiringItemEntries[nextExpirationDate]
							var freshItemList = expiringItemList
							var entryDirty = false
							for nextItemIndex in stride(from: expiringItemList!.count-1, through: 0, by: -1)
								{
								let nextItem = expiringItemList![nextItemIndex]
								let nextItemName = nextItem[IoGConfigurationManager.persistenceExpirationItemName] as! String
								if nextItemName == name
									{
									freshItemList!.remove(at: nextItemIndex)
									entryDirty = true
									dirty = true
									}
								}
							if entryDirty
								{
								if freshItemList!.count == 0
									{
									expiringItemEntries.removeValue(forKey: nextExpirationDate)
									}
								else
									{
									expiringItemEntries[nextExpirationDate] = freshItemList!
									}
								}
							}
						}
					if dirty
						{
						if expiringItemEntries.count == 0
							{
							UserDefaults.standard.removeObject(forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
							}
						else
							{
							UserDefaults.standard.set(expiringItemEntries, forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
							}
						UserDefaults.standard.synchronize()
						}
					}
				// Then, add the new expiring item
				let dateString = dateFormatter.string(from: expirationDate)
				if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) == nil
					{
					let expiringItemEntries = [dateString: [[IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue]]]
					UserDefaults.standard.set(expiringItemEntries, forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
					UserDefaults.standard.synchronize()
					}
				else
					{
					var expiringItemEntries = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) as! Dictionary<String, [[String: Any]]>
					if var dateExpiringItemList = expiringItemEntries[dateString]
						{
						dateExpiringItemList.append([IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue])
						expiringItemEntries[dateString] = dateExpiringItemList
						}
					else
						{
						expiringItemEntries[dateString] = [[IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue]]
						}
					UserDefaults.standard.set(expiringItemEntries, forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
					UserDefaults.standard.synchronize()
					}
				}
			else
				{
				return false
				}
			}
		return true
	}

	/// Read a value from storage
	///
	///  - Parameters:
	///  	- name: Key name that the value is stored under
	///  	- from: The location of the data to be retrieved
	///  	- key: If using a custom symmetric key instead of the default key created by IoGInfrastructure, the key to decrypt the secured data with
	///
	///  - Returns: The result of the read attempt and, if successful, the retrieved value
	public func readValue(name: String, from: PersistenceSource, key: SymmetricKey? = nil) -> (result: PersistenceReadResultCode, value: Any?)
	{
		if from == .Memory
			{
			if memoryStore[name] == nil
				{
				return (result: .NotFound, value: nil)
				}
			else
				{
				let savedDataElement = memoryStore[name]!
				let value = savedDataElement[IoGConfigurationManager.persistencElementValue]
// 02-17-22 - EGC - Added support for encryption
				if let protection = savedDataElement[IoGConfigurationManager.persistencElementProtection] as? Int
					{
					if protection == PersistenceProtectionLevel.Secured.rawValue
						{
						if let encodedString = value as? String
							{
							if let symmetricKey = key
								{
								if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString, key: symmetricKey)
									{
									return (result: .Success, value: decodedString)
									}
								else
									{
									return (result: .ProtectionError, value: value)
									}
								}
							else
								{
								if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString)
									{
									return (result: .Success, value: decodedString)
									}
								else
									{
									return (result: .ProtectionError, value: value)
									}
								}
							}
						else
							{
							return (result: .ProtectionError, value: value)
							}
						}
					else
						{
						return (result: .Success, value: value)
						}
					}
				else
					{
					return (result: .ProtectionError, value: value)
					}
				}
			}
		else if from == .UserDefaults
			{
			if UserDefaults.standard.object(forKey: name) == nil
				{
				return (result: .NotFound, value: nil)
				}
			else
				{
				let savedDataElement = UserDefaults.standard.object(forKey: name) as! Dictionary<String, Any>
				let value = savedDataElement[IoGConfigurationManager.persistencElementValue]
// 02-17-22 - EGC - Added support for encryption
				if let protection = savedDataElement[IoGConfigurationManager.persistencElementProtection] as? Int
					{
					if protection == PersistenceProtectionLevel.Secured.rawValue
						{
						if let encodedString = value as? String
							{
							if let symmetricKey = key
								{
								if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString, key: symmetricKey)
									{
									return (result: .Success, value: decodedString)
									}
								else
									{
									return (result: .ProtectionError, value: value)
									}
								}
							else
								{
								if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString)
									{
									return (result: .Success, value: decodedString)
									}
								else
									{
									return (result: .ProtectionError, value: value)
									}
								}
							}
						else
							{
							return (result: .ProtectionError, value: value)
							}
						}
					else
						{
						return (result: .Success, value: value)
						}
					}
				else
					{
					return (result: .ProtectionError, value: value)
					}
				}
			}
		else if from == .FileStorage
			{
			let homePathString = NSHomeDirectory()
			let persistencePathString = homePathString + IoGConfigurationManager.persistenceFolderPath
			let sourceFilePathString = persistencePathString + "/" + name
			if !FileManager.default.fileExists(atPath: sourceFilePathString)
				{
				return (result: .NotFound, value: nil)
				}
			else
				{
				if let url = URL.init(string: sourceFilePathString)
					{
					let fileURL = URL(fileURLWithPath: url.path)
					if let savedDataElement = NSDictionary.init(contentsOf: fileURL)
						{
						if savedDataElement.object(forKey: IoGConfigurationManager.persistencElementValue) != nil
							{
							let value = savedDataElement[IoGConfigurationManager.persistencElementValue]
// 02-17-22 - EGC - Added support for encryption
							if let protection = savedDataElement[IoGConfigurationManager.persistencElementProtection] as? Int
								{
								if protection == PersistenceProtectionLevel.Secured.rawValue
									{
									if let encodedString = value as? String
										{
										if let symmetricKey = key
											{
											if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString, key: symmetricKey)
												{
												return (result: .Success, value: decodedString)
												}
											else
												{
												return (result: .ProtectionError, value: value)
												}
											}
										else
											{
											if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString)
												{
												return (result: .Success, value: decodedString)
												}
											else
												{
												return (result: .ProtectionError, value: value)
												}
											}
										}
									else
										{
										return (result: .ProtectionError, value: value)
										}
									}
								else
									{
									return (result: .Success, value: value)
									}
								}
							else
								{
								return (result: .ProtectionError, value: value)
								}
							}
						else
							{
							return (result: .NotFound, value: nil)
							}
						}
					else
						{
						return (result: .NotFound, value: nil)
						}
					}
				else
					{
					return (result: .NotFound, value: nil)
					}
				}
			}
		return (result: .NotFound, value: nil)
	}

	/// Check for the existence of a value in storage
	///
	///  - Parameters:
	///  	- name: Key name that the value is stored under
	///  	- from: The location of the data to be searched for
	///
	///  - Returns: Whether or not a value was found for the given key name
	public func checkForValue(name: String, from: PersistenceSource) -> Bool
	{
		if from == .Memory
			{
			if memoryStore[name] == nil
				{
				return false
				}
			else
				{
				return true
				}
			}
		else if from == .UserDefaults
			{
			if UserDefaults.standard.object(forKey: name) == nil
				{
				return false
				}
			else
				{
				return true
				}
			}
		else if from == .FileStorage
			{
			let sourcePath = NSHomeDirectory()
			let srcPath = URL(fileURLWithPath: sourcePath)
			let srcFile = srcPath.appendingPathComponent("Documents").appendingPathComponent(name)
			if FileManager.default.fileExists(atPath: srcFile.path)
				{
				return true
				}
			}
		return false
	}

	/// Delete a value from storage
	///
	///  - Parameters:
	///  	- name: Key name that the value is stored under
	///  	- from: The location of the data to be searched for
	///
	///  - Returns: Whether or not the value was deleted
	@discardableResult public func clearValue(name: String, from: PersistenceSource) -> Bool
	{
		if checkForValue(name: name, from: from)
			{
			if from == .Memory
				{
				memoryStore[name] = nil
				return true
				}
			else if from == .UserDefaults
				{
				UserDefaults.standard.removeObject(forKey: name)
				UserDefaults.standard.synchronize()
				return true
				}
			else if from == .FileStorage
				{
				let sourcePath = NSHomeDirectory()
				let srcPath = URL(fileURLWithPath: sourcePath)
				let srcFile = srcPath.appendingPathComponent("Documents").appendingPathComponent(name)
				if FileManager.default.fileExists(atPath: srcFile.path)
					{
					do
						{
						try FileManager.default.removeItem(at: srcFile)
						return true
						}
					catch
						{
						return false
						}
					}
				}
			// Then clear any expiring values for the same name
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
			var dirty = false
			if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) != nil
				{
				var expiringItemEntries = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) as! Dictionary<String, [[String: Any]]>
				for nextExpirationDate in expiringItemEntries.keys
					{
					let expiringItemList = expiringItemEntries[nextExpirationDate]
					var freshItemList = expiringItemList
					var entryDirty = false
					for nextItemIndex in stride(from: expiringItemList!.count-1, through: 0, by: -1)
						{
						let nextItem = expiringItemList![nextItemIndex]
						let nextItemName = nextItem[IoGConfigurationManager.persistenceExpirationItemName] as! String
						if nextItemName == name
							{
							freshItemList!.remove(at: nextItemIndex)
							entryDirty = true
							dirty = true
							}
						}
					if entryDirty
						{
						if freshItemList!.count == 0
							{
							expiringItemEntries.removeValue(forKey: nextExpirationDate)
							}
						else
							{
							expiringItemEntries[nextExpirationDate] = freshItemList!
							}
						}
					}
				if dirty
					{
					if expiringItemEntries.count == 0
						{
						UserDefaults.standard.removeObject(forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
						}
					else
						{
						UserDefaults.standard.set(expiringItemEntries, forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
						}
					UserDefaults.standard.synchronize()
					}
				}
			}
		return false
	}

	private func checkForExpiredItems()
	{
		if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) != nil
			{
			let expiringItemEntries = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) as! Dictionary<String, [[String: Any]]>
			var freshItemEntries = expiringItemEntries
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
			for nextExpirationDateString in expiringItemEntries.keys
				{
				let nextExpirationDate = dateFormatter.date(from: nextExpirationDateString)
				if let expirationDate = nextExpirationDate
					{
					if expirationDate.timeIntervalSinceNow < 0
						{
						let expiringItemList = expiringItemEntries[nextExpirationDateString]
						for nextItem in expiringItemList!
							{
							let source = PersistenceSource(rawValue: nextItem[IoGConfigurationManager.persistenceExpirationItemSource] as! Int)
							let name = nextItem[IoGConfigurationManager.persistenceExpirationItemName] as! String
							if let src = source
								{
								clearValue(name: name, from: src)
								}
							}
						freshItemEntries.removeValue(forKey: nextExpirationDateString)
						}
					}
				}
			UserDefaults.standard.set(freshItemEntries, forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
			UserDefaults.standard.synchronize()
			}
	}

	internal func removeSessionItems()
	{
		if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementSessionItems) != nil
			{
			let sessionItemEntries = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementSessionItems) as! [[String: Any]]
			for nextSessionItem in sessionItemEntries
				{
				let source = PersistenceSource(rawValue: nextSessionItem[IoGConfigurationManager.persistenceExpirationItemSource] as! Int)
				let name = nextSessionItem[IoGConfigurationManager.persistenceExpirationItemName] as! String
				if let src = source
					{
					clearValue(name: name, from: src)
					}
				}
			}
		UserDefaults.standard.removeObject(forKey: IoGConfigurationManager.persistenceManagementSessionItems)
		UserDefaults.standard.synchronize()
	}
}
