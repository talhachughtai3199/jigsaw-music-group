//
//  SqliteManager.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 27/05/25.
//

import Foundation

 
class SqliteManager{
    let databaseFileName = "appdata.dat"
    
    var pathToDatabase: String!
    
    var database: FMDatabase!
    
    static let shared = SqliteManager()
    private init(){
        pathToDatabase = AppInfo.shared.AppDbPath() 
    }
    
    func isDbExists() -> Bool {
        var res = false
        if FileManager.default.fileExists(atPath: pathToDatabase) {
            res = true
        }
        return res
    }
    
    func initializeDatabase() {
        database = FMDatabase(path: pathToDatabase!)
        
        if database != nil {
            // Open the database to create database file
            if database.open() {
                //database.close()
            }
            else {
                print("Could not open the database.")
            }
        }
    }
    
    func closeDbConnection()-> Bool{
        var res = false
        if(database != nil){
            if(database!.isOpen){
                database!.close()
                res = true
            }else {
                res = true
            }
        }
        return res
    }
    
    func createTblFTPSettingsIfNotAvailable(){
        do {
            let query =  "CREATE TABLE `tbl_FTPSettings` (" +
            "`Host`    TEXT," +
            "Port    Int," +
            "`Username`    TEXT," +
            "`Password`    TEXT," +
            "Mode    Int," +
            "UseSecureConnection    Int);";
            
            
            try database.executeUpdate(query, values: nil)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func createTblReportIfNotAvailable(){
        do {
            let query =  "CREATE TABLE `tbl_Report` (" +
            "ID INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "`ReportFilePath`   TEXT," +
            "Date           Int," +
            "NetPay         Int," +
            "`Currency`     TEXT);";
            
            
            try database.executeUpdate(query, values: nil)
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
