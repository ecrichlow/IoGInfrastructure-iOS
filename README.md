# IoGInfrastructure

v3.0 (c) 2022 Infusions of Grandeur - Written By: Eric Crichlow

## Background

IoGInfrastructure is a framework designed to facilitate common, mundane tasks of mobile application development, such as back-end communications, data persistence and business object inflation. Along with those, it also helps with management of blocks of code, typically related to back-end communications, that initially fail and need to be attempted again, either until they succeed, or until they fail enough times that the application gives up trying. This is referred to as retry management.

Most of these functions already exist in well-established frameworks, so why introduce a new one?

Two reasons. One, most of the existing frameworks are extremely big, one might even say, bloated, offering far more functionality and flexibility than is needed by most applications, and, more importantly, this framework is implemented and available for both iOS and Android, such that an application that needs to be developed for both platforms can utilize the same framework for basic infrastructure functionality, significantly accelerating the development of both codebases, resulting in almost line-by-line compatible implementation of native apps, not relying on clucky cross-platform technologies.

## History

Version 1.1 :	Initial public release

Version 2.0 :	Adds secure storage, multiple API Base URLs, custom data request types and Codable IoGDataObject; Changed from Foundation collection objects to Swift native collection objects; Cleaned up warnings

Version 3.0 :	Changing to a Swift Package Manager project; added support for GraphQL; added support for DocC

## Platforms

iOS 13.0

MacOS 10.10

tvOS 13.0

watchOS 7.0

## Classes

* IoGPersistenceManager

This is the class that handles storage of data. It supports such storage either in memory, in User Defaults, or in a file. It supports storing data securely (encrypted). And it allows data to be stored only for the current session, or to have an expiration date or to be permanent.

* IoGDataManager

This is the class that handles back-end communications. It handles large sets of data returned in pages, and manages multiple simultaneous requests. Under the enumeration "IoGDataRequestType" are defined the types of requests that the class supports. This is a convenience for clients of the class to identify what type of request is being responded to. Add your own entries to this enumeration for your own custom request types.

* IoGDataRequestResponse

This is the class that handles a unique request, and all of the request and response details associated with it.

* IoGDataObjectManager

This is the class that handles business object class inflation. It takes JSON data usually returned from a back-end call and parses it into a class defined for a specific business object.

* IoGDataObject

This is the class that clients subclass to create customized business data objects with only the specific properties relevant to the business object.

* IoGRetryManager

This is the class that manages delayed and repeated execution of a block of code, allowing the caller to determine when the workflow has completed and retry attempts are no longer necessary.

* IoGGQLManager

This is the class that handles GraphQL interactions. It dynamically inspects business objects that are subclasses of "IoGGQLDataObject" and builds query and mutation strings for them, makes requests to the GraphQL server and returns populated objects or arrays of those objects. Under the enumeration "IoGGQLRequestType" are defined the types of requests that the class supports. This is a convenience for clients of the class to identify what type of request is being responded to. Add your own entries to this enumeration for your own custom request types.

* IoGGQLDataObject

This is the class that clients subclass to create customized GraphQL business data objects with only the specific properties and mutations relevant to the business object.

## Installation

Install using Xcode "Add Packages..." file menu option

Reference the package using this URL: https://github.com/ecrichlow/IoGInfrastructure-iOS.git

## Usage

As for utilizing the classes contained in this project, the easiest way to learn how to use them is by looking at the unit test classes. They give great detail as to how to perform each function.

Of note, the IoGDataManager, IoGRetryManager and IoGGQLManager classes support broadcasting responses to multiple delegates, and thus "registerDelegate" and "unregisterDelegate" methods are provided for each class.

## Known Issues

IoGPersistenceManager can only securely (encrypted) store strings.

## Support

Questions or suggestions can be submitted to support@infusionsofgrandeur.com

## License

Copyright (c) 2018 Infusions of Grandeur

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
