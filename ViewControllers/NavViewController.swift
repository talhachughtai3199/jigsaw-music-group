//
//  NavViewController.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 21/05/25.
//

import Cocoa

class NavViewController: NSViewController {

    let config = Configuration.shared
    let reportManager = ReportManager.shared
    
 
    @IBOutlet weak var BtnHome: HandCursorButton!
    @IBOutlet weak var BtnSettings: NSButton!
    
    @IBOutlet weak var NavCollectionView: NSCollectionView!
    @IBOutlet weak var NavBarScrollView: NSScrollView!
    
    var navItems = [NavItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initializeSettings()
    }
    
    func initializeSettings(){
        config.navVC = self
        NavCollectionView.delegate = self
        
        BtnHome.toolTip = "Home"
        BtnSettings.toolTip = "Settings"
        
        configureCollectionView()
        refreshNavItems()
    }
    
    func refreshNavItems(){
        let reports = reportManager.reports
         
        if(!navItems.isEmpty) {
            navItems.removeAll()
        }
        
        if(!reports.isEmpty) {
            for report in reports {
                navItems.append(NavItem(Id: report.Id!, Title: report.ReportTitle ?? "Untitled", ReportDate: report.Date))
            }
        }
        
        NavCollectionView.reloadData()
    }
    
    func configureCollectionView(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 00.0
        flowLayout.minimumLineSpacing = 5.0
        flowLayout.itemSize = NSSize(width: 180, height: 60)
        flowLayout.sectionInset = NSEdgeInsets(top: 5.0, left: 00.0, bottom: 0.0, right: 00.0)
        NavCollectionView.collectionViewLayout = flowLayout

        //clearing background color of collection view
        NavBarScrollView.backgroundColor = NSColor.clear
        NavBarScrollView.layer?.borderWidth = 0.5
        NavBarScrollView.layer?.cornerRadius = 8
        NavCollectionView.backgroundColors = [NSColor.clear]
        NavCollectionView.isSelectable = true
        NavCollectionView.allowsMultipleSelection = false
    }
    
    @IBAction func BtnPlusPressed(_ sender: Any) {
        config.mainTab?.SwitchTab(screen: .CreateNewReport)
    }
    
    @IBAction func BtnMinusPressed(_ sender: Any) {
        let msg = "Are you sure you would like to remove selected report?"
        let alert: NSAlert = NSAlert()
        alert.messageText = AppInfo.shared.AppName
        alert.informativeText = msg
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = NSAlert.Style.warning
        alert.icon = NSImage.imgWarning
        
        let res = alert.runModal()
        if(res == .alertFirstButtonReturn){
            
        }
    }
    
    func clearSelection(){
        //remove selection if any
        resetSelection() 
        NavCollectionView.deselectAll(self)
    }
    
    @IBAction func BtnHomePressed(_ sender: Any) {
        clearSelection()
        
        //move to welcome screen
        config.mainTab?.SwitchTab(screen: .Welcome)
    }
    
    @IBAction func BtnOptionsPressed(_ sender: Any) {
        
    }
    
    func selectDefaultItem() {
        Logger.log("selectDefaultItem", NavCollectionView.visibleItems().count)
        if(!reportManager.reports.isEmpty){
            let items = NavCollectionView.visibleItems()
            if(!items.isEmpty){
                if let firstItem = items[0] as? NavBarCollectionViewItem{
                    firstItem.updateSelection(shouldSelect: true)
                    config.summaryVC?.refreshReport(reportManager.reports[0])
                }
            }
        }
    }
}



extension NavViewController: NSCollectionViewDelegate, NSCollectionViewDataSource {
   
   func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
       var itemsCount = 0
       let collectionViewName = collectionView.accessibilityIdentifier()
       if(collectionViewName == "NavCollectionIdentifier"){
           itemsCount = self.navItems.count
       }
       return itemsCount
   }
   
   func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
       let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("NavBarCollectionViewItem"), for: indexPath)
       guard let safeItem = item as? NavBarCollectionViewItem else {return item}
       safeItem.setSourceItem(selectedItem: navItems[indexPath[1]])
       return safeItem
   }
   
   func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
       let collectionViewName = collectionView.accessibilityIdentifier()
       if(collectionViewName == "NavCollectionIdentifier"){
           if let itemIndex = indexPaths.first{
               guard let selectedItem = collectionView.item(at: itemIndex) as? NavBarCollectionViewItem else {
                   return
               }
               
               //reset selection
               resetSelection()
               
               //select current item
               selectedItem.updateSelection(shouldSelect: true)
               
               //update and show summary report
               if let indexPath = indexPaths.first{
                   let selectedIndex = indexPath.item
                   let reportDetails = reportManager.reports[selectedIndex]
                   
                   config.summaryVC?.refreshReport(reportDetails)
                   config.mainTab?.SwitchTab(screen: .SummaryReport) 
               }
               
               //reset internal collection view index to -1 otherwise 0 index item will stay selected on collection view
               NavCollectionView.selectionIndexPaths = [IndexPath(item: -1, section: 0)]
           }
       }
   }
    
    func resetSelection() {
        let items = NavCollectionView.visibleItems()
        for item in items {
            let navItem = item as! NavBarCollectionViewItem
            navItem.updateSelection(shouldSelect: false)
        }
    }
}
