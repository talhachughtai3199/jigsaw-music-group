//
//  SettingsView.swift
//  jigsaw rpt
//
//  Created by Gaurav Kundalwal on 26/05/25.
//

import Cocoa

class SettingsView: NSView {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var TxtFTPIPAddress: NSTextField!
    
    @IBOutlet weak var TxtFTPPort: NSTextField!
    
    @IBOutlet weak var TxtUsername: NSTextField!
    
    @IBOutlet weak var TxtPassword: NSTextField!
    
    @IBOutlet weak var AppProgress: NSProgressIndicator!
    
    @IBOutlet weak var FtpModeMenu: NSPopUpButton!
    
    @IBOutlet weak var ChkUseSecureConnection: HandCursorButton!
     
    
    let ftpManager = FTPConnectionManager.shared
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        initializeSettings()
    }
    
    func initializeSettings(){
        loadFromNib()
        
        updateUI()
    }
    
    func updateUI() {
        TxtFTPIPAddress.stringValue = ftpManager.ftpHost ?? ""
        
        if let port = ftpManager.ftpPort {
            TxtFTPPort.stringValue = String(port)
        }
        
        if let mode =  ftpManager.ftpMode {
            FtpModeMenu.selectItem(at: mode)
        }
        
        if let secureConnection =  ftpManager.useSecureFTPConnection {
            ChkUseSecureConnection.state = secureConnection == 1 ? .on : .off
        }
        
        TxtUsername.stringValue = ftpManager.ftpUsername ?? ""
        TxtPassword.stringValue = ftpManager.ftpPassword  ?? ""
        
 
        TxtFTPIPAddress.becomeFirstResponder()
        
        TxtFTPIPAddress.nextKeyView = TxtFTPPort
        TxtFTPPort.nextKeyView = FtpModeMenu
        FtpModeMenu.nextKeyView = ChkUseSecureConnection
        ChkUseSecureConnection.nextKeyView = TxtUsername
        TxtUsername.nextKeyView = TxtPassword
    }
    
   
    
    func updateFieldsFormat(){
        //number only format
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0
        formatter.maximumFractionDigits = 0
        TxtFTPPort.formatter = formatter
    }
    
    private var isInitialized = false
    private func loadFromNib() {
        //it prevents view to re-initialize
        guard !isInitialized else { return }
               isInitialized = true

       
        
        var topLevelObjects: NSArray?
        Bundle.main.loadNibNamed("SettingsView", owner: self, topLevelObjects: &topLevelObjects)
        
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
    
    func isValidIPAddress(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }

        for part in parts {
            guard let num = Int(part), num >= 0 && num <= 255 else {
                return false
            }
        }
        return true
    }
    
    func saveFTPSettings(){
        //save ftp settings
        ftpManager.ftpHost = TxtFTPIPAddress.stringValue
        ftpManager.ftpPort = Int(TxtFTPPort.stringValue)
        
        ftpManager.ftpMode = FtpModeMenu.indexOfSelectedItem
        ftpManager.useSecureFTPConnection = ChkUseSecureConnection.state == .on ? 1 : 0
        
        ftpManager.ftpUsername = TxtUsername.stringValue
        ftpManager.ftpPassword = TxtPassword.stringValue
        
        //save settings
        ftpManager.saveFTPSettings()
    }
    
    @IBAction func BtnSaveSettingsPressed(_ sender: Any) {
        
        if(!checkIfSettingsAreValid()) {return}
        saveFTPSettings()
        showMsg("Settings Saved", "FTP settings saved successfully.", isSuccessMsg: true)
    }
    
    @IBAction func BtnValidateConnectionPressed(_ sender: Any) {
        if(!checkIfSettingsAreValid()) {return}
        
        Task{await validateSettings()}
    }
    
    func validateSettings() async {
        showProgress(shouldShow: true)
        
        //validate settings
        let result = Task{
            let res = await ftpManager.validateFTPSettings(host: TxtFTPIPAddress.stringValue,
                                                           port: TxtFTPPort.stringValue,
                                                           username: TxtUsername.stringValue,
                                                           password: TxtPassword.stringValue,
                                                           mode: FtpModeMenu.indexOfSelectedItem == 0 ? "active" : "passive")
            
            try? await Task.sleep(nanoseconds: 1_000_000)
            return res
        }
        
        let res = await result.value
        if(res){
            //save settings
            saveFTPSettings()
            
            showMsg("Success", "FTP connection established successfully.", isSuccessMsg: true)
        }else {
            showMsg("Failed", "Failed to establish connection at FTP, please check your settings.")
        }
        showProgress(shouldShow: false)
    }
     
    
    func checkIfSettingsAreValid() -> Bool {
        //check if valid host
        if(TxtFTPIPAddress.stringValue.isEmpty){
            showMsg("Invalid Host", "Please enter valid host address.")
            return false
        }
        
        //check if valid port
        if(TxtFTPPort.stringValue.isEmpty){
            showMsg("Invalid Port", "Please enter a valid port.")
            return false
        }
        
        //check if valid host
        if(TxtUsername.stringValue.isEmpty){
            showMsg("Invalid Username", "Please enter a valid username.")
            return false
        }
        
        //check if valid pw
        if(TxtPassword.stringValue.isEmpty){
            showMsg("Invalid Password", "Please enter a valid password.")
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
    
    @IBAction func BtnResetPressed(_ sender: Any) {
        let msg = "Are you sure you wish to reset current FTP settings?"
        let alert: NSAlert = NSAlert()
        alert.messageText = "Reset"
        alert.informativeText = msg
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = NSAlert.Style.warning
        alert.icon = NSImage.imgWarning
        
        let res = alert.runModal()
        if(res == .alertFirstButtonReturn){
            //reset and save ftp settings
            ftpManager.ftpHost = ""
            ftpManager.ftpPort = 0
            
            ftpManager.ftpMode = 0
            ftpManager.useSecureFTPConnection = 0
            
            ftpManager.ftpUsername = ""
            ftpManager.ftpPassword = ""
            
            if let port = ftpManager.ftpPort {
                TxtFTPPort.stringValue = String(port)
            }
            
            if let mode =  ftpManager.ftpMode {
                FtpModeMenu.selectItem(at: mode)
            }
            
            if let secureConnection =  ftpManager.useSecureFTPConnection {
                ChkUseSecureConnection.state = secureConnection == 1 ? .on : .off
            }
            
            //reset UI
            TxtFTPIPAddress.stringValue = ""
            TxtFTPPort.stringValue = "21"
            FtpModeMenu.selectItem(at: 1)
            ChkUseSecureConnection.state = .on
            TxtUsername.stringValue = ""
            TxtPassword.stringValue = ""
            
            
            //save settings
            ftpManager.saveFTPSettings()
        }
    }
    
}

 
