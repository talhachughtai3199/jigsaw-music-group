//
//  ReportSummaryViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 06/06/25.
//

import Cocoa

class SummaryViewController: NSViewController {
    
    @IBOutlet weak var LblReportTitle: NSTextField!
    @IBOutlet weak var CollectionViewScrollView: NSScrollView!
    
    @IBOutlet weak var CollectionView: NSCollectionView!
    
    @IBOutlet weak var BtnShowInFinder: HandCursorButton!
    
    @IBOutlet weak var BtnDeleteReport: HandCursorButton!
    
    
    @IBOutlet weak var TxtFilePath: NSTextField!
    
    @IBOutlet weak var TxtDate: NSTextField!
    
    
    var config = Configuration.shared
    var reportManager = ReportManager.shared
    
    var items = [SummaryDetails]()
    var reportDetails: ReportDetails?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        initializeSettings()
    }
     
  
    func initializeSettings(){
        
        config.summaryVC = self 
        
        updateUI()
        configureCollectionView()
    }
    
    func configureCollectionView(){
        CollectionView.delegate = self
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 00.0
        flowLayout.minimumLineSpacing = 5.0
        flowLayout.itemSize = NSSize(width: 418, height: 60)
        flowLayout.sectionInset = NSEdgeInsets(top: 5.0, left: 00.0, bottom: 0.0, right: 00.0)
        CollectionView.collectionViewLayout = flowLayout
        
        //clearing background color of collection view
        CollectionViewScrollView.backgroundColor = NSColor.clear
        CollectionViewScrollView.layer?.borderWidth = 0.5
        CollectionViewScrollView.layer?.cornerRadius = 8
        
        CollectionView.backgroundColors = [NSColor.clear]
        CollectionView.isSelectable = false
        CollectionView.allowsMultipleSelection = false
    }
    
    
    func updateUI(){
        if(items.isEmpty){
            LblReportTitle.stringValue = "..."
            TxtFilePath.stringValue = ""
            BtnDeleteReport.isEnabled = false
            BtnShowInFinder.isEnabled = false
        }else {
            BtnDeleteReport.isEnabled = true
            BtnShowInFinder.isEnabled = true
            TxtFilePath.isEnabled = true 
        }
    }
    
    
    func refreshReport(_ reportDetails: ReportDetails){
        self.reportDetails = reportDetails
        
        if(!items.isEmpty){
            items.removeAll()
        }
        
        LblReportTitle.stringValue = reportDetails.ReportTitle ?? ""
        TxtFilePath.stringValue = reportDetails.ReportFilePath ?? ""
        TxtDate.stringValue = Utility.formatDateToDDMMYYYY(reportDetails.Date!)
        
        //add USD
        items.append(SummaryDetails(currency: reportDetails.Currency ?? "",
                                    currencySymbol: "$",
                                    amount: reportDetails.NetPay ?? 0.0))
        
        //add GBP
        let gbpConversionRate: Double = 0.79
        items.append(SummaryDetails(currency: "GBP",
                                    currencySymbol: "£",
                                    amount: (reportDetails.NetPay ?? 0.0) * gbpConversionRate))
        
        //add EUR
        let euroConversionRate: Double = 0.92
        items.append(SummaryDetails(currency: "EUR",
                                    currencySymbol: "€",
                                    amount: (reportDetails.NetPay ?? 0.0) * euroConversionRate))
        
        
        CollectionView.reloadData()
        updateUI()
    }
    
    
    @IBAction func BtnShowInFinderPRessed(_ sender: Any) {
        if let report = reportDetails{
            
            //check if file exists
            if(!FileManager.default.fileExists(atPath: report.ReportFilePath!)){
                showMsg("Invalid file", "Couldn't find file at disk.")
                return
            }
            
            //show file
            if let filePathStr = report.ReportFilePath {
                Utility.showAndSelectFileInFinder(path: filePathStr)
            }
        }
      
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
    
    @IBAction func BtnDeleteReportPressed(_ sender: Any) {
        if let reportDetails = reportDetails{
            let msg = "Are you sure you wish to delete this report?"
            let alert: NSAlert = NSAlert()
            alert.messageText = "Delete"
            alert.informativeText = msg
            alert.addButton(withTitle: "Yes")
            alert.addButton(withTitle: "No")
            alert.alertStyle = NSAlert.Style.warning
            alert.icon = NSImage.imgWarning
            
            let res = alert.runModal()
            if(res == .alertFirstButtonReturn){ 
                config.navVC?.clearSelection()
                let result = reportManager.deleteReport(reportDetails)
                if(result){
                    config.navVC?.refreshNavItems()
                    config.mainTab?.SwitchTab(screen: .Welcome)
                }
            }
        }
    }
}

extension SummaryViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        var itemsCount = 0
        let collectionViewName = collectionView.accessibilityIdentifier()
        if(collectionViewName == "SummaryCollectionIdentifier"){
            itemsCount = self.items.count
        }
        return itemsCount
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("SummaryCollectionViewItem"), for: indexPath)
        guard let safeItem = item as? SummaryCollectionViewItem else {return item}
        safeItem.setSourceItem(selectedItem: items[indexPath[1]])
        return safeItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let collectionViewName = collectionView.accessibilityIdentifier()
        if(collectionViewName == "SummaryCollectionViewItem"){
            if let itemIndex = indexPaths.first{
                guard let selectedItem = collectionView.item(at: itemIndex) as? SummaryCollectionViewItem else {
                    return
                }
                
                //select current item
                //selectedItem.updateSelection(shouldSelect: true)
                
                //reset internal collection view index to -1 otherwise 0 index item will stay selected on collection view
                CollectionView.selectionIndexPaths = [IndexPath(item: -1, section: 0)]
            }
        }
    }
}



struct SummaryDetails{
    var currency: String?
    var currencySymbol: String?
    var amount: Double?
}
