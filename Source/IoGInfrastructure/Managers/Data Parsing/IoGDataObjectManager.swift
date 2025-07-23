/*
********************************************************************************
* IoGDataObjectManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for constructing
*						business objects from raw JSON input
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	01/15/19		*	EGC	*	File creation date
*	02/04/22		*	EGC	*	Adding support for Codable, removing NS types
*	06/18/22		*	EGC	*	Added DocC support
*	06/03/25		*	EGC	*	Added support for nested base objects
*	07/23/25		*	EGC	*	Added support for nested base arrays
********************************************************************************
*/

import Foundation

/// Singleton class that generates IoGDataObject instances and arrays from supplied JSON string
public class IoGDataObjectManager
{

	/// Returns the shared Data Object Manager instance.
	public static let sharedManager = IoGDataObjectManager()

	// MARK: Business Logic

	/// Parses JSON string for a single JSON object and returns an instance of the provided type, which must be a subclass of IoGDataObject
	public func parseObject<T: IoGDataObject>(objectString: String, toObject: T.Type) -> T
	{
		return T.init(withString: objectString)
	}

	/// Parses JSON string for a single JSON object, where all of the necessary data comes from a dictionary within the JSON object, and returns an instance of the provided type, which must be a subclass of IoGDataObject
	public func parseObject<T: IoGDataObject>(objectString: String, toObject: T.Type, fromBaseElement: String) -> T
	{
		if let objectData = objectString.data(using: .utf8)
			{
			do
				{
				let jsonDict = try JSONSerialization.jsonObject(with: objectData, options: []) as? [String: Any]
				if let element = jsonDict?[fromBaseElement] as? [String: Any]
					{
					let elementData = try JSONSerialization.data(withJSONObject: element)
					return parseObject(objectData: elementData, toObject: toObject)
					}
				}
			catch
				{
				}
			}
		return T.init(withString: "")
	}

	/// Parses Data object containing JSON string for a single JSON object and returns an instance of the provided type, which must be a subclass of IoGDataObject
	public func parseObject<T: IoGDataObject>(objectData: Data, toObject: T.Type) -> T
	{
		let contentString = String(decoding: objectData, as: UTF8.self)
		return parseObject(objectString: contentString, toObject: toObject)
	}

	/// Parses JSON string for an array of JSON objects and returns an array of the provided type, which must be a subclass of IoGDataObject
	public func parseArray<T: IoGDataObject>(arrayString: String, forObject: T.Type) -> [T]
	{
		var objectArray = [T]()
		let data = Data(arrayString.utf8)
		do
			{
			let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataArray = jsonArray as? [Any]
				{
				for nextObject in dataArray
					{
					let jsonData = try JSONSerialization.data(withJSONObject: nextObject, options: [])
					if let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
						{
						objectArray.append(T.init(withString: jsonString))
						}
					}
				}
			}
		catch
			{
			}

		return objectArray
	}

	/// Parses JSON string for a single JSON object, where all of the necessary data comes from a dictionary within the JSON object, and returns an instance of the provided type, which must be a subclass of IoGDataObject
	public func parseArray<T: IoGDataObject>(arrayString: String, toObject: T.Type, fromBaseElement: String) -> [T]
	{
		if let objectData = arrayString.data(using: .utf8)
			{
			do
				{
				let jsonDict = try JSONSerialization.jsonObject(with: objectData, options: []) as? [String: Any]
				if let element = jsonDict?[fromBaseElement] as? [String: Any]
					{
					let elementData = try JSONSerialization.data(withJSONObject: element)
					return parseArray(arrayData: elementData, forObject: toObject)
					}
				}
			catch
				{
				}
			}
		return [T.init(withString: "")]
	}

	/// Parses Data object containing JSON string for an array of JSON objects and returns an array of the provided type, which must be a subclass of IoGDataObject
	public func parseArray<T: IoGDataObject>(arrayData: Data, forObject: T.Type) -> [T]
	{
		let contentString = String(decoding: arrayData, as: UTF8.self)
		return parseArray(arrayString: contentString, forObject: forObject)
	}
}
