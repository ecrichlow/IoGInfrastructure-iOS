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

/// The parameter type, which identifies the modifiers available for use with mutation parameters
public enum IoGGQLParamterModifierType
{
	/// The parameter name and property name do not match
	case Alias
	/// The string value will be included without quotes
	case LiteralRepresentation
	/// Either true/false or 1/0 will be used to denote the boolean value
	case BooleanNumericRepresentation
}

public typealias CustomGQLRequestType = String
public typealias GQLMutationParameterList = [String: [Any]]
public typealias GQLMutationParameterFields = [String: [IoGGQLParamterModifierType: Any]]
public typealias GQLQueryPropertyParameters = [String: String]
public typealias GQLQueryPropertyParametersList = [GQLQueryPropertyParameters]

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
		case Analytics
		case Score
		case Catalog
		case Charge
		case Purchase
		case Cart
		case Extra
		case Station
		case Vehicle
		case Block
		case Chat
		case Customer
		case Admin
		case Video
		case Audio
		case Unregister
		case Delete
		case Selections
		case Location
		case Profile
		case Shop
		case Receipt
		case Store
		case Department
		case Category
		case Image
		case Thumbnail
		case Gallery
		case Price
		case Offer
		case Discount
		case Address
		case Contact
		case Lookup
		case Save
		case Open
		case Close
		case Time
		case Schedule
		case Service
		case Order
		case Log
		case Diagnostics
		case Notification
		case Alert
		case Event
		case Map
		case Route
		case Lock
		case Unlock
		case Transfer
		case Upload
		case Download
		case Send
		case Receive
		case Directory
		case Verify
		case List
		case Trip
		case Details
		case Pass
		case Cancel
		case Confirm
		case Comment
		case Rating
		case Search
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
	///   - propertyParameters: An array of dictionaries matching target type property names with a parameters to add to them in the query string
	///
	///  - Returns: An identifier for the request
	@discardableResult public func transmitQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, type: IoGGQLRequestType, target: T.Type, propertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target, fieldParameters: propertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target, propertyParameters: propertyParameters)
			let payloadData = Data(gqlQuery.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfDefaultType().registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfDefaultType().transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: type, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
			outstandingRequests[reqID] = requestInfo
			return reqID
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
	///   - propertyParameters: An array of dictionaries matching target type property names with a parameters to add to them in the query string
	///
	///  - Returns: An identifier for the request
	@discardableResult public func transmitQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, customTypeIdentifier: CustomGQLRequestType, target: T.Type, propertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target, fieldParameters: propertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target, propertyParameters: propertyParameters)
			let payloadData = Data(gqlQuery.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfDefaultType().registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfDefaultType().transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	@discardableResult internal func transmitTestQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, type: IoGGQLRequestType, target: T.Type, propertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target, fieldParameters: propertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target, propertyParameters: propertyParameters)
			let payloadData = Data(gqlQuery.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: type, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	@discardableResult internal func transmitTestQueryRequest<T: IoGGQLDataObject>(url: String, name: String?, parameters: String?, customTypeIdentifier: CustomGQLRequestType, target: T.Type, propertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: target, fieldParameters: propertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlQuery = buildGQLQueryString(name: name, parameters: parameters, target: target, propertyParameters: propertyParameters)
			let payloadData = Data(gqlQuery.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			let requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	/// Send GraphQL Mutation Request
	///
	///  - Parameters:
	///   - url: The URL string for the request
	///   - name: The name to assign to the query
	///   - requestType: One of the pre-defined identifiers used by delegates to differentiate the kind of request they are being notified about
	///   - target: The type of IoGGQLDataObject subclass that the mutation is defined in and relates to
	///   - returnType: The type of IoGGQLDataObject subclass for the manager to populate with the query response and return to the delegates
	///   - returnTypePropertyParameters: An array of dictionaries matching target type property names with a parameters to add to them in the post mutation query string
	///
	///  - Returns: An identifier for the request
	@discardableResult public func transmitMutationRequest<T: IoGGQLDataObject, R: IoGGQLDataObject>(url: String, name: String, requestType: IoGGQLRequestType, target: T, returnType: R.Type?, returnTypePropertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: type(of: target).self, fieldParameters: returnTypePropertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlMutation = buildGQLMutationString(name: name, target: target, returnType: returnType, returnTypePropertyParameters: returnTypePropertyParameters)
			let payloadData = Data(gqlMutation.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfDefaultType().registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfDefaultType().transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			var requestInfo:  [String : Any]
			if let rType = returnType
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: requestType, IoGConfigurationManager.gqlRequestKeyTargetType: target, IoGConfigurationManager.gqlRequestKeyReturnTargetType: rType] as [String : Any]
				}
			else
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: requestType, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
				}
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	/// Send GraphQL Mutation Request with custom type
	///
	///  - Parameters:
	///   - url: The URL string for the request
	///   - name: The name to assign to the query
	///   - customTypeIdentifier: A custom identifier used by delegates to differentiate the kind of request they are being notified about
	///   - target: The type of IoGGQLDataObject subclass that the mutation is defined in and relates to
	///   - returnType: The type of IoGGQLDataObject subclass for the manager to populate with the query response and return to the delegates
	///   - returnTypePropertyParameters: An array of dictionaries matching target type property names with a parameters to add to them in the post mutation query string
	///
	///  - Returns: An identifier for the request
	@discardableResult public func transmitMutationRequest<T: IoGGQLDataObject, R: IoGGQLDataObject>(url: String, name: String, customTypeIdentifier: CustomGQLRequestType, target: T, returnType: R.Type?, returnTypePropertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: type(of: target).self, fieldParameters: returnTypePropertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlMutation = buildGQLMutationString(name: name, target: target, returnType: returnType, returnTypePropertyParameters: returnTypePropertyParameters)
			let payloadData = Data(gqlMutation.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfDefaultType().registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfDefaultType().transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			var requestInfo:  [String : Any]
			if let rType = returnType
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: target, IoGConfigurationManager.gqlRequestKeyReturnTargetType: rType] as [String : Any]
				}
			else
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: target] as [String : Any]
				}
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	@discardableResult func transmitTestMutationRequest<T: IoGGQLDataObject, R: IoGGQLDataObject>(url: String, name: String, requestType: IoGGQLRequestType, target: T, returnType: R.Type?, returnTypePropertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: type(of: target).self, fieldParameters: returnTypePropertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlMutation = buildGQLMutationString(name: name, target: target, returnType: returnType, returnTypePropertyParameters: returnTypePropertyParameters)
			let payloadData = Data(gqlMutation.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			var requestInfo:  [String : Any]
			if let rType = returnType
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: requestType, IoGConfigurationManager.gqlRequestKeyTargetType: type(of: target).self, IoGConfigurationManager.gqlRequestKeyReturnTargetType: rType, IoGConfigurationManager.gqlRequestKeyTestMutationName: name, IoGConfigurationManager.gqlRequestKeyTestMutationString: gqlMutation] as [String : Any]
				}
			else
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: requestType, IoGConfigurationManager.gqlRequestKeyTargetType: type(of: target).self, IoGConfigurationManager.gqlRequestKeyTestMutationName: name, IoGConfigurationManager.gqlRequestKeyTestMutationString: gqlMutation] as [String : Any]
				}
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	@discardableResult func transmitTestMutationRequest<T: IoGGQLDataObject, R: IoGGQLDataObject>(url: String, name: String, customTypeIdentifier: CustomGQLRequestType, target: T, returnType: R.Type?, returnTypePropertyParameters: GQLQueryPropertyParametersList?) -> Int
	{
		let reqID = requestID
		if let _ = parseTargetDataObject(target: type(of: target).self, fieldParameters: returnTypePropertyParameters), let requestURL = URL(string: url)
			{
			var urlRequest = URLRequest(url: requestURL)
			let gqlMutation = buildGQLMutationString(name: name, target: target, returnType: returnType, returnTypePropertyParameters: returnTypePropertyParameters)
			let payloadData = Data(gqlMutation.utf8)
			urlRequest.httpBody = payloadData
			urlRequest.httpMethod = "POST"
			urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
			urlRequest.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
			IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).registerDelegate(delegate: self)
			let dataManagerRequestID = IoGDataManager.dataManagerOfType(type: .IoGDataManagerTypeMock).transmitRequest(request: urlRequest, customTypeIdentifier: IoGConfigurationManager.gqlManagerCustomDataManagerType)
			requestID += 1
			var requestInfo:  [String : Any]
			if let rType = returnType
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: type(of: target).self, IoGConfigurationManager.gqlRequestKeyReturnTargetType: rType, IoGConfigurationManager.gqlRequestKeyTestMutationName: name, IoGConfigurationManager.gqlRequestKeyTestMutationString: gqlMutation] as [String : Any]
				}
			else
				{
				requestInfo = [IoGConfigurationManager.gqlRequestKeyDataRequestID: dataManagerRequestID, IoGConfigurationManager.gqlRequestKeyRequestType: IoGGQLRequestType.Custom, IoGConfigurationManager.gqlRequestKeyCustomRequestType: customTypeIdentifier, IoGConfigurationManager.gqlRequestKeyTargetType: type(of: target).self, IoGConfigurationManager.gqlRequestKeyTestMutationName: name, IoGConfigurationManager.gqlRequestKeyTestMutationString: gqlMutation] as [String : Any]
				}
			outstandingRequests[reqID] = requestInfo
			return reqID
			}
		return -1
	}

	private func buildGQLQueryString<T: IoGGQLDataObject>(name: String?, parameters: String?, target: T.Type, propertyParameters: GQLQueryPropertyParametersList?) -> String
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
			if let propertyObjectDefinition = parseTargetDataObject(target: target, fieldParameters: propertyParameters)
				{
				queryString += propertyObjectDefinition
				}
			queryString += "}\n"
			}
		return queryString
	}

	private func buildGQLMutationString<T: IoGGQLDataObject, R: IoGGQLDataObject>(name: String, target: T, returnType: R.Type?, returnTypePropertyParameters: GQLQueryPropertyParametersList?) -> String
	{
		var mutationString = "mutation {\n\(name)"
		let parameterDefinition = parseTargetParameters(target: target, mutationName: name)
		mutationString += parameterDefinition
		if let rType = returnType
			{
			if let propertyObjectDefinition = parseTargetDataObject(target: rType, fieldParameters: returnTypePropertyParameters)
				{
				mutationString += " "
				mutationString += propertyObjectDefinition
				}
			}
		mutationString += "}"
		return mutationString
	}

	private func parseTargetDataObject<T: IoGGQLDataObject>(target: T.Type, fieldParameters: GQLQueryPropertyParametersList?) -> String?
	{
		let typeInstance = target.init()	// Swift's reflection only works on instances, not class types, so we need to create a dummy instance
		let mirror = Mirror(reflecting: typeInstance)
		var gqlObjectDefinition = "{\n"
		for child in mirror.children
			{
			if let propertyName = child.label
				{
				if !typeInstance.excludeFromQueries.contains(propertyName)
					{
					if child.value is IoGGQLDataObject
						{
						if let childObject = child.value as? IoGGQLDataObject
							{
							if let propertyObjectDefinition = parseTargetDataObject(target: type(of: childObject).self, fieldParameters: fieldParameters), let innerClassName = child.label
								{
								if let parameters = fieldParameters, let innerClassParameters = getFieldParameters(fieldName: innerClassName, fieldParameters: parameters)
									{
									gqlObjectDefinition += "\(innerClassName)(\(innerClassParameters)) \(propertyObjectDefinition)"
									}
								else
									{
									gqlObjectDefinition += "\(innerClassName) \(propertyObjectDefinition)"
									}
								}
							}
						}
					else if child.value is NSArray
						{
						if let childArray = child.value as? NSArray, let childName = child.label
							{
							let arrayDefinition = parseArray(array: childArray as NSArray, name: childName, fieldParameters: fieldParameters)
							if let propertyName = child.label
								{
								if let parameters = fieldParameters, let innerClassParameters = getFieldParameters(fieldName: propertyName, fieldParameters: parameters)
									{
									gqlObjectDefinition += "\(propertyName)(\(innerClassParameters)) \(arrayDefinition)"
									}
								else
									{
									gqlObjectDefinition += "\(propertyName) \(arrayDefinition)"
									}
								}
							}
						}
					else
						{
						if let propertyName = child.label
							{
							if let parameters = fieldParameters, let innerClassParameters = getFieldParameters(fieldName: propertyName, fieldParameters: parameters)
								{
								gqlObjectDefinition += "\(propertyName)(\(innerClassParameters))"
								}
							else
								{
								gqlObjectDefinition += "\(propertyName)\n"
								}
							}
						}
					}
				}
			}
		gqlObjectDefinition += "}\n"
		return gqlObjectDefinition
	}

	private func parseTargetParameters<T: IoGGQLDataObject>(target: T, mutationName: String) -> String
	{
		let mirror = Mirror(reflecting: target)
		var parameterList = "("
		var firstParameter = true
		if let mutationParameters = target.mutations[mutationName]
			{
			for parameter in mutationParameters
				{
				var parameterName = ""
				var associatedPropertyName = ""
				var parameterModifiers: [IoGGQLParamterModifierType: Any]? = nil
				var booleanNumericRepresentation = false
				var literalRepresentation = false
				if !firstParameter
					{
					parameterList += ", "
					}
				if parameter is GQLMutationParameterFields	// Parameter is customized
					{
					if let parameterEntry = parameter as? GQLMutationParameterFields
						{
						// Store the modifiers for later use
						if let parameterFieldName = parameterEntry.keys.first
							{
							parameterModifiers = parameterEntry[parameterFieldName]
							parameterName = parameterFieldName
							// But use the alias modifier immediately
							if let modifiers = parameterModifiers
								{
								if let propertyName = modifiers[.Alias] as? String
									{
									associatedPropertyName = propertyName
									}
								else
									{
									associatedPropertyName = parameterFieldName
									}
								if let booleanRepresentation = modifiers[.BooleanNumericRepresentation] as? Bool
									{
									if booleanRepresentation
										{
										booleanNumericRepresentation = true
										}
									}
								if let literal = modifiers[.LiteralRepresentation] as? Bool
									{
									if literal
										{
										literalRepresentation = true
										}
									}
								}
							}
						}
					}
				else		// Parameter name is same as property name
					{
					if let pName = parameter as? String
						{
						parameterName = pName
						associatedPropertyName = pName
						}
					}
				for child in mirror.children
					{
					if let propertyName = child.label
						{
						if propertyName == associatedPropertyName
							{
							parameterList += "\(parameterName):"
							switch child.value
								{
								case is String:
									if let parameterValue = child.value as? String
										{
										if literalRepresentation
										{
											parameterList += "\(parameterValue)"
										}
										else
											{
											parameterList += "\"\(parameterValue)\""
											}
										}
								case is Bool:
									if let booleanValue = child.value as? Bool
										{
										if booleanValue == true
											{
											if booleanNumericRepresentation
												{
												parameterList += "1"
												}
											else
												{
												parameterList += "true"
												}
											}
										else
											{
											if booleanNumericRepresentation
												{
												parameterList += "0"
												}
											else
												{
												parameterList += "false"
												}
											}
										}
								case is Int:
									if let parameterValue = child.value as? Int
										{
										parameterList += "\(parameterValue)"
										}
								case is Double:
									if let parameterValue = child.value as? Double
										{
										parameterList += "\(parameterValue)"
										}
								case is Float:
									if let parameterValue = child.value as? Float
										{
										parameterList += "\(parameterValue)"
										}
								default:
									parameterList += "\(child.value):"
								
							}
							break
							}
						}
					}
				firstParameter = false
				}
			}
		parameterList += ")"
		return parameterList
	}

	private func parseArray(array: NSArray, name: String?, fieldParameters: GQLQueryPropertyParametersList?) -> String
	{
		var arrayDefinition = ""

		if let arrayObject = array.firstObject
			{
			if arrayObject is IoGGQLDataObject
				{
				if let propertyType = type(of: arrayObject) as? IoGGQLDataObject.Type
					{
					if let propertyObjectDefinition = parseTargetDataObject(target: propertyType.self, fieldParameters: fieldParameters)
						{
						arrayDefinition += propertyObjectDefinition
						}
					}
				else if arrayObject is NSArray
					{
					if let childArray = arrayObject as? NSArray
						{
						let subarrayDefinition = parseArray(array: childArray as NSArray, name: name, fieldParameters: fieldParameters)
						if let propertyObjectName = name
							{
							if let parameters = fieldParameters, let innerClassParameters = getFieldParameters(fieldName: propertyObjectName, fieldParameters: parameters)
								{
								arrayDefinition += "\(propertyObjectName)(\(innerClassParameters)) \(subarrayDefinition)"
								}
							else
								{
								arrayDefinition += "\(propertyObjectName) \(subarrayDefinition)"
								}
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
						if let parameters = fieldParameters, let innerClassParameters = getFieldParameters(fieldName: propertyObjectName, fieldParameters: parameters)
							{
							arrayDefinition += "\(propertyObjectName)(\(innerClassParameters))"
							}
						else
							{
							arrayDefinition += "\(propertyObjectName)\n"
							}
						}
					}
				}
			}
		return arrayDefinition

	}

	private func getFieldParameters(fieldName: String, fieldParameters: GQLQueryPropertyParametersList) -> String?
	{
		for parameter in fieldParameters
		{
			if let parameters = parameter[fieldName]
			{
				return parameters
			}
		}
		return nil
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
				if objectDictionary.keys.count == 1
					{
					if let key = objectDictionary.keys.first
						{
						if let dataDictionary = objectDictionary[key] as? [String: Any]
							{
							assignDataToFields(target: returnObject, fields: dataDictionary)
							}
						}
					}
				else
					{
					assignDataToFields(target: returnObject, fields: objectDictionary)
					}
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

	private func processTestMutation(dataObject: IoGGQLDataObject, mutationName: String, mutationString: String)
	{
		if mutationString.contains("(") && mutationString.contains(")")
			{
			let firstComponentArray = mutationString.components(separatedBy: "(")
			if firstComponentArray.count > 1
				{
				let subString = firstComponentArray[1]
				let secondComponentArray = subString.components(separatedBy: ")")
				if secondComponentArray.count > 0
					{
					let parameterString = secondComponentArray[0]
					let parameterArray = parameterString.components(separatedBy: ",")
					if parameterArray.count > 0
						{
						for parameterPair in parameterArray
							{
							let parameterPairArray = parameterPair.components(separatedBy: ":")
							if parameterPairArray.count == 2
								{
								var property = parameterPairArray[0].trimmingCharacters(in: .whitespacesAndNewlines)
								let value = parameterPairArray[1].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
								var parameterList = "("
								var firstParameter = true
								if let mutationParameters = dataObject.mutations[mutationName]
									{
									for parameter in mutationParameters
										{
										var parameterModifiers: [IoGGQLParamterModifierType: Any]? = nil
										if !firstParameter
											{
											parameterList += ", "
											}
										if parameter is GQLMutationParameterFields	// Parameter is customized
											{
											if let parameterEntry = parameter as? GQLMutationParameterFields
												{
												if let parameterFieldName = parameterEntry.keys.first
													{
													parameterModifiers = parameterEntry[parameterFieldName]
													if let modifiers = parameterModifiers
														{
														if let propertyName = modifiers[.Alias] as? String
															{
															property = propertyName
															}
														}
													}
												}
											}
										firstParameter = false
										}
									}
								dataObject.setProperty(propertyName: property, value: value)
								}
							}
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
									if let contentString = parseGQLResponse(dataDictionary: dataObject)
										{
										var returnType: IoGGQLDataObject.Type
										if let type = requestInfo[IoGConfigurationManager.gqlRequestKeyReturnTargetType]
											{
											returnType = type as! IoGGQLDataObject.Type
											if isGQLResponsePlural(content: contentString)
												{
												let objectArray = populateDataObjectArray(data: contentString, target: returnType)
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
												let object = populateDataObject(data: contentString, target: returnType)
												// Support for GQL mutation unit tests
												if let mutationName = requestInfo[IoGConfigurationManager.gqlRequestKeyTestMutationName] as? String, let mutationString = requestInfo[IoGConfigurationManager.gqlRequestKeyTestMutationString] as? String
													{
													processTestMutation(dataObject: object, mutationName: mutationName, mutationString: mutationString)
													}
												for nextDelegate in delegateList.allObjects
													{
													if let delegate = nextDelegate as? IoGGQLManagerDelegate
														{
														delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: object, error: nil)
														}
													}
												}
											}
										else if let type = requestInfo[IoGConfigurationManager.gqlRequestKeyTargetType]
											{
											returnType = type as! IoGGQLDataObject.Type
											if isGQLResponsePlural(content: contentString)
												{
												let objectArray = populateDataObjectArray(data: contentString, target: returnType)
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
												let object = populateDataObject(data: contentString, target: returnType)
												// Support for GQL mutation unit tests
												if let mutationName = requestInfo[IoGConfigurationManager.gqlRequestKeyTestMutationName] as? String, let mutationString = requestInfo[IoGConfigurationManager.gqlRequestKeyTestMutationString] as? String
													{
													processTestMutation(dataObject: object, mutationName: mutationName, mutationString: mutationString)
													}
												for nextDelegate in delegateList.allObjects
													{
													if let delegate = nextDelegate as? IoGGQLManagerDelegate
														{
														delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: object, error: nil)
														}
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
								else if let errorList = dataDictionary["errors"] as? [[String: Any]]
									{
									if let error = errorList.first
										{
										if let message = error["message"] as? String
											{
											for nextDelegate in delegateList.allObjects
												{
												if let delegate = nextDelegate as? IoGGQLManagerDelegate
													{
													delegate.gqlRequestResponseReceived(requestID: gqlRequestID, requestType: requestInfo[IoGConfigurationManager.gqlRequestKeyRequestType] as! IoGGQLManager.IoGGQLRequestType, customRequestIdentifier: customType, responseData: nil, error: NSError.init(domain: message, code: IoGConfigurationManager.gqlRequestResponseParsingErrorCode, userInfo: nil))
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
