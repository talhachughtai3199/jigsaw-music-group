//
//  ProcessingFilesViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 02/06/25.
//

import Cocoa

class ProcessingFilesViewController : NSViewController {
    @IBOutlet weak var LblTitle: NSTextField!
    @IBOutlet weak var LblFileName: NSTextField!
    @IBOutlet weak var LblFileCount: NSTextField!
    
    @IBOutlet weak var BtnCancel: NSButton!
    
    @IBOutlet weak var AppProgress: NSProgressIndicator!
    
    let scanManager = ScanDirectoryFiles.shared
    let filesManager = FilesManager.shared
    let reportManager = ReportManager.shared
    let config = Configuration.shared
    
    var filesToProcess: [FileDetails]?
    var outputFilePath: URL?
    
    var current = 0
    var total = 0
    var success = 0
    var failed = 0
    var hasCancelled = false
    
    var isPaused = false
    var continuation: CheckedContinuation<Void, Never>?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initializeSettings()
        //startLoop()
    }
    
    override func viewDidAppear() {
        //update total
        total = filesToProcess?.count ?? 0
        AppProgress.maxValue = Double(total)
        
        Task{
            await startScanning()
        }
    }
    
    func initializeSettings(){
        current = 0
        success = 0
        failed = 0
        
        //setup progress bar
        AppProgress.controlTint = .blueControlTint
        AppProgress.doubleValue = 0.0
    }
    
    func waitForUserAction() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func scanFiles() async -> Bool {
        let taskResult = Task {
            var res = false
            if let files = filesToProcess{
                
                Logger.log("Processing files: \(files.count)")
                filesManager.clearReportIfAny()
                
                for i in 0..<files.count {
                    //check if cancelled
                    if(hasCancelled) {break}
                    
                    //wait until user action
                    if(isPaused){
                        await waitForUserAction()
                    }
                    
                    
                    let file = files[i]
                    
                    var rowsToSkip = 0
                    if let safeRowsToSkip = file.schema?.options?.skipRows{
                        rowsToSkip = safeRowsToSkip
                    } 
                        
                    let res = filesManager.parseFile(file: file, rowsToSkip: rowsToSkip )
                    if(res) {
                        success += 1
                    }else {
                        failed += 1
                    }
                    
                    DispatchQueue.main.async{
                        //update UI
                        self.current += 1
                        self.AppProgress.doubleValue = Double(self.current)
                        
                        self.LblFileName.stringValue = file.filePath!.relativePath
                        self.LblFileCount.stringValue = "\(self.current) of \(self.total) \(self.total == 1 ? "file" : "files")"
                    }
                   
                    
                    // Delay 1 second (non-blocking)
                    try? await Task.sleep(nanoseconds: 1_000_000_00)
                }
                
                //show completed state
                if(self.success > 0){
                    Logger.log("Process result - Success: \(success) | Failed: \(failed)")
                    res = true
                }
            }
            
            return res
        }
        
        return await taskResult.value
    }
    
    func writeCSV() async -> Bool {
        let taskResult = Task {
            var res = false
            if let path = outputFilePath{
                
                DispatchQueue.main.async{
                    //reset app progress
                    self.AppProgress.doubleValue = 0.0
                    self.LblTitle.stringValue = "Saving"
                    self.LblFileName.stringValue = path.relativePath
                    self.LblFileCount.stringValue = "Please wait..."
                }
               
                
                let resultFileWrite = await filesManager.writeCSV(path, onCompleted: {curRow, totalRows in
                    let progress = (Double(curRow) / Double(totalRows)) * 100
                    let progressValue = Double(progress / 100)
                    
                    DispatchQueue.main.async{
                        self.AppProgress.doubleValue = progressValue
                    }
                })
                
                if (resultFileWrite){
                    DispatchQueue.main.async{
                        self.AppProgress.doubleValue = 100.0
                        self.LblFileCount.stringValue = "Completed"
                    }
                    
                    res = true
                }
            }
            return res
        }
        
        
        return await taskResult.value
    }
    
    func startScanning() async {
        let resScanFiles = await scanFiles()
        if(resScanFiles){
            let writeCSV = await writeCSV()
            if(writeCSV){
                //show completed status msg
                showCompleteStatus()
                
                //clear files
                scanManager.clearFiles()
                
                //refresh navbar
                reportManager.getReports()
                config.navVC?.refreshNavItems()
                
                //0.07
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.config.navVC?.selectDefaultItem()
                }
                
                config.mainTab?.SwitchTab(screen: .SummaryReport)
            }else {
                DispatchQueue.main.async{
                    self.showFailedMsg()
                }
            }
        }else {
            DispatchQueue.main.async{
                self.showFailedMsg()
            }
        }
    }
    
    func showFailedMsg(){
        showMsg("Processing Failed", "One or more files failed to process. Please check app logs for details.")
        self.view.window?.close()
    }
     
    func resetFlags(){
        //reset flags
        if(isPaused){
            continuation?.resume()
        }
        continuation = nil
        isPaused = false
        hasCancelled = false
    }
    
    func showMsg(_ title: String, _ msg: String, isSuccessMsg: Bool = false){
        let msg = msg
        let alert: NSAlert = NSAlert()
        alert.messageText = title
        alert.informativeText = msg
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = NSAlert.Style.warning
        alert.icon = isSuccessMsg == true ? NSImage.imgCheck : NSImage.imgWarning
        
        let res = alert.runModal()
        if(res == .alertFirstButtonReturn){
        }
    }
    
    func showCompleteStatus(){
        let msg = "One or more selected files have processed and report saved."
        let alert: NSAlert = NSAlert()
        alert.messageText = "Completed"
        alert.informativeText = msg
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = NSAlert.Style.informational
        alert.icon = NSImage.imgCheck
        
        let res = alert.runModal()
        if(res == .alertFirstButtonReturn){
            resetFlags()
            self.view.window?.close()
        }
    }
  
    
    @IBAction func BtnCancelPressed(_ sender: Any) {
        //wait for user action
        isPaused = true
        
        let msg = "Are you sure you wish to stop processing files?"
        let alert: NSAlert = NSAlert()
        alert.messageText = "Processing Files"
        alert.informativeText = msg
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = NSAlert.Style.warning
        alert.icon = NSImage.imgWarning
        
        let res = alert.runModal()
        if(res == .alertFirstButtonReturn){
            //stop and close dialog
            isPaused = false
            hasCancelled = true
            
            self.view.window?.close()
        }else {
            //resume progress
            continuation?.resume()
            continuation = nil
            isPaused = false
        }
    }
}
