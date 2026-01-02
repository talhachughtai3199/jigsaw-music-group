//
//  ReportViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 20/05/25.
//

import Cocoa

class ReportViewController: NSViewController {

    @IBOutlet weak var ChkAssignSchemas: NSButton!
    
    @IBOutlet weak var TxtFolderPath: NSTextField!
    
    @IBOutlet weak var BtnProcessFolder: NSButton!
    
    @IBOutlet weak var TabAssignNotAssign: NSTabView!
    
    @IBOutlet weak var BtnInfo: HandCursorButton!
    
    @IBOutlet weak var BtnUSDInfo: HandCursorButton!
    
    @IBOutlet weak var BtnEURInfo: HandCursorButton!
    
    @IBOutlet weak var BtnAdminFeeInfo: HandCursorButton!
    
    @IBOutlet weak var BtnAddFileManually: HandCursorButton!
    
    @IBOutlet weak var TxtUSDConversion:NSTextField!
    
    @IBOutlet weak var TxtEurConversion:NSTextField!
    
    @IBOutlet weak var TxtAdminFee:NSTextField!
    
 
    let filesManager = FilesManager.shared
    let scanManager = ScanDirectoryFiles.shared
    let config = Configuration.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initializeSettings()
    }
    
    func initializeSettings(){
        config.createReportVC = self
        TabAssignNotAssign.delegate = self
        updateProcessBtnState(shouldEnable: false)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = true
        formatter.minimum = 0
        formatter.isPartialStringValidationEnabled = true


        TxtUSDConversion.formatter = formatter
        TxtEurConversion.formatter = formatter
        TxtAdminFee.formatter = formatter
        
        
    }
    
    func resetUI() {
        TxtFolderPath.stringValue = ""
        updateProcessBtnState(shouldEnable: false)
        ChkAssignSchemas.state = .on
        refreshListData()
    }
    
    func updateProcessBtnState(shouldEnable: Bool){
        BtnProcessFolder.isEnabled = shouldEnable
    }
     
    @IBAction func ChkAssignSchemasPressed(_ sender: Any) {
        
    }
    
    @IBAction func BtnRescanPressed(_ sender: Any) {
        let path = TxtFolderPath.stringValue
        if(ScanDirectoryFiles.shared.isValidDirectory(path)){
            //start scanning
            let dirToScan = URL(fileURLWithPath: path)
            if(filesManager.startScan(directoryPath: dirToScan.path)){
                if let files = filesManager.scannedFiles(){
                    //update UI
                    refreshListData()
                }
            }
        }else {
            let msg = "Please select a valid folder to add files."
            let alert: NSAlert = NSAlert()
            alert.messageText = "Invalid folder"
            alert.informativeText = msg
            alert.addButton(withTitle: "Ok")
            alert.alertStyle = NSAlert.Style.warning
            alert.icon = NSImage.imgWarning
            
            let res = alert.runModal()
            if(res == .alertFirstButtonReturn){
                
            }
        }
    }
    
    @IBAction func BtnSelectFolderPressed(_ sender: Any) {
        let dlg = NSOpenPanel()
        
        dlg.title = "Select a folder"
        dlg.showsResizeIndicator = true
        dlg.showsHiddenFiles = false
        dlg.canChooseFiles = false
        dlg.canChooseDirectories = true
        dlg.allowsMultipleSelection = false
        
        if(dlg.runModal() == .OK){
            if let selectedURL = dlg.url {
                let folderPath = selectedURL.path
                Logger.log("Selected folder path: \(folderPath)")
                TxtFolderPath.stringValue = folderPath
                
                //start scanning
                if(filesManager.startScan(directoryPath: selectedURL.path)){
                    //select unassigned files tab if there are no files at assigned tab
                    selectAppropriateTab()
                    
                    //update lists and UI
                    refreshListData()
                }
            }
        }
    }
    
    func selectAppropriateTab(){
        Logger.log("AssignedFiles", filesManager.assignedFilesCount())
        Logger.log("UnassignedFiles", filesManager.unAssignedFilesCount())
        
        if(filesManager.assignedFilesCount() == 0
           && filesManager.unAssignedFilesCount() == 0){
            TabAssignNotAssign.selectTabViewItem(at: 0)
        }else  if(filesManager.assignedFilesCount() == 0
                  && filesManager.unAssignedFilesCount() > 0){
            TabAssignNotAssign.selectTabViewItem(at: 1)
        }else {
            TabAssignNotAssign.selectTabViewItem(at: 0)
        }
    }
    
    func refreshListData(){
        //update UI
        let selectedTab = getSelectedTab()
        if(selectedTab == .assignedFiles){
            config.assignedFilesView?.refreshData()
        }else if(selectedTab == .unassignedFiles){
            config.unAssignedFilesView?.refreshData()
        }
    }
    
    func getSelectedTab() -> TabItems {
        var tabItems = TabItems.assignedFiles
        if let selectedItem = TabAssignNotAssign.selectedTabViewItem{
            if(TabAssignNotAssign.indexOfTabViewItem(selectedItem) == 1) {
                tabItems = TabItems.unassignedFiles
            }
        }
        return tabItems
    }
    
    @IBAction func AddFileManuallyPressed(_ sender: Any) {
        let dlg = NSOpenPanel()
        dlg.allowedContentTypes = ScanDirectoryFiles.shared.getAllowedFileTypes()
        
        dlg.title = "Select a file"
        dlg.showsResizeIndicator = true
        dlg.showsHiddenFiles = false
        dlg.canChooseFiles = true
        dlg.canChooseDirectories = false
        dlg.allowsMultipleSelection = true
        
        if(dlg.runModal() == .OK){
            var hasAddFile = false
            for file in dlg.urls {
                if let selectedURL = dlg.url {
                    let filePath = selectedURL.path
                    Logger.log("Selected file path: \(filePath)")
                    scanManager.addFileManually(filePath: selectedURL)
                    hasAddFile = true
                }
            }
            
            if(hasAddFile){
                refreshListData()
            }
        }
    }
    
    func showMsg(_ title: String, _ msg: String){
        let alert: NSAlert = NSAlert()
        alert.messageText = title
        alert.informativeText = msg
        alert.addButton(withTitle: "Ok")
        alert.alertStyle = NSAlert.Style.warning
        alert.icon = NSImage.imgWarning
        _ = alert.runModal()
    }
    
    func showMessageIfNoSchemaAssignedToFile() -> Bool {
        var res = false
        
        if let safeSelectedFiles = filesManager.selectedFiles() {
            for item in safeSelectedFiles{
                if(item.schema == nil){
                    res = true
                    break
                }
            }
        }
        return res
    }
    
    
    @IBAction func BtnProcessFolderPressed(_ sender: Any) {
        
        Logger.log("Admin fee: \(TxtAdminFee.stringValue), USD: \(TxtUSDConversion.stringValue), EUR: \(TxtEurConversion.stringValue)")
        //check that all files have schema else show message
        if(showMessageIfNoSchemaAssignedToFile()) {
            showMsg("Schema not found", "One or more selected files do not have schema assigned. Please select schema for unassigned files.")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save CSV File"
        savePanel.allowedFileTypes = ["csv"]
        savePanel.nameFieldStringValue = "data.csv"
        
        savePanel.begin { result in
            if result == .OK, let outputFilePath = savePanel.url {
                do {
                    //remove if existing file
                    if FileManager.default.fileExists(atPath: outputFilePath.path) {
                        try FileManager.default.removeItem(atPath:  outputFilePath.path)
                    }
                    
                    //show progress dialog
                    let mainStoryBoard = NSStoryboard(name: "Main", bundle: nil)
                    if let winController = mainStoryBoard.instantiateController(withIdentifier: "ProcessingFilesWinIdentifier") as? ProcessingFilesWindowController{
                        
                        let usd = Double(self.TxtUSDConversion.stringValue) ?? 0.0
                        let eur = Double(self.TxtEurConversion.stringValue) ?? 0.0
                        let adminFee = Double(self.TxtAdminFee.stringValue) ?? 0.0
                        
                        self.filesManager.updateConversionValues(usd: usd, eur: eur, adminFee: adminFee)
                        //update selected files for processing
                        if let vc = winController.contentViewController as? ProcessingFilesViewController{
                            Logger.log("selectedFilesCount: \(self.filesManager.selectedFiles()!.count)") 
                            vc.filesToProcess = self.filesManager.selectedFiles()
                            vc.outputFilePath = outputFilePath
                        }
                        
                        //show dialog as sheet
                        if let dialogWindow = winController.window{
                            self.view.window?.beginSheet(dialogWindow)
                        }
                    }
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
    
    @IBAction func BtnInfoPressed(_ sender: Any) {
        let tooltipVC = TooltipViewController()
        tooltipVC.message = "The program will try to auto-assign schemas based on pre-defined rules. This should work most of the time."
        let popover = NSPopover()
        popover.contentViewController = tooltipVC
        popover.behavior = .transient
        popover.show(relativeTo: BtnInfo.bounds, of: BtnInfo, preferredEdge: .maxY)

    }
    
    @IBAction func BtnUSDInfoPressed(_ sender: Any) {
        let tooltipVC = TooltipViewController()
        tooltipVC.message = "Insert exchange rate for USD in decimal format."
        let popover = NSPopover()
        popover.contentViewController = tooltipVC
        popover.behavior = .transient
        popover.show(relativeTo: BtnUSDInfo.bounds, of: BtnUSDInfo, preferredEdge: .maxY)

    }
    @IBAction func BtnEURInfoPressed(_ sender: Any) {
        let tooltipVC = TooltipViewController()
        tooltipVC.message = "Insert exchange rate for EUR in decimal format."
        let popover = NSPopover()
        popover.contentViewController = tooltipVC
        popover.behavior = .transient
        popover.show(relativeTo: BtnEURInfo.bounds, of: BtnEURInfo, preferredEdge: .maxY)

    }
    @IBAction func BtnAdminFeeInfoPressed(_ sender: Any) {
        let tooltipVC = TooltipViewController()
        tooltipVC.message = "Insert the admin fee as a percentage."
        let popover = NSPopover()
        popover.contentViewController = tooltipVC
        popover.behavior = .transient
        popover.show(relativeTo: BtnAdminFeeInfo.bounds, of: BtnAdminFeeInfo, preferredEdge: .maxY)

    }
    
    //Insert exchange rate for USD in decimal format
}

extension ReportViewController : NSTabViewDelegate{
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        
        Logger.log("tab view changed")
    }
}

enum TabItems{
    case assignedFiles
    case unassignedFiles
}
