//
//  ReportManager.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 06/06/25.
//

class ReportManager {
    static let shared = ReportManager()
    private init(){}
    
    let dbManager = SqliteManager.shared
    var reports = [ReportDetails]()
    
    func getReports() {
        if(!reports.isEmpty) { reports.removeAll()}
        
        let cmd = "SELECT * from tbl_Report"
        
        do {
            let result = try dbManager.database.executeQuery(cmd, values: nil)
            while result.next() {
                
                var report = ReportDetails()
                
                let reportDate = Utility.fromUnixTimeStamp(value: Double(result.int(forColumn: "Date")))
                report.Id = Int(result.int(forColumn: "Id"))
                report.ReportTitle = Utility.formatDateToMMMMyyyy(reportDate!)
                
                report.ReportFilePath = result.string(forColumn: "ReportFilePath")?.fromBase64()
                report.Date = reportDate
                
                report.NetPay = result.double(forColumn: "NetPay")
                report.Currency = result.string(forColumn: "Currency")
                
                reports.append(report)
            }
            
            if(!reports.isEmpty){
                //sort by descending
                reports.sort{$0.Date! > $1.Date! }
            }
        }catch{
            print("Error while getting reports")
            print(error.localizedDescription)
        }
    }
    
    func deleteReport(_ report: ReportDetails) -> Bool{
        var res = false
        do{
            //remove file
            if(FileManager.default.fileExists(atPath: report.ReportFilePath!)){
                try FileManager.default.removeItem(atPath: report.ReportFilePath!)
            }
            
            //remove db entry
            let cmdDelete = "DELETE FROM tbl_Report WHERE ID=\(report.Id!)"
            try dbManager.database.executeUpdate(cmdDelete, values: nil)
             
            if let itemIndex = reports.firstIndex(where: {$0.Id == report.Id!}){
                reports.remove(at: itemIndex)
                res = true
            } 
        }catch{
            print("failed to remove report details")
            print(error.localizedDescription)
        }
        return res
    }
    
    func addReport(_ reportDetails: ReportDetails){
        _ = saveReportToDb(reportDetails, shouldUpdate: false)
    }
    
    private func saveReportToDb(_ reportDetails: ReportDetails, shouldUpdate: Bool) -> Bool{
        var res = false
        var cmd = ""
        
        if (!shouldUpdate)
        {
            cmd = "INSERT INTO tbl_Report ("
            cmd += "ReportFilePath, "
            cmd += "Date, "
            cmd += "NetPay, "
            cmd += "Currency) "
            cmd += "VALUES('\(Utility.parseStr(value: reportDetails.ReportFilePath).toBase64())', "
            cmd += "\(Utility.parseInt(value: Int(Utility.toUnixTimeStamp(value: reportDetails.Date)))), "
            cmd += "\(Utility.parseDouble(value: reportDetails.NetPay)), "
            cmd += "'\(Utility.parseStr(value: reportDetails.Currency))');"
        }
        else
        {
            cmd = "UPDATE tbl_Report SET ";
            cmd += "ReportFilePath='\(Utility.parseStr(value: reportDetails.ReportFilePath))', "
            cmd += "Date=\(Utility.parseInt(value: Int(Utility.toUnixTimeStamp(value: reportDetails.Date)))), "
            cmd += "NetPay=\(Utility.parseDouble(value: reportDetails.NetPay)), "
            cmd += "Currency='\(Utility.parseStr(value: reportDetails.Currency))';"
        }
        
        do {
            try dbManager.database.executeUpdate(cmd, values: nil)
            res = true
            print("Report details saved to db")
        }catch{
            print("failed to save report details")
            print(error.localizedDescription)
        }
        return res
    }
    
    func deleteReports(){
        
    }
}

struct ReportDetails{
    var Id: Int?
    var ReportTitle: String?
    var ReportFilePath: String?
    var Date: Date?
    var NetPay: Double?
    var Currency: String?
}
