/*
********************************************************************************
* IoGDataObject.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the the base class for business
*						objects constructed from (string) data, which should
*						generally be subclassed with properties for the fields
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	01/15/19		*	EGC	*	File creation date
*	02/04/22		*	EGC	*	Adding support for Codable, removing NS types
*	06/18/22		*	EGC	*	Added DocC support
********************************************************************************
*/

import Foundation

/// The class that clients of the Data Manager subclass to define the business objects inflated by JSON strings
/// returned from calls to a back end.
///
/// Subclasses should add a var for each expected property in the format:
/// ``` swift
/// var title : String
/// {
/// 	get
/// 	{
/// 		if let content = getValue("title") as? String
/// 		{
/// 			return content
/// 		}
/// 		else
/// 		{
/// 			return ""
/// 		}
/// 	}
/// }
/// ```
///  Or return nil if the var is an optional and the value isn't found.
open class IoGDataObject: Codable
{

	private var sourceData : String!
	private var objectDictionary = [String: Any]()

	enum CodingKeys: String, CodingKey
	{
		case rawString
	}

	required public init(withString source: String)
	{
		sourceData = source
		let data = Data(source.utf8)
		do
			{
			let jsonDict = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataDictionary = jsonDict as? [String: Any]
				{
				objectDictionary = dataDictionary
				}
			}
		catch
			{
			}
	}

	public required init(from decoder: Decoder) throws
	{
		let values = try decoder.container(keyedBy: CodingKeys.self)
        sourceData = try values.decode(String.self, forKey: .rawString)
		let data = Data(sourceData.utf8)
		do
			{
			let jsonDict = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataDictionary = jsonDict as? [String: Any]
				{
				objectDictionary = dataDictionary
				}
			}
		catch
			{
			}
	}

	/// Encode necessary elements of the class
	public func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sourceData, forKey: .rawString)
	}

	/// Retrieve a value from the source data for a given key
	///
	///  - Parameters:
	///  	- key: The key for the desired value to retrieve
	///
	/// - Returns: The value associated with the requested key
	public func getValue(_ key: String) -> Any
	{
		if let value = objectDictionary[key]
			{
			return value
			}
		else
			{
			return String()
			}
	}
}
