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
        
        // If already uncompressed, return
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
        var res = false
        if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
            do{
                let resUncompressedFile = try uncompressGZFileIfNeeded(at: fileURL)
                if(resUncompressedFile == nil){
                    return false
                }
                
                let uncompressedFileURL = resUncompressedFile!
                let fileDetails = FileDetails(fileName: uncompressedFileURL.lastPathComponent,
                                         filePath: uncompressedFileURL,
                                         fileExtension: uncompressedFileURL.pathExtension.lowercased())
                
                //update service code and beautify name
                fileDetails.service = fileDetails.fileDirectoryName()
                
                if let service = fileDetails.service{
                    if(!service.isEmpty){
                        let serviceBeautifyName = services.getBeautifyServiceNameFromFile(fileDetails.fileName ?? "Not specified") ?? services.getBeautifyServiceName(service)
                        fileDetails.serviceBeautifyName =  serviceBeautifyName
                        
                        //update file schema
                        if(!serviceBeautifyName.isEmpty){
                            fileDetails.itemType = .Assigned
                            fileDetails.schema = services.schemas.first(where: {$0.key == serviceBeautifyName})?.value
                        }else {
                            fileDetails.serviceBeautifyName = "Not specified"
                        }
                    }
                }
                
                
                
                files.append(fileDetails)
                res = true
            }catch{
                Logger.log("validateAndAddFile ex", error.localizedDescription)
            }
        }
        return res
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
}

