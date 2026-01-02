//
//  FTPItem.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 13/06/25.
//

import Foundation

class FTPItem {
    let id = UUID().uuidString
    let name: String?
    var path: String? = ""
    var children: [FTPItem]?
    var isDirectory: Bool = true
    var isChecked: Bool = false
    var hasLoaded: Bool = false
    
    let ftpFileManager = FTPFileManager.shared
    
    
    init(name: String, path: String) {
        self.name = name
        self.path = path
        
        self.isDirectory = name.contains(".") ? false : true
    }
    

    func getValidPath(_ itemName: String, _ childName: String) -> String{
        return itemName + childName + "/"
    }
    
    func loadChildren(folderPath: String) async  {
        if(hasLoaded ) { return }
        let result = Task{
            await ftpFileManager.getFoldersOrFiles(folderPath: folderPath)
        }
        let folders = await result.value
        if(!folders.isEmpty){
            children = folders
                .filter{!($0).contains(".")}
                .sorted{$0.localizedCaseInsensitiveCompare($1) == .orderedAscending}
                .map{FTPItem(name: "\($0)", path: getValidPath(self.path ?? "", $0))}
        }else {
            children = []
        }
        self.hasLoaded = true
    }
}

