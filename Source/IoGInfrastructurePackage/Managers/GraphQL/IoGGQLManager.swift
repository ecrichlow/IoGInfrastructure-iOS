/*
********************************************************************************
* IoGGQLManager.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the manager for processing
*						interactions with GraphQL services
* Author:			Eric Crichlow
* Version:			3.0
* Copyright:		(c) 2022 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	06/20/22		*	EGC	*	File creation date
********************************************************************************
*/

import Foundation

/// Protocol the delegates of the GQL Manager must conform to in order to be notified of the final status of
/// a GraphQL request
public protocol IoGGQLManagerDelegate : AnyObject
{
	func gqlRequestResponseReceived(requestID: Int, requestType: IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: CustomGQLRequestType?, responseData: Any?, error: Error?)
}

public typealias CustomGQLRequestType = String

/// Singleton class that manages attempts to interact with GraphQL servers
public class IoGGQLManager: IoGDataManagerDelegate
{

	/// The request type, which is an identifier used by clients to differentiate between responses in the delegate method
	public enum IoGGQLRequestType
	{
		case Custom
		case Register
		case Login
		case Logout
		case ResetPassword
		case UserInfo
		case UpdateUserInfo
		case Features
		case Version
	}

	/// Returns the shared Data Manager instance.
	public static let sharedManager = IoGGQLManager()

	var delegateList = NSPointerArray.weakObjects()
	var outstandingRequests = [Int: [String: Any]]()		// Maintains a link between a GQLManager request and the corresponding DataManager request
	var requestID = 0

	// MARK: Instance Methods

	init()
	{
	}

	// MARK: Business Logic

	/// Register a delegate to receive a callback when the GraphQL operation completes
	public func registerDelegate(delegate: IoGGQLManagerDelegate)
	{
		for nextDelegate in delegateList.allObjects
			{
			if let del = nextDelegate as? IoGGQLManagerDelegate
				{
				if del === delegate
					{
					return
					}
				}
			}
		let pointer = Unmanaged.passUnretained(delegate as AnyObject).toOpaque()
		delegateList.addPointer(pointer)
	}

	/// Unregister a relegate from receiving a callback when the GraphQL operation completes
	public func unregisterDelegate(delegate: IoGGQLManagerDelegate)
	{
		var index = 0
		for nextDelegate in delegateList.allObjects
			{
			if let del = nextDelegate as? IoGGQLManagerDelegate
				{
				if del === delegate
					{
					break
					}
				index += 1
				}
			}
		if index < delegateList.count
			{
			delegateList.removePointer(at: index)
			}
	}

	/// Send GraphQL Query Request
	///
	///  - Parameters:
	///   - url: The URL string for the request
	///   - name: The name to assign to the query
	///   - parameters: The query parameters
	///   - type: One of the pre-defined identifiers used by delegates to differentiate the kind of request they are being notified about
	///   - target: The type of IoGGQLDataObject subclass for the manager to populate with the query response and return to the delegates
	///
	///  - Returns: An identifier for the request
	@discardableResult func transmitQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, type: IoGGQLRequestType, target: T.Type) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target), let requestURL = URL(string: url)
			{
			do
				{
				var urlRequest = URLRequest(url: requestURL)
				let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target)
				let jsonData = try JSONSerialization.data(withJSONObject: gqlQuery)
				urlRequest.httpBody = jsonData
				urlRequest.httpMethod = "POST"
				IoGDataManager.dataManagerOfDefaultType().registerDelegate(delegate: self)
				let dataManagerRequestID = IoGDataManager.dataManagerOfDefaultType().transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
				requestID += 1
				let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: type, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
				outstandingRequests[reqID] = requestInfo
				return reqID
				}
			catch
				{
				return -1
				}
			}
		return -1
	}

	/// Send GraphQL Query Request with custom type
	///
	///  - Parameters:
	///   - url: The URL string for the request
	///   - name: The name to assign to the query
	///   - parameters: The query parameters
	///   - customTypeIdentifier: A custom identifier used by delegates to differentiate the kind of request they are being notified about
	///   - target: The type of IoGGQLDataObject subclass for the manager to populate with the query response and return to the delegates
	///
	///  - Returns: An identifier for the request
	@discardableResult func transmitQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, customTypeIdentifier: CustomGQLRequestType, target: T.Type) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target), let requestURL = URL(string: url)
			{
			do
				{
				var urlRequest = URLRequest(url: requestURL)
				let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target)
				let jsonData = try JSONSerialization.data(withJSONObject: gqlQuery)
				urlRequest.httpBody = jsonData
				urlRequest.httpMethod = "POST"
				IoGDataManager.dataManagerOfDefaultType().registerDelegate(delegate: self)
				let dataManagerRequestID = IoGDataManager.dataManagerOfDefaultType().transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
				requestID += 1
				let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
				outstandingRequests[reqID] = requestInfo
				return reqID
				}
			catch
				{
				return -1
				}
			}
		return -1
	}

	@discardableResult internal func transmitTestQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, type: IoGGQLRequestType, target: T.Type) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target)
			let payloadData = Data(gqlQuery.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: type, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	@discardableResult internal func transmitTestQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, customTypeIdentifier: CustomGQLRequestType, target: T.Type) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target)
			let payloadData = Data(gqlQuery.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	private func buildGQLQueryString<T: IoGGQLDataObject>(name: String?, parameters: String?, target: T.Type) -> String
	{
		var queryString = "query "
		let targetName = String(NSStringFromClass(target.self))
		let targetComponents = targetName.components(separatedBy: ".")
		if let className = targetComponents.last
			{
			if let queryName = name
				{
				queryString += "\(queryName) "
				}
			queryString += "{\n"
			queryString += "\(className)"
			if let queryParameters = parameters
				{
				queryString += "(\(queryParameters))"
				}
			queryString += " "
			if let propertyObjectDefinition = parseTargetDataObject(target: target)
				{
				queryString += propertyObjectDefinition
				}
			queryString += "}\n"
			}
		return queryString
	}

	private func parseTargetDataObject<T: IoGGQLDataObject>(target: T.Type) -> String?
	{
		let typeInstance = target.init()	// Swift's reflection only works on instances, not class types, so we need to create a dummy instance
		let mirror = Mirror(reflecting: typeInstance)
		var gqlObjectDefinition = "{\n"
		for child in mirror.children
			{
			if child.value is IoGGQLDataObject
				{
				if let childObject = child.value as? IoGGQLDataObject
					{
					if let propertyObjectDefinition = parseTargetDataObject(target: type(of: childObject).self), let innerClassName = child.label
						{
						gqlObjectDefinition += "\(innerClassName) \(propertyObjectDefinition)"
						}
					}
				}
			else if child.value is NSArray
				{
				if let childArray = child.value as? NSArray, let childName = child.label
					{
					let arrayDefinition = parseArray(array: childArray as NSArray, name: childName)
					if let propertyName = child.label
						{
						gqlObjectDefinition += "\(propertyName) \(arrayDefinition)"
						}
					}
				}
			else
				{
				if let propertyName = child.label
					{
					gqlObjectDefinition += "\(propertyName)\n"
					}
				}
			}
		gqlObjectDefinition += "}\n"
		return gqlObjectDefinition
	}

	private func parseArray(array: NSArray, name: String?) -> String
	{
		var arrayDefinition = ""

		if let arrayObject = array.firstObject
			{
			if arrayObject is IoGGQLDataObject
				{
				if let propertyType = type(of: arrayObject) as? IoGGQLDataObject.Type
					{
					if let propertyObjectDefinition = parseTargetDataObject(target: propertyType.self)
						{
						arrayDefinition += propertyObjectDefinition
						}
					}
				else if arrayObject is NSArray
					{
					if let childArray = arrayObject as? NSArray
						{
						let subarrayDefinition = parseArray(array: childArray as NSArray, name: name)
						if let propertyObjectName = name
							{
							arrayDefinition += "\(propertyObjectName) \(subarrayDefinition)"
							}
						else
							{
							arrayDefinition += "\(subarrayDefinition)"
							}
						}
					}
				else
					{
					if let propertyObjectName = name
						{
						arrayDefinition += "\(propertyObjectName)\n"
						}
					}
				}
			}
		return arrayDefinition

	}

	private func isGQLResponsePlural(content: String) -> Bool
	{
		let data = Data(content.utf8)
		do
			{
			let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataDictionary = jsonData as? [String: Any]
				{
				if dataDictionary.keys.count == 1
					{
					if let key = dataDictionary.keys.first
						{
						if let _ = dataDictionary[key] as? NSArray
							{
							return true
							}
						}
					}
				}
			}
		catch
			{
			}
		return false
	}

	private func parseGQLResponse(dataDictionary: [String: Any]) -> String?
	{
		do
			{
			let jsonData = try JSONSerialization.data(withJSONObject: dataDictionary)
			let contentString = String(decoding: jsonData, as: UTF8.self)
			return contentString
			}
		catch
			{
			return nil
			}
	}

	private func populateDataObject<T: IoGGQLDataObject>(data: String, target: T.Type) -> T
	{
		let dataObject = Data(data.utf8)
		do
			{
			let jsonDict = try JSONSerialization.jsonObject(with: dataObject, options: [])
			if let objectDictionary = jsonDict as? [String: Any]
				{
				let returnObject = target.init()
				assignDataToFields(target: returnObject, fields: objectDictionary)
				return returnObject
				}
			}
		catch
			{
			return target.init()
			}
		return target.init()
	}

	// This was the only way to take a object inspecxted with Mirror, get the dynamic type, and instantiate am instance of that class that wasn't returned as AnyObject
	private func instantiatePropertyObject<T: IoGGQLDataObject>(target: T.Type) -> T
	{
		return target.init()
	}

	private func populateDataObjectArray<T: IoGGQLDataObject>(data: String, target: T.Type) -> [T]
	{
		var objectArray = [T]()
		let data = Data(data.utf8)
		do
			{
			let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
			if let dataDictionary = jsonData as? [String: Any]
				{
				if dataDictionary.keys.count == 1
					{
					if let key = dataDictionary.keys.first
						{
						if let dataArray = dataDictionary[key] as? [[String: Any]]
							{
							for nextObject in dataArray
								{
								let returnObject = target.init()
								assignDataToFields(target: returnObject, fields: nextObject)
								objectArray.append(returnObject)
								}
							}
						}
					}
				}
			}
		catch
			{
			}

		return objectArray
	}

	private func assignDataToFields<T: IoGGQLDataObject>(target: T, fields: [String: Any])
	{
		let mirror = Mirror(reflecting: target)
		for child in mirror.children
			{
			if child.value is IoGGQLDataObject
				{
				if let propertyName = child.label
					{
					if let fieldValue = fields[propertyName] as? [String: Any]
						{
						do
							{
							let jsonData = try JSONSerialization.data(withJSONObject: fieldValue)
							let contentString = String(decoding: jsonData, as: UTF8.self)
							let childType = type(of: child.value)
							let realType = instantiatePropertyObject(target: childType as! IoGGQLDataObject.Type)	// Dummy instance
							let object = populateDataObject(data: contentString, target: type(of: realType))
							target.setProperty(propertyName: propertyName, value: object)
							}
						catch
							{
							}
						}
					}
				}
			else if child.value is [IoGGQLDataObject]
				{
				if let propertyName = child.label, let property = child.value as? [IoGGQLDataObject]
					{
					if let fieldValue = fields[propertyName] as? [[String: Any]], let fieldTarget = property.first
						{
						do
							{
							var objectArray: [IoGGQLDataObject] = [T]()
							for nextObject in fieldValue
								{
								let jsonData = try JSONSerialization.data(withJSONObject: nextObject)
								let contentString = String(decoding: jsonData, as: UTF8.self)
								let childType = type(of: fieldTarget)
								let realType = instantiatePropertyObject(target: childType)	// Dummy instance
								let object = populateDataObject(data: contentString, target: type(of: realType))
								objectArray.append(object)
								}
							target.setProperty(propertyName: propertyName, value: objectArray)
							}
						catch
							{
							}
						}
					else
						{
						target.clearArray(propertyName: propertyName)	// Clear out dummy instance from array
						}
					}
				}
			else
				{
				if let propertyName = child.label
					{
					if let fieldValue = fields[propertyName]
						{
						target.setProperty(propertyName: propertyName, value: fieldValue)
						}
					}
				}
			}
	}

	// MARK: IoGGQLManagerDelegate Methods

	/// IoGDataManager delegate method that handles the response from the server
	///
	/// > Note: Clients should not call this method
	public func dataRequestResponseReceived(requestID: Int, requestType: IoGDataManager.IoGDataRequestType, responseData: Data?, error: Error?, response: IoGDataRequestResponse)
	{
		var gqlRequestID = -1
		for nextID in outstandingRequests.keys
			{
			if let requestInfo = outstandingRequests[nextID]
			{
				let dataRequestID = requestInfo[IoGConfigurationManager.gqlRequestKeyDataRequestID] as! Int
				if dataRequestID == requestID
					{
					gqlRequestID = nextID
					break
					}
				}
			}
		if gqlRequestID == -1	// Didn't find a matching request
			{
			return
			}
		if requestType == .Custom
			{
			var customType: CustomGQLRequestType? = nil
			if response.getCustomRequestType() == IoGConfigurationManager.gqlManagerCustomDataManagerType
				{
				delegateList.compact()
				if response.didRequestSucceed()
					{
					if let data = responseData, let requestInfo = outstandingRequests[gqlRequestID]
						{
						if let cType = requestInfo[IoGConfigurationManager.gqlRequestKeyCustomRequestType] as? CustomGQLRequestType
							{
							customType = cType
							}
						do
							{
							let jsonDict = try JSONSerialization.jsonObject(with: data, options: [])
							if let dataDictionary = jsonDict as? [String: Any]
								{
								if let dataObject = dataDictionary["data"] as? [String: Any]
									{
									if let contentString = parseGQLResponse(dataDictionary: dataObject), let type = requestInfo[IoGConfigurationManager.gqlRequestKeyTargetType] as? IoGGQLDataObject.Type
										{
										if isGQLResponsePlural(content: contentString)
											{
											let objectArray = populateDataObjectArray(data: contentString, target: type)
											for nextDelegate in delegateList.allObjects
												{
												if let delegate = nextDelegate as? IoGGQLManagerDelegate
													{
													delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: objectArray, error: nil)
													}
												}
											}
										else
											{
											let object = populateDataObject(data: contentString, target: type)
											for nextDelegate in delegateList.allObjects
												{
												if let delegate = nextDelegate as? IoGGQLManagerDelegate
													{
													delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: object, error: nil)
													}
												}
											}
										}
									else
										{
										for nextDelegate in delegateList.allObjects
											{
											if let delegate = nextDelegate as? IoGGQLManagerDelegate
												{
												delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: IoGConfigurationManager.gqlRequestResponseParsingErrorDescription, code: IoGConfigurationManager.gqlRequestResponseParsingErrorCode, userInfo: nil))
												}
											}
										}
									}
								else if let error = dataDictionary["error"] as? Data
									{
									let errorString = String(decoding: error, as: UTF8.self)
									for nextDelegate in delegateList.allObjects
										{
										if let delegate = nextDelegate as? IoGGQLManagerDelegate
											{
											delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: errorString, code: IoGConfigurationManager.gqlRequestResponseParsingErrorCode, userInfo: nil))
											}
										}
									}
								else
									{
									for nextDelegate in delegateList.allObjects
										{
										if let delegate = nextDelegate as? IoGGQLManagerDelegate
											{
											delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: IoGConfigurationManager.gqlRequestResponseParsingErrorDescription, code: IoGConfigurationManager.gqlRequestResponseParsingErrorCode, userInfo: nil))
											}
										}
									}
								}
							else
								{
								for nextDelegate in delegateList.allObjects
									{
									if let delegate = nextDelegate as? IoGGQLManagerDelegate
										{
										delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: IoGConfigurationManager.gqlRequestResponseParsingErrorDescription, code: IoGConfigurationManager.gqlRequestResponseParsingErrorCode, userInfo: nil))
										}
									}
								}
							}
						catch
							{
							for nextDelegate in delegateList.allObjects
								{
								if let delegate = nextDelegate as? IoGGQLManagerDelegate
									{
									delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: IoGConfigurationManager.gqlRequestResponseParsingErrorDescription, code: IoGConfigurationManager.gqlRequestResponseParsingErrorCode, userInfo: nil))
									}
								}
							}
						}
					else
						{
						for nextDelegate in delegateList.allObjects
							{
							if let delegate = nextDelegate as? IoGGQLManagerDelegate, let requestInfo = outstandingRequests[gqlRequestID]
								{
								delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: IoGConfigurationManager.requestResponseGeneralErrorDescription, code: IoGConfigurationManager.requestResponseGeneralErrorCode, userInfo: nil))
								}
							}
						}
					}
				else
					{
					for nextDelegate in delegateList.allObjects
						{
						if let delegate = nextDelegate as? IoGGQLManagerDelegate, let requestInfo = outstandingRequests[gqlRequestID]
							{
							delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: IoGConfigurationManager.requestResponseGeneralErrorDescription, code: IoGConfigurationManager.requestResponseGeneralErrorCode, userInfo: nil))
							}
						}
					}
				}
			}
	}
}
