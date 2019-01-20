/*******************************************************************************
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
*******************************************************************************/

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
		savedDataElement[IoGConfigurationManager.persistencElementValue] = value
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
				do
					{
					let destFileURL = URL(fileURLWithPath: destFilePathString)
					try dictionary.write(to: destFileURL)
					}
				catch
					{
					return (false);
					}
				}
			else if overwrite
				{
				do
					{
					try FileManager.default.removeItem(atPath: destFilePathString)
					let destFileURL = URL(fileURLWithPath: destFilePathString)
					try dictionary.write(to: destFileURL)
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
				}
			else
				{
				var sessionItems = UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementSessionItems) as! [[String: Any]]
				sessionItems.append([IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue])
				UserDefaults.standard.set(sessionItems, forKey: IoGConfigurationManager.persistenceManagementSessionItems)
				UserDefaults.standard.synchronize()
				}
			}
		else if lifespan == .Expiration
			{
			if let expirationDate = expiration
				{
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
				let dateString = dateFormatter.string(from: expirationDate)
				if UserDefaults.standard.object(forKey: IoGConfigurationManager.persistenceManagementExpiringItems) == nil
					{
					let expiringItemEntries = [dateString: [[IoGConfigurationManager.persistenceExpirationItemName: name, IoGConfigurationManager.persistenceExpirationItemSource: destination.rawValue]]]
					UserDefaults.standard.set(expiringItemEntries, forKey: IoGConfigurationManager.persistenceManagementExpiringItems)
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
				let savedDataElement = memoryStore[name] as! Dictionary<String, Any>
				let value = savedDataElement[IoGConfigurationManager.persistencElementValue]
				return (result: .Success, value: value)
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
				return (result: .Success, value: value)
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
					do
						{
						let fileURL = URL(fileURLWithPath: url.path)
						let savedDataElement = try NSDictionary.init(contentsOf: fileURL, error:())
						if savedDataElement.object(forKey: IoGConfigurationManager.persistencElementValue) != nil
							{
							let value = savedDataElement[IoGConfigurationManager.persistencElementValue]
							return (result: .Success, value: value)
							}
						else
							{
							return (result: .NotFound, value: nil)
							}
						}
					catch
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
