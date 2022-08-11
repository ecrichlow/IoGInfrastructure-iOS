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

/// The class that clients of the GQL Manager subclass to define the business objects inflated using the
/// response to a query.
///
/// Subclasses should add a var for each expected property in the format:
///
/// ``` swift
/// var flightID: String? = ""
/// var seats: NSNumber? = 0
/// var route: Route = Route.init()
/// var passenger: [Passenger] = [Passenger.init()]
/// ```
///
/// > Note: Native types can be declared as optionals, but must have an initial value assigned in order for the query
/// parsing to work. Properties that are also subclasses of IoGGQLDataObject must have an instance of the subclass
/// initially assigned to them. Array properties must initially contain an object of the designated type.
///
/// For mutations, subclasses should add code to the required initializer that contains listings for the business object's
/// supported mutations:
///
/// ``` swift
/// required public init()
/// {
/// 	super.init()
/// 	mutations = ["mutationAddDependent": [["id": "passengerID"], "name", "age"],
/// 				 "mutationRemoveDependent": [["id": "passengerID"]]]
/// }
/// ```
/// The format of each entry in the mutation dictionary is:
///
/// 	* A key that is the name of the mutation
///
/// 	* A value that is an array of the list of parameters for the mutation
///
/// > Note: The format of the parameter list array is, if the parameter name is the same as the property name, a string
///	that denotes the name; if the parameter name and property name are different, a dictionary with the parameter name
///	as the sole key and the property name as the sole value
open class IoGGQLDataObject
{

	// Mutations
	/// The collection of mutations supported for the business object
	public var mutations = [String: [Any]]()

	// MARK: Instance Methods

	/// Default initializer
	required public init()
	{
	}

	// MARK: Business Logic

	/// Set a value for a given key
	///
	///  - Parameters:
	///  	- propertyName: The name of the property for which the value should be set
	///  	- value: The value to set for the property
	///
	///	> Note: Subclasses *must* override this method and add code to set the requested property's value.
	///	
	///	Example:
	/// ``` swift
	/// override public func setProperty(propertyName: String, value: Any?)
	/// {
	/// 	switch propertyName
	/// 		{
	/// 		case "name":
	/// 			name = value as <type>
	/// 		}
	/// }
	/// ```
	open func setProperty(propertyName: String, value: Any?)
	{
		preconditionFailure("This method must be overridden")
	}

	/// Clear the contents of a property that is an array type
	///
	/// Arrays have to be initially populated with a "dummy" instance; when IoGGQLManager is ready to populate real
	/// instances, the dummy instances need to be cleared, so it calls this method to clear a specific array.
	///
	///  - Parameters:
	///  	- propertyName: The name of the array property for which the contents should be cleared
	///
	///	> Note: Subclasses *must* override this method and add code to clear the requested array's value.
	///
	///	Example:
	/// ``` swift
	/// override public func clearArray(propertyName: String)
	/// {
	/// 	switch propertyName
	/// 		{
	/// 		case "arrayName":
	/// 			arrayName.removeAll()
	/// 		}
	/// }
	/// ```
	open func clearArray(propertyName: String)
	{
		preconditionFailure("This method must be overridden")
	}
}
