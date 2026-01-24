//
//  SettingsView.swift
//  jigsaw rpt
//
//  Created by Talha

import Cocoa

class SchemaSettingsView: NSView {
    
 
    @IBOutlet var contentView: NSView!
 
    @IBOutlet weak var txtDelimiter: NSTextField!
    @IBOutlet weak var txtSkipRows: NSTextField!
    @IBOutlet weak var txtFilenameRegrex: NSTextField!
    @IBOutlet weak var txtTransactionDate: NSTextField!
    @IBOutlet weak var txtReleaseTitle: NSTextField!
    @IBOutlet weak var txtTrackLabel: NSTextField!
    @IBOutlet weak var txtTerritory: NSTextField!
    @IBOutlet weak var txtTrackArtist: NSTextField!
    @IBOutlet weak var txtTrackTitle: NSTextField!
    @IBOutlet weak var txtISRC: NSTextField!
    
    @IBOutlet weak var txtBarcode: NSTextField!
    @IBOutlet weak var txtCurrency: NSTextField!
    @IBOutlet weak var txtNetPayable: NSTextField!
    @IBOutlet weak var txtUnits: NSTextField!
    @IBOutlet weak var AppProgress: NSProgressIndicator!
    @IBOutlet weak var serviceCombo: NSComboBox!

     
    
 
    var selectedService: String?
    var schema: ReportSchema?
    
    func loadSchema(service: String) {
        selectedService = service
        
        if let dbSchema = SqliteManager.shared.loadReportSchema(service: service) {
            schema = dbSchema
        }
        
        bindToUI()
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        initializeSettings()
    }
    
    func initializeSettings(){
        loadFromNib()
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = false
        formatter.minimum = 0
        txtSkipRows.formatter = formatter
        
        serviceCombo.completes = true
        serviceCombo.isEditable = true
        serviceCombo.removeAllItems()
        serviceCombo.addItems(withObjectValues:  SqliteManager.shared.getAllServiceNames())
        
    }
    
    
    private var isInitialized = false
    private func loadFromNib() {
        //it prevents view to re-initialize
        guard !isInitialized else { return }
               isInitialized = true

       
        
        var topLevelObjects: NSArray?
        Bundle.main.loadNibNamed("SchemaSettingsView", owner: self, topLevelObjects: &topLevelObjects)
        
        if let views = topLevelObjects as? [Any],
           let loadedView = views.first(where: { $0 is NSView }) as? NSView {
            self.contentView = loadedView
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.width, .height]
            self.addSubview(contentView)
        }
    }
    
    func showProgress(shouldShow: Bool){
        if(shouldShow){
            AppProgress.isHidden = false
            AppProgress.startAnimation(self)
        }else {
            AppProgress.isHidden = true
            AppProgress.stopAnimation(self)
        }
    }
    
    
    private func bindToUI() {
        guard let schema else { return }
        
        txtDelimiter.stringValue = schema.options?.delimiter ?? ","
        txtFilenameRegrex.stringValue = schema.FileNameRegex ?? ""
        txtSkipRows.stringValue = "\(Int(schema.options?.skipRows ?? 0))"
        txtTransactionDate.stringValue = schema.TransactionDate
        txtTrackLabel.stringValue = schema.TrackLabel
        txtReleaseTitle.stringValue = schema.ReleaseTitle
        txtTrackArtist.stringValue = schema.TrackArtist
        txtTrackTitle.stringValue = schema.TrackTitle
        txtISRC.stringValue = schema.ISRC
        txtBarcode.stringValue = schema.Barcode
        txtTerritory.stringValue = schema.Territory
        txtCurrency.stringValue = schema.Currency
        txtNetPayable.stringValue = schema.NetPayable
        txtUnits.stringValue = schema.Units
    }
    
    private func readFromUI() {
        
        let skipRows = txtSkipRows.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        schema?.options?.delimiter = txtDelimiter.stringValue
        schema?.FileNameRegex = txtFilenameRegrex.stringValue
        schema?.options?.skipRows = Int(skipRows) ?? 0
        schema?.TransactionDate = txtTransactionDate.stringValue
        schema?.TrackLabel = txtTrackLabel.stringValue
        schema?.ReleaseTitle = txtReleaseTitle.stringValue
        schema?.TrackArtist = txtTrackArtist.stringValue
        schema?.TrackTitle = txtTrackTitle.stringValue
        schema?.ISRC = txtISRC.stringValue
        schema?.Barcode = txtBarcode.stringValue
        schema?.Territory = txtTerritory.stringValue
        schema?.Currency = txtCurrency.stringValue
        schema?.NetPayable = txtNetPayable.stringValue
        schema?.Units = txtUnits.stringValue
        
    }
    
    @IBAction func serviceChanged(_ sender: NSComboBox) {
        let service = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !service.isEmpty else { return }

            if sender.indexOfItem(withObjectValue: service) == NSNotFound {
                sender.addItem(withObjectValue: service)
            }

            if let schema = SqliteManager.shared.loadReportSchema(service: service) {
                loadSchema(service: service)
            } else {
                let emptySchema = ReportSchema(
                    TransactionDate: "",
                    TrackLabel: "",
                    ReleaseTitle: "",
                    TrackArtist: "",
                    TrackTitle: "",
                    ISRC: "",
                    Barcode: "",
                    Territory: "",
                    Currency: "",
                    NetPayable: "",
                    Units: "",
                    SaleDate: nil,
                    Source: nil,
                    ReleaseArtist: nil,
                    ReleaseLabel: nil,
                    FileNameRegex: nil,
                    options: Options(skipRows: 0, delimiter: "")
                )
                
                SqliteManager.shared.saveReportSchema(service: service, schema: emptySchema)
                loadSchema(service: service)
            }
    }

    @IBAction func saveClicked(_ sender: NSButton) {
        
        if(!checkIfSettingsAreValid()){
            return
        }
        
        guard let service = selectedService else { return }
        readFromUI()
        if let schema {
            SqliteManager.shared.saveReportSchema(service: service, schema: schema)
            showMsg("Success", "Schema Saved Successfully.")
        }
    }
    
    @IBAction func resetClicked(_ sender: NSButton) {
        guard
            let service = selectedService,
            let defaultSchema = Services.shared.schemas[service]
        else { return }
        
        schema = defaultSchema
        bindToUI()
        SqliteManager.shared.saveReportSchema(service: service, schema: defaultSchema)
    }
    func checkIfSettingsAreValid() -> Bool {
        
        if(serviceCombo.stringValue.isEmpty){
            showMsg("Invalid service", "Please enter a valid service name.")
            serviceCombo.becomeFirstResponder()
            return false
        }
        
        
        if(txtDelimiter.stringValue.isEmpty){
            showMsg("Invalid delimiter", "Please enter a valid delimiter.")
            txtDelimiter.becomeFirstResponder()
            return false
        }
        
        let skipRows = txtSkipRows.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if skipRows.isEmpty {
            txtSkipRows.stringValue = "0"
        } else if Int(skipRows) == nil || Int(skipRows)! < 0 {
            showMsg("Invalid Skip Rows", "Please enter a valid skip rows value.")
            txtSkipRows.becomeFirstResponder()
            return false
        }
        
        if(txtTransactionDate.stringValue.isEmpty){
            showMsg("Invalid Transaction Date", "Please enter transaction date.")
            txtTransactionDate.becomeFirstResponder()
            return false
        }
        
        if(txtCurrency.stringValue.isEmpty){
            showMsg("Invalid currency", "Please enter a valid currency.")
            txtCurrency.becomeFirstResponder()
            return false
        }
        
      
        
        if(txtNetPayable.stringValue.isEmpty){
            showMsg("Invalid Net Payable", "Please enter a valid net payable.")
            return false
        }
        
     
        return true
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
    
}

 
