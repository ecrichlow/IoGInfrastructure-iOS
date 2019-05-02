/*******************************************************************************
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
*******************************************************************************/

import Foundation

open class IoGDataObject
{

	private var sourceData : String!
	private var objectDictionary = [String: Any]()

	required public init(withString source: String)
	{
		sourceData = source
		let data = Data(source.utf8)
		do
			{
			let jsonDict = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataDictionary = jsonDict as? NSDictionary
				{
				objectDictionary = dataDictionary as! [String: Any]
				}
			}
		catch
			{
			}
	}

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
