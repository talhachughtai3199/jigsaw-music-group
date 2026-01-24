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
    
    func createTblReportSchemaIfNotAvailable() {
           let query = """
           CREATE TABLE IF NOT EXISTS tbl_ReportSchema (
               ServiceName TEXT PRIMARY KEY,
               TransactionDate TEXT,
               TrackLabel TEXT,
               ReleaseTitle TEXT,
               TrackArtist TEXT,
               TrackTitle TEXT,
               ISRC TEXT,
               Barcode TEXT,
               Territory TEXT,
               Currency TEXT,
               NetPayable TEXT,
               Units TEXT,
               SaleDate TEXT,
               Source TEXT,
               ReleaseArtist TEXT,
               ReleaseLabel TEXT,
               FileNameRegex TEXT,
               Delimiter TEXT,
               SkipRows INTEGER DEFAULT 0
           );
           """
            do{
                try database.executeUpdate(query, values: nil)
            }
            catch {
                print(error.localizedDescription)
            }
       }
    
    func migrateReportSchemaIfNeeded() {
        let migrations = [
            "ALTER TABLE tbl_ReportSchema ADD COLUMN FileNameRegex TEXT",
            "ALTER TABLE tbl_ReportSchema ADD COLUMN Delimiter TEXT",
            "ALTER TABLE tbl_ReportSchema ADD COLUMN SkipRows INTEGER DEFAULT 0"
        ]
        
        for sql in migrations {
            do {
                try database.executeUpdate(sql, values: nil)
            } catch {
                // Ignore "duplicate column" errors
                print("Migration skipped:", error.localizedDescription)
            }
        }
    }

       
    func saveReportSchema(service: String, schema: ReportSchema) {
        let query = """
        INSERT INTO tbl_ReportSchema (
            ServiceName, TransactionDate, TrackLabel, ReleaseTitle,
            TrackArtist, TrackTitle, ISRC, Barcode, Territory,
            Currency, NetPayable, Units, SaleDate, Source,
            ReleaseArtist, ReleaseLabel, FileNameRegex, Delimiter, SkipRows
        )
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ON CONFLICT(ServiceName) DO UPDATE SET
            TransactionDate = excluded.TransactionDate,
            TrackLabel = excluded.TrackLabel,
            ReleaseTitle = excluded.ReleaseTitle,
            TrackArtist = excluded.TrackArtist,
            TrackTitle = excluded.TrackTitle,
            ISRC = excluded.ISRC,
            Barcode = excluded.Barcode,
            Territory = excluded.Territory,
            Currency = excluded.Currency,
            NetPayable = excluded.NetPayable,
            Units = excluded.Units,
            SaleDate = excluded.SaleDate,
            Source = excluded.Source,
            ReleaseArtist = excluded.ReleaseArtist,
            ReleaseLabel = excluded.ReleaseLabel,
            FileNameRegex = excluded.FileNameRegex,
            Delimiter = excluded.Delimiter,
            SkipRows = excluded.SkipRows
        """
        
        let values: [Any] = [
            service,
            schema.TransactionDate,
            schema.TrackLabel,
            schema.ReleaseTitle,
            schema.TrackArtist,
            schema.TrackTitle,
            schema.ISRC,
            schema.Barcode,
            schema.Territory,
            schema.Currency,
            schema.NetPayable,
            schema.Units,
            schema.SaleDate ?? "",
            schema.Source ?? "",
            schema.ReleaseArtist ?? "",
            schema.ReleaseLabel ?? "",
            schema.FileNameRegex ?? "",
            schema.options?.delimiter ?? ",",
            schema.options?.skipRows ?? ""
            
        ]
        
        do {
            try database.executeUpdate(query, values: values)
        } catch {
            print(error.localizedDescription)
        }
    }

    func getAllServiceNames() -> [String] {
        var services: [String] = []
        
        let query = """
        SELECT ServiceName
        FROM tbl_ReportSchema
        ORDER BY ServiceName COLLATE NOCASE
        """
        
        if let rs = database.executeQuery(query, withArgumentsIn: []) {
            defer { rs.close() }
            
            while rs.next() {
                if let name = rs.string(forColumn: "ServiceName") {
                    services.append(name)
                }
            }
        }
        
        return services
    }

    
    func loadReportSchema(service: String) -> ReportSchema? {
        
        let query = "SELECT * FROM tbl_ReportSchema WHERE ServiceName = ?"
        
        if let rs = database.executeQuery(query, withArgumentsIn: [service]) {
            defer { rs.close() }
            
            if rs.next() {
                return ReportSchema(
                    TransactionDate: rs.string(forColumn: "TransactionDate") ?? "",
                    TrackLabel: rs.string(forColumn: "TrackLabel") ?? "",
                    ReleaseTitle: rs.string(forColumn: "ReleaseTitle") ?? "",
                    TrackArtist: rs.string(forColumn: "TrackArtist") ?? "",
                    TrackTitle: rs.string(forColumn: "TrackTitle") ?? "",
                    ISRC: rs.string(forColumn: "ISRC") ?? "",
                    Barcode: rs.string(forColumn: "Barcode") ?? "",
                    Territory: rs.string(forColumn: "Territory") ?? "",
                    Currency: rs.string(forColumn: "Currency") ?? "",
                    NetPayable: rs.string(forColumn: "NetPayable") ?? "",
                    Units: rs.string(forColumn: "Units") ?? "",
                    SaleDate: rs.string(forColumn: "SaleDate"),
                    Source: rs.string(forColumn: "Source"),
                    ReleaseArtist: rs.string(forColumn: "ReleaseArtist"),
                    ReleaseLabel: rs.string(forColumn: "ReleaseLabel"),
                    FileNameRegex: rs.string(forColumn: "FileNameRegex"),
                    options: Options(skipRows: Int(rs.int(forColumn: "SkipRows")),
                                     delimiter: rs.string(forColumn: "Delimiter"))
                )
            }
        }
        
        if let defaultSchema = Services.shared.schemas[service] {
            saveReportSchema(service: service, schema: defaultSchema)
            return defaultSchema
        }
        
        return nil
    }
    
    func getAllReportSchemas() -> [String: ReportSchema] {
        var result: [String: ReportSchema] = [:]

        let query = "SELECT * FROM tbl_ReportSchema"

        if let rs = database.executeQuery(query, withArgumentsIn: []) {
            defer { rs.close() }

            while rs.next() {
                let serviceName = rs.string(forColumn: "ServiceName") ?? ""

                let schema = ReportSchema(
                    TransactionDate: rs.string(forColumn: "TransactionDate") ?? "",
                    TrackLabel: rs.string(forColumn: "TrackLabel") ?? "",
                    ReleaseTitle: rs.string(forColumn: "ReleaseTitle") ?? "",
                    TrackArtist: rs.string(forColumn: "TrackArtist") ?? "",
                    TrackTitle: rs.string(forColumn: "TrackTitle") ?? "",
                    ISRC: rs.string(forColumn: "ISRC") ?? "",
                    Barcode: rs.string(forColumn: "Barcode") ?? "",
                    Territory: rs.string(forColumn: "Territory") ?? "",
                    Currency: rs.string(forColumn: "Currency") ?? "",
                    NetPayable: rs.string(forColumn: "NetPayable") ?? "",
                    Units: rs.string(forColumn: "Units") ?? "",
                    SaleDate: rs.string(forColumn: "SaleDate"),
                    Source: rs.string(forColumn: "Source"),
                    ReleaseArtist: rs.string(forColumn: "ReleaseArtist"),
                    ReleaseLabel: rs.string(forColumn: "ReleaseLabel"),
                    FileNameRegex: rs.string(forColumn: "FileNameRegex"),
                    options: Options(skipRows: Int(rs.int(forColumn: "SkipRows")),
                                     delimiter: rs.string(forColumn: "Delimiter"))
                )

                result[serviceName] = schema
            }
        }

        return result
    }


   
    func seedAllSchemasIfMissing() {
        for (service, schema) in Services.shared.schemas {
            _ = loadReportSchema(service: service)
        }
    }

}
