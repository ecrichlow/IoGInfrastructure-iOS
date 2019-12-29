# IoGInfrastructure

v1.1 (c) 2018 Infusions of Grandeur - Written By: Eric Crichlow

## Background

IoGInfrastructure is a framework designed to facilitate common, mundane tasks of mobile application development, such as back-end communications, data persistence and business object inflation. Along with those, it also helps with management of blocks of code, typically related to back-end communications, that initially fail and need to be attempted again, either until they succeed, or until they fail enough times that the application gives up trying. This is referred to as retry management.

Most of these functions already exist in well-established frameworks, so why introduce a new one?

Two reasons. One, most of the existing frameworks are extremely big, one might even say, bloated, offering far more functionality and flexibility than is needed by most applications, and, more importantly, this framework is implemented and available for both iOS and Android, such that an application that needs to be developed for both platforms can utilize the same framework for basic infrastructure functionality, significantly accelerating the development of both codebases, resulting in almost line-by-line compatible implementation of native apps, not relying on clucky cross-platform technologies.

## History

Version 1.1 :	Initial public release

## Classes

* IoGPersistenceManager

This is the class that handles storage of data. It supports such storage either in memory, in User Defaults, or in a file. It supports storing data securely (encrypted). And it allows data to be stored only for the current session, or to have an expiration date or to be permanent. 

* IoGDataManager

This is the class that handles back-end communications. It handles large sets of data returned in pages, and manages multiple simultaneous requests. Under the enumeration "IoGDataRequestType" are defined the types of requests that the class supports. This is a convenience for clients of the class to identify what type of request is being responded to. Add your own entries to this enumeration for your own custom request types.

* IoGDataRequestResponse

This is the class that handles a unique request, and all of the request and response details associated with it.

* IoGDataObjectManager

This is the class that handles business object class inflation. It takes JSON data usually returned from a back-end call and parses it into a class defined for a specific business object.

* IoGRetryManager

This is the class that manages delayed and repeated execution of a block of code, allowing the caller to determine when the workflow has completed and retry attempts are no longer necessary.

## Usage

* iOS

Note, the project in its current configuration doesn't build a framework that supports both the Simulator and actual hardware. So, you can either embed this project as a subproject of your app project, or, if you want to include this project as a framework, you need to run the following script at the root of this project's folder to get the framework properly configured:

	#!/bin/sh
	CONFIGURATION=release
	BUILD_DIR=/Users/<username>/Library/Developer/Xcode/DerivedData/path to project derived data>/Build/Products
	BUILD_ROOT=/Users/<username>/Library/Developer/Xcode/DerivedData/<path to project derived data>/Build/Products
	SDKROOT=iphoneos12.1
	TOOLCHAINS=com.apple.dt.toolchain.XcodeDefault
	UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal
	# make sure the output directory exists
	mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"
	# Step 1. Build Device and Simulator versions
	xcodebuild -target "IoGInfrastructure" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
	xcodebuild -target "IoGInfrastructure" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
	# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
	cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/IoGInfrastructure.framework" "${UNIVERSAL_OUTPUTFOLDER}/"
	# Step 3. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
	SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/IoGInfrastructure.framework/Modules/IoGInfrastructure.swiftmodule/."
	if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
	cp -R "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_OUTPUTFOLDER}/IoGInfrastructure.framework/Modules/IoGInfrastructureswiftmodule"
	fi
	# Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
	lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/IoGInfrastructure.framework/IoGInfrastructure" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/F IoGInfrastructure.framework/IoGInfrastructure" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/IoGInfrastructure.framework/IoGInfrastructure"
	# Step 5. Convenience step to copy the framework to the project's directory
	cp -R "${UNIVERSAL_OUTPUTFOLDER}/IoGInfrastructure.framework" "${PROJECT_DIR}"

Then, expand the IogInfrastructure.framework file, drill down to the "Modules" folder, and move every file from the "IoGInfrastructureswiftmodule" folder into the "IogInfrastructure.swiftmodule" folder and delete the "IoGInfrastructureswiftmodule" folder.

Now the framework is ready to be imported into any project.

Select the project, and then the target, and under "Frameworks, Libraries and Embedded Content" (code 11) add the framework created from building this project and performing the above-listed steps.

* Android

Select File -> Project Structure, select the "New Module" icon under "Modules", and select "Import .JAR/.AAR Package". Choose the .aar created by building this project.

As for utilizing the classes contained in this project, the easiest way to learn how to use them is by looking at the unit test classes. They give great detail as to how to perform each function.

Of note, the IoGDataManager and IoGRetryManager classes support broadcasting responses to multiple delegates, and thus "registerDelegate" and "unregisterDelegate" methods are provided for each class.


## Known Issues

	* IoGPersistenceManager doesn't yet support securely (encrypted) storing data.

	* The project doesn't build a framework that is ready to support both Simulator and actual device on iOS.

## Support

Questions or suggestions can be submitted to support@infusionsofgrandeur.com

## License

Copyright 2018 Infusions of Grandeur

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
