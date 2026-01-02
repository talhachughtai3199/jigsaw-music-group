//
//  Utility.swift
//  SongwritersdB
//
//  Created by Gaurav Kundalwal on 06/01/23.
//

import Foundation
import Cocoa
import AVFoundation

class Utility{
     
    static func getCurrentBuildVersion()-> Int{
        var buildVersion = 1
        let buildVersionStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String  //returns build number
        //let buildVersionStr = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String //returns version number
        if let tmpBuildVerStr = buildVersionStr{
            if(!tmpBuildVerStr.isEmpty){
                buildVersion = Int(tmpBuildVerStr) ?? 1
            }
        }
        return buildVersion
    }
    
    static func getCurrentVersion()-> String{
        return  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String  //returns version number
    }
    
    static func fromUnixTimeStamp(value: Double)-> Date?{
        return Date(timeIntervalSince1970: value)
    }
    
    static func toUnixTimeStamp(value: Date?)-> Double{
        if let value = value {
            return value.timeIntervalSince1970
        }else {
            return 0
        }
    }
     
    
    static func getCurrentYear() -> Int{
        return Calendar.current.component(.year, from: Date())
    }
     
    
    static func browseFileLocationInFinder(filePath: String){
        let url = URL(fileURLWithPath: filePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    static func openUrl(url: String){
        guard let urlToOpen = URL(string: url) else {
            return //be safe
        }
        NSWorkspace.shared.open(urlToOpen)
    }
    
    static func showAndSelectFileInFinder(path: String){
        let filePath = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([filePath])
    }
    
    static func getFileSize(filePath: String)-> UInt64{
        var fileSize : UInt64 = 0
        do{
            let attr = try? FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attr?[FileAttributeKey.size]{
                fileSize = size as! uint64
            }
        }catch {
            print("Error: \(error)")
        }
        
        return fileSize
    }
    
    static func getFileSizeStr(fileSize: Int64)->String{
        var sizeStr = "0 KB"
        if(fileSize > 0){
            let fileSizeWithUnit = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            sizeStr = fileSizeWithUnit
        }
        return sizeStr
    }
     
    static func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    static func minsToSeconds(_ mins: Int) -> Double {
        return Double(mins * 60)
    }
     
    
    static func getSystemName() -> String {
        if let systemName = Host.current().localizedName {
            return systemName
        }
        
        return "Unknown"
    }
    
    static func getSystemAppearance() -> Bool {
        var isDarkMode = false
        if #available(OSX 10.14, *) {
            isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return isDarkMode
    }
     
    
    static func getFileFormatStr(filePath: String) -> String{
        let ext = URL(fileURLWithPath: filePath).pathExtension
        return ext.uppercased()
    }
    
    static func DateTimeToStr(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMMM-yyyy, hh:mm:ss"
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: date)
    }
    
    static func formatDateToDDMMYYYY(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy hh:mm a" // "a" for AM/PM
        return formatter.string(from: date)
    }
    
    static func formatDateToMMMMyyyy(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
     
    func fileDirectoryPath(_ filePath: String) -> String{
        let path = URL(fileURLWithPath: filePath)
        return path.deletingLastPathComponent().absoluteString
    }
    
    static func deleteFileIfExists(songFilePath: String) -> Bool{
        var res = false
        do{
            //remove existing file
            if(FileManager.default.fileExists(atPath: songFilePath)){
                try? FileManager.default.removeItem(atPath: songFilePath)
                Logger.log("File removed successfully")
            }else {
                Logger.log("File do not exists")
            }
            
            res = true
        }catch{
            Logger.log("deleteFileIfExists - ex")
            Logger.log(error.localizedDescription)
        }
        return res
    }
    
    static func restartApp(){
        Process.launchedProcess(launchPath: "/usr/bin/open", arguments: ["-b", Bundle.main.bundleIdentifier!])
        NSApp.terminate(self)
    }
    
    static func getFileWriteDate(filePath: String?) -> Date?{
        var fileDate: Date? = nil
        if let path = filePath{
            do{
                let fileExists = FileManager.default.fileExists(atPath: path)
                if(fileExists){
                    let attrs = try FileManager.default.attributesOfItem(atPath: path) as NSDictionary
                   fileDate = attrs.fileCreationDate()
                }
            }catch{
                Logger.log(error.localizedDescription)
            }
        }
        return fileDate
    }
    
    static func parseStr(value: String?) -> String{
        var val = ""
        if let tmpValue = value{
            val = tmpValue.isEmpty ? "" : tmpValue
        }
        return val
    }
    
    static func parseInt(value: Int?) -> Int{
        var val = 0
        if let tmpValue = value{
            val = tmpValue
        }
        return val
    }
    
    static func parseDouble(value: Double?) -> Double{
        var val = 0.0
        if let tmpValue = value{
            val = tmpValue
        }
        return val
    }
    
    
    static func getDayName(from dayIndex: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        if let date = calendar.date(byAdding: .day, value: dayIndex - calendar.component(.weekday, from: today), to: today) {
            return formatter.string(from: date)
        }
        return "Sunday"
    }
    
    static func getUTCDay() -> String{
        let utcCalendar = Calendar(identifier: .gregorian)
        let utcTimeZone = TimeZone(secondsFromGMT: 0)!  // UTC time zone
        let utcComponents = utcCalendar.dateComponents(in: utcTimeZone, from: Date())
        if let day = utcComponents.day {
            return getDayName(from: day)
        }
        return "Sunday"
    }
    
    static func getDisplayHours(mins: Int) -> String{
        let secs = minsToSeconds(mins)
        let (h,m,s) = secondsToHoursMinutesSeconds(Int(secs))
        
        //let timeString = String(format: "%02d", h) + ":" + String(format: "%02d", m) + ":" + String(format: "%02d", s)
        let timeString = String(format: "%02d", h) + ":" + String(format: "%02d", m)
        return timeString
    }
    
    static func formatIntTo2Digits(_ value: Int)-> String{
        return String(format: "%02d", value)
    }
     
    func parseColumnStrFromBase64(result: FMResultSet, columnName: String) -> String? {
        if let value = result.string(forColumn: columnName){
            if(!value.isEmpty){
                return value.fromBase64()
            }
        }
        return nil
    }
    
    static func createFolderIfNotExists(_ folderPath: URL) -> Bool{
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folderPath.path) {
            do {
                try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                Logger.log("Folder created at: \(folderPath.path)")
            } catch {
                Logger.log("Error creating folder: \(error.localizedDescription)")
                return false
            }
        }
        return true
    }
    
    static func getTimeDifference(_ startTime: Date, _ stopTime: Date) -> String{
        let difference = Calendar.current.dateComponents([.hour, .minute, .second], from: startTime, to: stopTime)
        return "Time difference: \(difference.hour ?? 0)h \(difference.minute ?? 0)m \(difference.second ?? 0)s"
    }
    
    static func lastDayOfMonth(ofMonth month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0  // 0th day of next month = last day of given month

        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            return calendar.component(.day, from: date)
        }
        return 30
    }  
}

