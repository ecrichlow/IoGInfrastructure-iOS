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
********************************************************************************
*/

import Foundation

public class IoGPersistenceManager
{
	public enum PersistenceSource : Int
	{
		case Memory
		case UserDefaults
		case FileStorage
	}

	public enum PersistenceProtectionLevel : Int
	{
		case Unsecured
		case Secured
	}

	public enum PersistenceLifespan : Int
	{
		case Immortal
		case Session
		case Expiration
	}

	public enum PersistenceDataType : Int
	{
		case Number
		case String
		case Array
		case Dictionary
		case Data
	}

	public enum PersistenceReadResultCode : Int
	{
		case Success
		case NotFound
		case Expired
// 02-17-22 - EGC - Added case to cover secure storage retrieval failures
		case ProtectionError
	}

	public static let sharedManager = IoGPersistenceManager()

	var memoryStore = [String: Dictionary<String, Any>]()

	init()
	{
		Timer.scheduledTimer(withTimeInterval: IoGConfigurationManager.timerPeriodPersistenceExpirationCheck, repeats: true) {timer in self.checkForExpiredItems()}
	}

	@discardableResult public func saveValue(name: String, value: Any, type: PersistenceDataType, destination: PersistenceSource, protection: PersistenceProtectionLevel, lifespan: PersistenceLifespan, expiration: Date?, overwrite: Bool) -> Bool
	{
		var savedDataElement = [String: Any]()
		if protection == .Secured
			{
			if let plainString = value as? String
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

	public func readValue(name: String, from: PersistenceSource) -> (result: PersistenceReadResultCode, value: Any?)
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
							if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString)
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
							if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString)
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
										if let decodedString = EncryptionKeyManager.sharedManager.decodeAndDecryptString(encodedString: encodedString)
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

	public func checkForExpiredItems()
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

	public func removeSessionItems()
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
