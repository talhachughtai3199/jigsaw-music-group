//
//  Logger.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 20/05/25.
//

import Cocoa

class Logger{
    static var res = true
    
    static func log(_ items: Any...){
        print(items)
        
        if(res){
            writeLogs(log: items.debugDescription)
        }
    }
    
    static func writeLogs(log: String){
        let logFilePathUrl = URL(fileURLWithPath: AppInfo.shared.LogFilePath())
        let dt = Utility.DateTimeToStr(date: Date())
        let logToWrite = "\(dt) | \(log)\n"
        
        do{
            let logFileExists = FileManager.default.fileExists(atPath: AppInfo.shared.LogFilePath())
            if(!logFileExists){
                //create New File and write first log
                try logToWrite.write(to: logFilePathUrl, atomically: true, encoding: .utf8)
            }else {
                //append text to existing file
                if let handle = try? FileHandle(forWritingTo: logFilePathUrl) {
                    handle.seekToEndOfFile() // moving pointer to the end
                    handle.write(logToWrite.data(using: .utf8)!) // adding content
                    handle.closeFile() // closing the file
                }
            }
        }catch {
            print(error.localizedDescription)
        }
    }
}
