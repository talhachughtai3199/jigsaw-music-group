//
//  FilesManager.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 22/05/25.
//

import Cocoa
import CSV

class FilesManager{
    static let shared = FilesManager()
    private init(){}
     
    
    var scanDirFiles = ScanDirectoryFiles.shared
    private var report = [ExportReport]()

    private var usdConversion: Double = 0.0
    private var eurConversion: Double = 0.0
    private var adminFee: Double = 0.0

    func updateConversionValues(
        usd: Double,
        eur: Double,
        adminFee: Double
    ) {
        self.usdConversion = usd
        self.eurConversion = eur
        self.adminFee = adminFee
    }
    
    func assignedFilesCount() -> Int{
        return scanDirFiles.files.count{$0.itemType == .Assigned}
    }
    
    func unAssignedFilesCount() -> Int{
        return scanDirFiles.files.count{$0.itemType == .Unassigned}
    }
    
    func scannedFiles() -> [FileDetails]? {
        return scanDirFiles.files
    }
    
    func selectedFiles() -> [FileDetails]? {
        return scanDirFiles.files.filter{$0.isSelected}
    }
    
    func selectedFilesCount() -> Int {
        return scanDirFiles.files.count{$0.isSelected}
    }
    
    func startScan(directoryPath: String) -> Bool{
        do{
            let hasCompleted = try scanDirFiles.startScan(directoryPath: directoryPath)
            if(hasCompleted){
                Logger.log("startScan DirFileCount: ", scanDirFiles.files.count)
            }
            return hasCompleted
        }catch{
            Logger.log("startScan ex", error.localizedDescription)
        }
        return false
    }
     
    
    func clearReportIfAny(){
        if(!report.isEmpty) {report.removeAll()}
    }
 
    
    func shouldProcessFile(file: String, serviceName: String) -> Bool {
        let serviceProcessingPatterns: [String: [String]] = [
            "spo-spotify": [
                "jigsawmusicgroupltd-track-for-breakage",
                "jigsawmusicgroupltd-track-for-streaming"
            ],
            "dzr-deezer": [
                "Deezer_jigsaw-music-group-ltd",
                "jigsaw-music-group-ltd_MERLIN"
            ]
        ]

        // Skip dot files
        if file.hasPrefix(".") {
            return false
        }

        let serviceKeys = Array(serviceProcessingPatterns.keys)

        // If serviceName is not in the map, return true
        guard serviceKeys.contains(serviceName) else {
            return true
        }

        // Check if any pattern matches
        return serviceProcessingPatterns[serviceName]?.contains(where: { file.contains($0) }) ?? false
    }
    
    func parseSpotifyTranscationDate(_ fileContent: String) -> String{
        var spotifyTransactionDate = ""
        let rows = fileContent.components(separatedBy: "\n")
        if rows.count > 1 {
            let firstRow = rows[1]
            let firstRowData = firstRow.components(separatedBy: "\t")
            if firstRowData.count > 2 {
                spotifyTransactionDate = firstRowData[2].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return spotifyTransactionDate
    }
   
    //parsing using CSV package
    func parseFile(file: FileDetails, rowsToSkip: Int) -> Bool{
        
        Logger.log("parseFile: | \(file.service ?? "") | \(file.fileName ?? "") | RowsToSkip: \(rowsToSkip)")
        
        if let schema = file.schema {
            if let filePath = file.filePath{
                if(FileManager.default.fileExists(atPath: filePath.relativePath)){
                    do{
                        guard let fileServiceName = file.service else { return false}
                        guard let serviceBeautifyName = file.serviceBeautifyName else { return false}
                        
                        if(!shouldProcessFile(file: file.fileName!, serviceName: fileServiceName)){
                            Logger.log("skipToProcessFile \(file.fileName!) | \(fileServiceName)")
                            return false
                        }
                        
                        var content = try! String(contentsOf: filePath, encoding: .utf8)
                        
                        var spotifyTranscationDate = ""
                        if(serviceBeautifyName == "Spotify"){
                            spotifyTranscationDate = parseSpotifyTranscationDate(content)
                        }
                        
                        //check if rows to skip
                        if rowsToSkip > 0 {
                            let lines = content.components(separatedBy: .newlines)
                            content = lines.dropFirst(rowsToSkip).joined(separator: "\n")
                        }
                        
                        //check if delimiter is tab
                        var delimiterToUse = ","
                        if let delimiter = schema.options?.delimiter {
                            if(delimiter == "\t"){
                                delimiterToUse = "\t"
                                //content = content.replacingOccurrences(of: "\t", with: ",")
                            }
                        }
                        
                        guard let data = content.data(using: .utf8) else {
                            Logger.log("Invalid encoding")
                            return false
                        }
                          
                        let csv = try! CSVReader(stream: InputStream(data: data),
                                                 hasHeaderRow: true,
                                                 trimFields: true,
                                                 delimiter: delimiterToUse.unicodeScalars.first!,
                                                 whitespaces: [])
                        
                        var reportData = ReportSchema()
                        var columnIndexes = SchemaColumnIndex()
                        
                        //set header
                        if let header = csv.headerRow{
                            //get column index
                            columnIndexes.TransactionDate = getColumnIndex(header, schema.TransactionDate)
                            columnIndexes.Source = getColumnIndex(header, schema.Source ?? "Source")
                            columnIndexes.TrackLabel = getColumnIndex(header, schema.TrackLabel)
                            columnIndexes.ReleaseTitle = getColumnIndex(header, schema.ReleaseTitle)
                            columnIndexes.TrackArtist = getColumnIndex(header, schema.TrackArtist)
                            columnIndexes.TrackTitle = getColumnIndex(header, schema.TrackTitle)
                            columnIndexes.ISRC = getColumnIndex(header, schema.ISRC)
                            columnIndexes.Barcode = getColumnIndex(header, schema.Barcode)
                            columnIndexes.Territory = getColumnIndex(header, schema.Territory)
                            columnIndexes.Currency = getColumnIndex(header, schema.Currency)
                            columnIndexes.NetPayable = getColumnIndex(header, schema.NetPayable)
                            columnIndexes.Units = getColumnIndex(header, schema.Units)
                            
                            if let salesDate = schema.SaleDate, !salesDate.isEmpty{
                                columnIndexes.SaleDate = getColumnIndex(header, salesDate)
                            }
                            
                            if let safeSource = schema.Source, !safeSource.isEmpty{
                                columnIndexes.Source = getColumnIndex(header, safeSource)
                            }
                            
                            if let safeReleaseArtist = schema.ReleaseArtist, !safeReleaseArtist.isEmpty{
                                columnIndexes.ReleaseArtist = getColumnIndex(header, safeReleaseArtist)
                            }
                        }
                        
                        var count = 0
                        var singleReportData = [ReportSchema]()
                        
                        while let row = csv.next() {
                            count += 1
                            if(row.count < columnIndexes.NetPayable){
                                continue
                            }
                            //read schema columns
                            reportData.TransactionDate = serviceBeautifyName == "Spotify"
                            ? spotifyTranscationDate
                            : parseRow(row, columnIndexes.TransactionDate)
                            
                            reportData.Source = parseRow(row, columnIndexes.Source)
                            reportData.TrackLabel = parseRow(row, columnIndexes.TrackLabel)
                            reportData.ReleaseTitle = parseRow(row, columnIndexes.ReleaseTitle)
                            reportData.TrackArtist = parseRow(row, columnIndexes.TrackArtist)
                            reportData.TrackTitle = parseRow(row, columnIndexes.TrackTitle)
                            reportData.ISRC = parseRow(row, columnIndexes.ISRC)
                            reportData.Barcode = parseRow(row, columnIndexes.Barcode)
                            reportData.Territory = parseRow(row, columnIndexes.Territory)
                            reportData.Currency = serviceBeautifyName == "Deezer" ? "EUR" :  parseRow(row, columnIndexes.Currency)
                            reportData.NetPayable = parseRow(row, columnIndexes.NetPayable)
                            reportData.Units = parseRow(row, columnIndexes.Units)
                            
                            //add reportData
                            singleReportData.append(reportData)
                        }
                        
                        if(!singleReportData.isEmpty){
                            report.append(ExportReport(serviceName: file.serviceBeautifyName!, report: singleReportData))
                            
                        }
                       
                        Logger.log("Service: \(file.service ?? "") | Rows Parsed: \(count)")
                        return count > 0 ? true : false
                    }
                }
            }
        }else {
            Logger.log("No schema found for Service: \(file.serviceBeautifyName ?? "")")
        }
        return false
    }
    
    func writeCSV(_ outputFilePath: URL, onCompleted: @escaping(Int, Int)-> ()) async -> Bool {
        Logger.log("---------")
        Logger.log("Writing CSV to: \(outputFilePath)")
        
        var totalNetPay:Decimal = 0
        
        if(report.isEmpty) {
            Logger.log("no data to write")
            return false
        }
        
        let stream = OutputStream(toFileAtPath: outputFilePath.relativePath, append: false)!
        let csv = try! CSVWriter(stream: stream)

        //add header
        try! csv.write(row: ["Sale Date",
                             "Transaction Date",
                             "Source",
                             "Territory",
                             "Barcode",
                             "Release Title",
                             "Release Version",
                             "Release Artist",
                             "Release Label",
                             "ISRC",
                             "Track Title",
                             "Track Version",
                             "Track Artist",
                             "Track Label",
                             "Units",
                             "Net Amount",
                             "Net Payable",
                             "Net Payable after Merlin Fee",
                             "Currency",
                             "Admin Fee",
                             "Net Payable GBP"
                            ])
        
        //add rows to csv
        //report.sort{$0.serviceName < $1.serviceName }
        let sortedReport = report.sorted { $0.serviceName.lowercased() < $1.serviceName.lowercased() }
        
        for j in 0..<sortedReport.count{
            
            var currentNetPay:Decimal = 0
            let currentService = sortedReport[j].serviceName
            let currentReport = sortedReport[j].report
            
            
            for i in 0..<currentReport.count{
                let row = currentReport[i]
                
                let netPay = parseNetPay(row.NetPayable)
                currentNetPay = currentNetPay + netPay
                let parsedTrascationDate = processServiceDateFormatRules(currentService, row.TransactionDate)
                let parsedSaleDate = processServiceDateFormatRules(currentService, row.SaleDate ?? "")
                let netPaybleAfterMerlinFee = getNetPaybleAfterMerlinFee(row.NetPayable)
                let source = parseServiceSource(currentService, row.Source ?? "")
                let currency = parseCurrency(currentService, row.Currency)
                
                let adminFee = "\(self.adminFee)"
                let netPayableGBP = calculateGrossGBP(currency: currency, netPayable: NSDecimalNumber(decimal: netPay).doubleValue)
               
                //avoid adding empty rows
                var shouldAddRow = true
                if(currentService == "Spotify"){
                    shouldAddRow = row.Currency.isEmpty ? false : true
                }else {
                    shouldAddRow = (row.ReleaseTitle.isEmpty && row.TrackTitle.isEmpty) ? false : true
                }
                
                if(shouldAddRow){
                    try! csv.write(row: [parsedSaleDate, //row.SaleDate
                                         parsedTrascationDate, //row.TransactionDate,
                                         source,
                                         row.Territory,
                                         row.Barcode,
                                         row.ReleaseTitle,
                                         "", //Release Version
                                         row.ReleaseArtist ?? "",
                                         row.ReleaseLabel ?? "",
                                         row.ISRC,
                                         row.TrackTitle,
                                         "", //Track Version
                                         row.TrackArtist,
                                         row.TrackLabel,
                                         row.Units,
                                         "", //Net Amount
                                         String("\(netPay)"),
                                         netPaybleAfterMerlinFee,
                                         currency,
                                         String("\(adminFee)%"),
                                         String("\(netPayableGBP)")
                                        ])
                }
                
                onCompleted(i + 1, sortedReport.count)
                
                // Delay 1 second (non-blocking)
                if(i % 10 == 0){
                    try? await Task.sleep(nanoseconds: 1_000_000)
                }
            }
            
            totalNetPay = totalNetPay + currentNetPay
            Logger.log("Service: \(currentService) | Netpay: \(currentNetPay) | TotalNetPay: \(totalNetPay)")
        }
        

        csv.stream.close()
        
        //save report summary
        Logger.log("Saving report completed. totalNetPay: \(totalNetPay)")
        saveReportSummary(NSDecimalNumber(decimal: totalNetPay).doubleValue, outputFilePath.relativePath)
        return true
    }
    
    func parseCurrency(_ serviceName: String, _ currency: String) -> String{
        var res = !currency.isEmpty ? currency : "USD"
        let allowedCurrencies = ["USD", "EUR", "GBP"]
        
        if(currency == "Deezer"){
            res = "EUR"
        }
        
        return allowedCurrencies.contains(res) ? res : "USD"
    }
    
    func parseServiceSource(_ serviceName: String, _ source: String) -> String{
        var res = serviceName
        if(!source.isEmpty && serviceName == "AudioSalad"){
            //AudioSalad csv as that one already contains the Source value
            res = source
        }
        return res
    }
    
    func getNetPaybleAfterMerlinFee(_ netPaybleFee: String) -> String{
//        var res = ""
//        if(!netPaybleFee.isEmpty){
//            let tmpFee = (Double(netPaybleFee) ?? 0.0 * 1.5) / 100
//            res = "\(String(format: "%.8f", tmpFee))"
//        }
        return netPaybleFee
    }
    
    func calculateGrossGBP(currency: String, netPayable: Double) -> Double {

        let adminMultiplier = 1 - (self.adminFee / 100)
        var amountInGBP: Double = 0.0

        switch currency.uppercased() {
            case "EUR":
                amountInGBP = netPayable * self.eurConversion
            case "USD":
                amountInGBP = netPayable * self.usdConversion
            case "GBP":
                amountInGBP = netPayable
            default:
                amountInGBP = netPayable
        }

        return amountInGBP * adminMultiplier
    }
    
    func processServiceDateFormatRules(_ serviceName: String, _ tDate: String) -> String{
        var res = ""
        if(tDate.isEmpty) { return res}
        
        if(serviceName == "Soundcloud"){
            let dateItems = tDate.split(separator: "-")
            let month = Int(dateItems[0]) ?? 0
            let year = Int(dateItems[1]) ?? 0
             
            if(month < 1 || month > 12){
                Logger.log("Invalid date format: \(tDate)")
                return ""
            }
            
            // Get the last day of the month
            let day = Utility.lastDayOfMonth(ofMonth: month, year: year)
            res = "\(year)-\(month.padded2Digits)-\(day.padded2Digits)"
            
        }else if(serviceName == "Tiktok"){
            
            let dateStr = tDate
            let version1 = try! NSRegularExpression(pattern: "^\\d{8}$")
            let version2 = try! NSRegularExpression(pattern: "^\\d{4}-\\d{2}-\\d{2}$")
            
            let range = NSRange(location: 0, length: dateStr.utf16.count)
            let isType1 = version1.firstMatch(in: dateStr, options: [], range: range) != nil
            let isType2 = version2.firstMatch(in: dateStr, options: [], range: range) != nil
            
            guard isType1 || isType2 else {
                return dateStr
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            
            if isType1 {
                let year = String(dateStr.prefix(4))
                let month = String(dateStr.dropFirst(4).prefix(2))
                let day = String(dateStr.dropFirst(6).prefix(2))
                
                let formatted = "\(year)-\(month)-\(day)"
                if let date = formatter.date(from: formatted) {
                    return date.toyyyyMMddString()
                } else {
                    return dateStr
                }
            }
            
            if isType2 {
                let parts = dateStr.split(separator: "-").map { String($0) }
                guard parts.count == 3,
                      let year = Int(parts[0]),
                      let month = Int(parts[1]),
                      let day = Int(parts[2]) else {
                    return dateStr
                }
                
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = day
                
                let calendar = Calendar(identifier: .gregorian)
                if let date = calendar.date(from: dateComponents) {
                    return date.toyyyyMMddString()
                } else {
                    return dateStr
                }
            }
            
            return dateStr
            
        }else if(serviceName == "Pandora"){
            let dateString = tDate
            let inputFormatter = DateFormatter()
            inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'UTC'"
            inputFormatter.timeZone = TimeZone(abbreviation: "UTC")

            if let date = inputFormatter.date(from: dateString) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "yyyy-MM-dd"
                outputFormatter.timeZone = TimeZone(abbreviation: "UTC")
                
                let _ = outputFormatter.string(from: date)
                //res = formattedDate
                res = date.toyyyyMMddString()
            } else {
                Logger.log("Failed to parse date")
            }
        }else if(serviceName == "Boomplay" ||
                 serviceName == "Trebel" ||
                 serviceName == "Resso" ||
                 serviceName == "Peloton" ||
                 serviceName == "Tencent"){
            
            if (tDate.count != 8){
                Logger.log("Invalid date format: \(tDate)")
                return ""
            }
            
            let yearStr = tDate.slice(from: 0, to: 4)
            let monthStr = tDate.slice(from: 4, to: 6)
            let dayStr = tDate.slice(from: 6, to: 8)
            
            if(!yearStr.isEmpty && !monthStr.isEmpty && !dayStr.isEmpty){
                let year = Int(yearStr) ?? 0
                let month = Int(monthStr) ?? 0
                let day = Int(dayStr) ?? 0
                
                res = Date.from(year: year, month: month, day: day)!.toyyyyMMddString()
            }else {
                res = "\(yearStr)-\(monthStr)-\(dayStr)"
            }
        }else if(serviceName == "Anghami" ||
                 serviceName == "NetEase Cloud Music" ||
                 serviceName == "AWA" ||
                 serviceName == "Canva"){
            
            let dateItems = tDate.split(separator: "/")
            
            var year = Int(dateItems[2]) ?? 0
            let month = Int(dateItems[1]) ?? 0
            var day = Int(dateItems[0]) ?? 0
            
            //if date format is parsed using yyyy/mm/dd
            if(year < 2000){
                year = Int(dateItems[0]) ?? 0
                day = Int(dateItems[2]) ?? 0
            }
            
            if(day < 1) {return ""}
            if(month < 1 || month > 12) {return ""}
            if(year < 1) {return ""}
            
            res = Date.from(year: year, month: month, day: day)!.toyyyyMMddString()
        }else if(serviceName == "iHeart"){
            
            let dateItems = tDate.split(separator: "/")
           
            let month = Int(dateItems[0]) ?? 0
            let day = Int(dateItems[1]) ?? 0
            let year = Int(dateItems[2]) ?? 0
            
            if(day < 1) {return ""}
            if(month < 1 || month > 12) {return ""}
            if(year < 1) {return ""}
            
            res = Date.from(year: year, month: month, day: day)!.toISOString()
        }
        else if(serviceName == "Deezer"){
            let dateItems = tDate.split(separator: "-")
            
            let day = Int(dateItems[0]) ?? 0
            let month = Int(dateItems[1]) ?? 0
            let year = Int(dateItems[2]) ?? 0
            
            if(day < 1) {return ""}
            if(month < 1 || month > 12) {return ""}
            if(year < 1) {return ""}
            
            res = Date.from(year: year, month: month, day: day)!.toyyyyMMddString()
        }else if(serviceName == "AudioSalad" || serviceName == "Snap"){
            let dateItems = tDate.split(separator: "-")
            
            let year = Int(dateItems[0]) ?? 0
            let month = Int(dateItems[1]) ?? 0
            let day = Int(dateItems[2]) ?? 0
            
            if(day < 1) {return ""}
            if(month < 1 || month > 12) {return ""}
            if(year < 1) {return ""}
            
            res = Date.from(year: year, month: month, day: day)!.toyyyyMMddString()
        }else {
            res = tDate
        }
        
        return res
    }
    
    func parseNetPay(_ netPay: String) -> Decimal {
        Decimal(string: netPay.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    
    func saveReportSummary(_ totalNetPay: Double, _ filePath: String){
        var report = ReportDetails()
        report.Currency = "USD"
        report.Date = Date()
        report.NetPay = totalNetPay
        report.ReportFilePath = filePath
        
        ReportManager.shared.addReport(report)
    }
    
    func getColumnIndex(_ header: [String], _ columnNameFromSchema: String) -> Int {
        if(header.isEmpty) { return -1 }
        if(columnNameFromSchema.isEmpty) { return -1 }
        return header.firstIndex(of: columnNameFromSchema) ?? -1
    }
    
    func parseRow(_ row: [String], _ columnIndex: Int) -> String {
        if(columnIndex == -1) { return "" }
        if(row.isEmpty) { return ""}
        
        return row[columnIndex]
    }
}

struct ExportReport{
    let serviceName: String
    let report: [ReportSchema]
}

