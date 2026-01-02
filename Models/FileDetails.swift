//
//  FileDetails.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 23/05/25.
//

import Cocoa

class FileDetails{
    
    init(fileName: String, filePath: URL, fileExtension: String) {
        self.fileName = fileName
        self.filePath = filePath
        self.fileExtension = fileExtension
    }
    
    var fileName: String?
    var filePath: URL?
    var fileExtension: String?
    var isSelected = true
    var itemType: FileItemType = .Unassigned
    
    
    var service: String?
    var serviceBeautifyName: String?
    
    var schema: ReportSchema?
    
    func fileDirectoryName() -> String?{
        if let path = filePath {
            return path.deletingLastPathComponent().lastPathComponent
        }
        return nil
    }
    
    func fileDirectoryPath() -> String?{
        if let path = filePath {
            return path.deletingLastPathComponent().absoluteString
        }
        return nil
    }
}
 

enum FileItemType {
    case Assigned
    case Unassigned
}
