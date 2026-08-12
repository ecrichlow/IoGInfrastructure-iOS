/*
********************************************************************************
* IoGMultipartFormData.swift
*
* Title:			IoG Infrastructure
* Description:		IoG Mobile App Infrastructure Framework
*						This file contains the helper type for building
*						multipart/form-data POST requests
* Author:			Eric Crichlow
* Version:			4.0
* Copyright:		(c) 2026 Infusions of Grandeur. All rights reserved.
********************************************************************************
*	08/10/26		*	Copilot	*	File creation date
********************************************************************************
*/

import Foundation

/// Represents a single file or binary part in a multipart/form-data request.
public struct IoGMultipartFilePart
{
	/// The HTML form field name for this part.
	public let fieldName: String
	/// The filename reported to the server.
	public let fileName: String
	/// The MIME type of the data (e.g. `"image/jpeg"`, `"application/octet-stream"`).
	public let mimeType: String
	/// The raw bytes to upload.
	public let data: Data

	public init(fieldName: String, fileName: String, mimeType: String, data: Data)
	{
		self.fieldName = fieldName
		self.fileName = fileName
		self.mimeType = mimeType
		self.data = data
	}
}

/// Builder that assembles a `multipart/form-data` body and produces a configured `URLRequest`.
///
/// ### Typical usage
/// ```swift
/// var form = IoGMultipartFormData()
/// form.addField(name: "username", value: "alice")
/// form.addFile(IoGMultipartFilePart(fieldName: "avatar",
///                                   fileName: "photo.jpg",
///                                   mimeType: "image/jpeg",
///                                   data: imageData))
/// let requestID = IoGDataManager.dataManagerOfDefaultType()
///     .transmitMultipartRequest(url: uploadURL, formData: form, type: .Upload)
/// ```
public struct IoGMultipartFormData
{
	/// The boundary string that separates parts. Auto-generated when not provided.
	public let boundary: String
	
	private var fields: [(name: String, value: String)] = []
	private var files: [IoGMultipartFilePart] = []
	
	// MARK: Instance Methods
	
	/// Create a new form-data builder.
	/// - Parameter boundary: Optional custom boundary. Defaults to a UUID string.
	public init(boundary: String = UUID().uuidString)
	{
		self.boundary = boundary
	}
	
	/// Add a plain-text field.
	/// - Parameters:
	///   - name: The HTML form field name.
	///   - value: The string value.
	public mutating func addField(name: String, value: String)
	{
		fields.append((name: name, value: value))
	}
	
	/// Add a binary/file part.
	/// - Parameter part: An ``IoGMultipartFilePart`` describing the file.
	public mutating func addFile(_ part: IoGMultipartFilePart)
	{
		files.append(part)
	}
	
	// MARK: Encoding
	
	/// Encode all fields and files into a `multipart/form-data` `Data` blob.
	public func encode() -> Data
	{
		var body = Data()
		let crlf = "\r\n"
		let dashdash = "--"
		
		// Text fields
		for field in fields
		{
			body.appendString("\(dashdash)\(boundary)\(crlf)")
			body.appendString("Content-Disposition: form-data; name=\"\(field.name)\"\(crlf)")
			body.appendString(crlf)
			body.appendString("\(field.value)\(crlf)")
		}
		
		// File / binary parts
		for file in files
		{
			body.appendString("\(dashdash)\(boundary)\(crlf)")
			body.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(crlf)")
			body.appendString("Content-Type: \(file.mimeType)\(crlf)")
			body.appendString(crlf)
			body.append(file.data)
			body.appendString(crlf)
		}
		
		// Closing boundary
		body.appendString("\(dashdash)\(boundary)\(dashdash)\(crlf)")
		
		return body
	}
	
	/// Build a fully configured POST `URLRequest` ready to pass to `IoGDataManager.transmitRequest`.
	///
	/// - Parameters:
	///   - url: The endpoint URL.
	///   - headers: Optional additional HTTP header fields to set on the request
	///              (e.g. `["Cookie": "cx-auth-token=…", "Accept": "application/json"]`).
	///              The `Content-Type` and `Content-Length` headers are always set by this method.
	/// - Returns: A `URLRequest` with `Content-Type`, `Content-Length`, `httpBody`, and any
	///            supplied headers set.
	public func buildRequest(url: URL, headers: [String: String]? = nil) -> URLRequest
	{
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		let body = encode()
		request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
		request.httpBody = body
		if let headers = headers
		{
			for (field, value) in headers
			{
				request.setValue(value, forHTTPHeaderField: field)
			}
		}
		return request
	}
}

// MARK: - Data convenience extension

private extension Data
{
	mutating func appendString(_ string: String)
	{
		if let encoded = string.data(using: .utf8)
			{
			append(encoded)
			}
	}
}
