//
//  PopoverViewController.swift
//  Boop
//
//  Created by Ivan on 1/27/19.
//  Copyright © 2019 OKatBest. All rights reserved.
//

import Cocoa
import SavannaKit

class PopoverViewController: NSViewController {
    
    @IBOutlet weak var overlayView: OverlayView!
    @IBOutlet weak var popoverView: PopoverView!
    @IBOutlet weak var searchField: SearchField!
    @IBOutlet weak var editorView: SyntaxTextView!
    @IBOutlet weak var statusView: StatusView!
    
    @IBOutlet weak var scriptManager: ScriptManager!
    
    @IBOutlet weak var tableView: ScriptTableView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewController: ScriptsTableViewController!
    @IBOutlet weak var appDelegate: AppDelegate!
    
    var enabled = false // Closed by default

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyHandlers()
    }
    
    func setupKeyHandlers() {
        
        var keyHandler: (_: NSEvent) -> NSEvent?
        keyHandler = {
            (_ theEvent: NSEvent) -> NSEvent? in
            
            var didSomething = false
                
            // Key codes:
            // 125 is down arrow
            // 126 is up
            // 53 is escape
            // 36 is enter
       
            if theEvent.keyCode == 53 && self.enabled { // ESCAPE
                
                // Let's dismiss the popover
                self.hide()
                
                didSomething = true
            }
            
            if theEvent.keyCode == 36 && self.enabled { // ENTER
                
                guard let script = self.tableViewController.selectedScript else {
                    return theEvent // Return event to beep
                }
                
                
                // Let's dismiss the popover
                self.hide()
                
                // Run the script afterwards in case we need to show a status
                self.scriptManager.runScript(script, into: self.editorView)
                
                
                didSomething = true
            }
            
            let window = self.view.window
            
            if window?.firstResponder is NSTextView &&
                (window?.firstResponder as! NSTextView).delegate is SearchField &&
                theEvent.keyCode == 125 { // DOWN
                
                // Why -1? I don't know, and I don't even care.
                let indexSet = IndexSet(integer: -1)
                self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
                window?.makeFirstResponder(self.tableView)
            }
            
            // Oh hey look now somehow it's 0.
            if window?.firstResponder is NSTableView &&
                self.tableView.selectedRow == 0 &&
                theEvent.keyCode == 126 { // UP
                
                window?.makeFirstResponder(self.searchField)
                // This doesn't work for some reason.
                //self.searchField.moveToEndOfLine(nil)
            }
            
            guard didSomething else {
                return theEvent
            }
            
            // Return an empty event to avoid the funk sound
            return nil
        }
        
        // Creates an object we do not own, but must keep track
        // of it so that it can be "removed" when we're done
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: keyHandler)
        
    }
    
    func show() {
        overlayView.show()
        popoverView.show()
        
        // FIXME: Use localized strings
        statusView.setStatus(.help("Select your action"))
        
        self.searchField.stringValue = ""
        self.tableHeightConstraint.constant = 0
        
        self.view.window?.makeFirstResponder(self.searchField)
        self.enabled = true
        
        appDelegate.setPopover(isOpen: true)
        
    }
    
    func hide() {
        overlayView.hide()
        popoverView.hide()
        
        statusView.setStatus(.normal)
        
        self.view.window?.makeFirstResponder(self.editorView.contentTextView)
        self.enabled = false
        self.tableHeightConstraint.animator().constant = 0
        
        tableViewController.results = []
        
        appDelegate.setPopover(isOpen: false)
    }
    
    func runScriptAgain() {
        self.scriptManager.runScriptAgain(editor: self.editorView)
    }
    
}

extension PopoverViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard (obj.object as? SearchField) == searchField else {
            return
        }
        
        let results = scriptManager.search(searchField.stringValue)
        tableViewController.results = results
        
        self.tableHeightConstraint.constant = CGFloat(47 * min(5, results.count))
    }
}
