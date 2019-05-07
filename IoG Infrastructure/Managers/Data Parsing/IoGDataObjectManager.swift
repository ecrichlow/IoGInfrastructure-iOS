/*******************************************************************************
* IoGDataObjectManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for constructing
*						business objects from raw input
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	01/15/19		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

public class IoGDataObjectManager
{

	public static let sharedManager = IoGDataObjectManager()

	public func parseObject<T: IoGDataObject>(objectString: String, toObject: T.Type) -> T
	{
		return T.init(withString: objectString)
	}

	public func parseArray<T: IoGDataObject>(arrayString: String, forObject: T.Type) -> [T]
	{
		var objectArray = [T]()
		let data = Data(arrayString.utf8)
		do
			{
			let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataArray = jsonArray as? NSArray
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
}
