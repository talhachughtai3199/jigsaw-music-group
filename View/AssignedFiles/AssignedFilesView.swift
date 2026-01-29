//
//  AssignedFilesView.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 22/05/25.
//

import Cocoa

class AssignedFilesView: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var CollectionViewScrollView: NSScrollView!
    @IBOutlet weak var CollectionView: NSCollectionView!
    
    var config = Configuration.shared
    var items = [FileDetails]()
    
    @IBOutlet weak var LblFilesFound: NSTextField!
    
    @IBOutlet weak var NoFilesFound: NSTextField!
    
    @IBOutlet weak var FilesCountDiv: NSBox!
    
    @IBOutlet weak var ChkSelectAllFiles: HandCursorButton!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        initializeSettings()
    }
    
    func initializeSettings(){ 
        
        config.assignedFilesView = self
        loadFromNib()
        updateCount()
        updateUI()
        configureCollectionView()
        refreshData()
    }
    
    func refreshData(){
        
        if(!items.isEmpty){
            items.removeAll()
        }
        
        for item in ScanDirectoryFiles.shared.files.filter({$0.itemType == .Assigned}){
            items.append(item)
        }
        
        CollectionView.reloadData()
        updateUI()
        updateCount()
    }
    
    func updateCount(){
        let selectedFilesCount = items.count(where: {$0.isSelected})
        let selectedFilesCountStr = items.count == 1 ? "file" : "files"
        LblFilesFound.stringValue = "\(selectedFilesCount) of \(items.count) \(selectedFilesCountStr) selected"
        
        
        if((selectedFilesCount == items.count && selectedFilesCount > 0) || selectedFilesCount > 0){
            ChkSelectAllFiles.state = .on
            config.createReportVC?.updateProcessBtnState(shouldEnable: true)
        }else if(selectedFilesCount == 0){
            ChkSelectAllFiles.state = .off
            config.createReportVC?.updateProcessBtnState(shouldEnable: false)
        }
    }
    
    func updateUI(){
        if(items.isEmpty){
            NoFilesFound.isHidden = false
            FilesCountDiv.isHidden = true
            LblFilesFound.isHidden = true
            ChkSelectAllFiles.isHidden = true
        }else {
            LblFilesFound.stringValue = "Files found: \(items.count)"
            LblFilesFound.isHidden = false
            FilesCountDiv.isHidden = false
            NoFilesFound.isHidden = true
            ChkSelectAllFiles.isHidden = false
        }
    }
     
     
    private var isInitialized = false
    private func loadFromNib() {
        //it prevents view to re-initialize
        guard !isInitialized else { return }
               isInitialized = true

        
        var topLevelObjects: NSArray?
        Bundle.main.loadNibNamed("AssignedFilesView", owner: self, topLevelObjects: &topLevelObjects)
        
        if let views = topLevelObjects as? [Any],
           let loadedView = views.first(where: { $0 is NSView }) as? NSView {
            self.contentView = loadedView
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.width, .height]
            self.addSubview(contentView)
        }
    }
 
    
    func configureCollectionView(){
        CollectionView.delegate = self
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 00.0
        flowLayout.minimumLineSpacing = 5.0
        
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = NSSize(width: 660, height: 60)
        flowLayout.sectionInset = NSEdgeInsets(top: 5.0, left: 0.0, bottom: 0.0, right: 0.0)
        CollectionView.collectionViewLayout = flowLayout

        //clearing background color of collection view
        CollectionViewScrollView.backgroundColor = NSColor.clear
        CollectionViewScrollView.layer?.borderWidth = 0.5
        CollectionViewScrollView.layer?.cornerRadius = 8
        
        CollectionView.backgroundColors = [NSColor.clear]
        CollectionView.isSelectable = true
        CollectionView.allowsMultipleSelection = false
    }
     
    
    @IBAction func ChkSelectAllFilesPressed(_ sender: Any) {
        let shouldSelected = ChkSelectAllFiles.state == .on ? true : false
        for item in items {
            item.isSelected = shouldSelected
        }
        
        CollectionView.reloadData()
        updateCount()
    }
    
}


extension AssignedFilesView: NSCollectionViewDelegate, NSCollectionViewDataSource {
   
   func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
       var itemsCount = 0
       let collectionViewName = collectionView.accessibilityIdentifier()
       if(collectionViewName == "AssignedFilesCollectionIdentifier"){
           itemsCount = self.items.count
       }
       return itemsCount
   }
   
   func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
       let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("AssignedFilesCollectionViewItem"), for: indexPath)
       guard let safeItem = item as? AssignedFilesCollectionViewItem else {return item}
       safeItem.setSourceItem(selectedItem: items[indexPath[1]])
       return safeItem
   }
   
   func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
       let collectionViewName = collectionView.accessibilityIdentifier()
       if(collectionViewName == "AssignedFilesCollectionIdentifier"){
           if let itemIndex = indexPaths.first{
               guard let selectedItem = collectionView.item(at: itemIndex) as? AssignedFilesCollectionViewItem else {
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

