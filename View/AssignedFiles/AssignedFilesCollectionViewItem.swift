//
//  AssignedFilesCollectionViewItem.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 22/05/25.
//

import Cocoa

class AssignedFilesCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var LblFileName: NSTextField!
    @IBOutlet weak var LblFilePath: NSTextField!
     
    
    @IBOutlet weak var MenuSchema: NSPopUpButton!
    
    @IBOutlet weak var BgBox: NSBox!
    
    var item: FileDetails?
    
    @IBOutlet weak var ChkSelection: HandCursorButton!
    
    @IBOutlet weak var BtnOpenFileLocation: HandCursorButton!
    
    let config = Configuration.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        updateUI()
        updateSelection(shouldSelect: false)
    }
    
    func setSourceItem(selectedItem: FileDetails){
        self.item = selectedItem
        if let safeItem = self.item{
            let dirPath = safeItem.fileDirectoryPath() ?? ""
            
            LblFileName.stringValue = safeItem.fileName ?? ""
            LblFilePath.stringValue = dirPath
            
            if let service = safeItem.serviceBeautifyName {
                MenuSchema.selectItem(at: MenuSchema.indexOfItem(withTitle: service))
            }
             
            ChkSelection.state = selectedItem.isSelected ? .on : .off
            
            LblFileName.toolTip = safeItem.fileName ?? ""
            LblFilePath.toolTip = dirPath
        }
    }
    
    func updateUI(){
        if(!self.isViewLoaded) {return}
        
        BtnOpenFileLocation.toolTip = "Show in Finder"
        
        BgBox.isTransparent = true
        BgBox.wantsLayer = true
        BgBox.layer?.cornerRadius = 6
        BgBox.layer?.borderWidth = 0
        BgBox.layer?.backgroundColor = NSColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 0.2).cgColor
        
        
        let area = NSTrackingArea.init(rect: self.view.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.view.addTrackingArea(area)
        
        //update combo box
        MenuSchema.removeAllItems()
        MenuSchema.addItems(withTitles: Services.shared.services)
    }
    
    func updateSelection(shouldSelect: Bool){
        BgBox.isHidden = shouldSelect ? false : true
    }
    
    
    @IBAction func ChkSelectionPressed(_ sender: Any) {
        Logger.log(ChkSelection.state)
        self.item?.isSelected = ChkSelection.state == .on ? true : false
        config.assignedFilesView?.updateCount()
    }
    
    @IBAction func BtnOpenFileLocationPressed(_ sender: Any) {
        if let filePath = self.item {
            Utility.showAndSelectFileInFinder(path: filePath.filePath!.relativePath)
        }
    }
    
    @IBAction func MenuSchemaChanged(_ sender: Any) {
        let services = Services.shared.services
        if(!services.isEmpty && MenuSchema.indexOfSelectedItem >= 0 && MenuSchema.indexOfSelectedItem < services.count){
            if let safeItem = item{
                let serviceName = services[MenuSchema.indexOfSelectedItem]
                safeItem.serviceBeautifyName = serviceName
                safeItem.schema = Services.shared.schemas[serviceName]
            }
        }
    }
    
}
