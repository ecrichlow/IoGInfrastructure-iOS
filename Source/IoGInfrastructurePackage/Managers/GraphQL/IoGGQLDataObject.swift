/*
********************************************************************************
* IoGGQLDataObject.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
 *						This file contains the the base class for business
 *						objects constructed from GraphQL data, which should
 *						generally be subclassed with properties for the fields
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/29/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation

open class IoGGQLDataObject
{

	// MARK: Instance Methods

	required public init()
	{
	}

	// MARK: Business Logic
	public func setProperty(name: String, value: Any?)
	{
		/*	Example switch implementation
		switch name
			{
			case: "name"
			self.name = value as type
			}
		 */
		preconditionFailure("This method must be overridden")
	}
}
