/*******************************************************************************
* IoGMockDataManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the mock implementation of the class
*						for the manager for retrieving remote data
* Author:			Eric Crichlow
* Version:			1.0
* Copyright:		(c) 2018 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	10/01/18		*	EGC	*	File creation date
*******************************************************************************/

import Foundation

class IoGMockDataManager : IoGDataManager
{

	// MARK: Business Logic

	@discardableResult override func transmitRequest(request: URLRequest, type: IoGDataRequestType) -> Int?
	{
		return nil
	}

	override func continueMultiPartRequest(multiPartResponse: IoGDataRequestResponse)
	{
	}
}
