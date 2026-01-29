//
//  ScanDirectoryFiles.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 23/05/25.
//

import Cocoa
import UniformTypeIdentifiers
import Compression


class ScanDirectoryFiles{
    
    static let shared = ScanDirectoryFiles()
    private init(){}
    
    let services = Services.shared;
    
    let supportedExtensions = ["gz", "txt", "csv", "tsv"]
    
    
    private(set) var files = [FileDetails]()
    
    func getAllowedFileTypes () -> [UTType] {
        return [.gzip, .plainText, .commaSeparatedText]
    }
    
    func addFileManually(filePath: URL) -> Bool{
        return validateAndAddFile(filePath)
    }
    
    func isValidDirectory(_ directoryPath: String) -> Bool{
        //check for non empty path
        guard !directoryPath.isEmpty else { return false }
        
        //check for valid directory
        var isDirectory: ObjCBool = true
        guard FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory) else { return false }
        
        return true
    }
    
    func startScan(directoryPath: String) throws -> Bool {
        if(isValidDirectory(directoryPath)){
            //perform recursive scan
            scanDirectoryRecursively(directoryPath: directoryPath)
            return true
        }
        return false
    }
    
    func clearFiles(){
        if(!files.isEmpty) {files.removeAll()}
    }
    
    
    
    private func scanDirectoryRecursively(directoryPath: String) {
        clearFiles()
        
        let root = URL(fileURLWithPath: directoryPath)
        let fileManager = FileManager.default
        
        //skip hidden files
        if let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                _ = validateAndAddFile(fileURL)
            }
        }
    }
    
    func uncompressGZFileIfNeeded(at fileURL: URL) throws -> URL? {
        guard fileURL.pathExtension == "gz" else {
            return fileURL // Already uncompressed
        }
        
        let uncompressedURL = fileURL.deletingPathExtension()
        
        if FileManager.default.fileExists(atPath: uncompressedURL.path) {
            return nil
        }
        
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/usr/bin/gunzip")
        task.arguments = ["-c", fileURL.path]
        task.standardOutput = pipe
        
        try task.run()
        
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw NSError(domain: "Uncompression", code: Int(task.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: "gunzip -c failed with status \(task.terminationStatus)"
            ])
        }
        
        try outputData.write(to: uncompressedURL)
        
        return uncompressedURL
    }
    
    func validateAndAddFile(_ fileURL: URL) -> Bool {
        guard supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
            return false
        }

        do {
            let resUncompressedFile = try uncompressGZFileIfNeeded(at: fileURL)
            if resUncompressedFile == nil { return false }

            let uncompressedFileURL = resUncompressedFile!
            let fileName = uncompressedFileURL.lastPathComponent

            let fileDetails = FileDetails(
                fileName: fileName,
                filePath: uncompressedFileURL,
                fileExtension: uncompressedFileURL.pathExtension.lowercased()
            )

            let schemas = SqliteManager.shared.getAllReportSchemas()

            var matchedService: String?
            var matchedSchema: ReportSchema?

            for (serviceName, schema) in schemas {
                let regex = schema.FileNameRegex ?? serviceName

                if matchesPattern(regex, service: serviceName, fileName: fileName) {
                    matchedService = serviceName
                    matchedSchema = schema
                    break
                }
            }

            
            
            if let service = matchedService, let schema = matchedSchema {
                fileDetails.serviceBeautifyName = service
                fileDetails.service = service
                fileDetails.schema = schema
                fileDetails.itemType = .Assigned
            } else {
                fileDetails.serviceBeautifyName = "Not specified"
                fileDetails.itemType = .Unassigned
            }

            files.append(fileDetails)
            return true

        } catch {
            Logger.log("validateAndAddFile", error.localizedDescription)
            return false
        }
    }

    
    func isValidFile(filePath: String) -> Bool {
        guard !filePath.isEmpty else {return false}
        
        // Ignore temporary files
        guard filePath.contains("~") else { return false}
        
        // allow only supported extensions
        if(supportedExtensions.contains(URL(fileURLWithPath: filePath).pathExtension.lowercased())){
            return true
        }
        
        //TODO: // Exclude files located in any directory starting with ".removed_at_"
        return false
    }
    
    func matchesPattern(_ pattern: String, service: String,  fileName: String) -> Bool {
        let fileNameLower = fileName.lowercased().replacingOccurrences(of: "-", with: " ")
        let normalizedService = service.lowercased()

        let parts = pattern
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for part in parts {

            if let regex = try? NSRegularExpression(
                pattern: part,
                options: [.caseInsensitive]
            ) {
                let range = NSRange(fileName.startIndex..., in: fileName)
                if regex.firstMatch(in: fileName, options: [], range: range) != nil {
                    return true
                }
            }
            

            if fileNameLower.contains(part.lowercased()) {
                return true
            }
        }

        if fileNameLower.contains(normalizedService) {
            return true
        }
        
        return false
    }
}

