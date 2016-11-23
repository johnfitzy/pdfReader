//
//  AppDelegate.swift
//  Annotate
//
//  Created by Matt Barnes and John Fitzgerald on 19/09/16.
//  Copyright © 2016 Matt Barnes and John Fitzgerald. All rights reserved.
//

import Cocoa
import Quartz
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// outlet for the intro panel
    @IBOutlet weak var IntroPanel: NSPanel!
    /// <#Description#>
    @IBOutlet weak var AnnotateImage :NSImageView!
    /// outlet for the main window
    @IBOutlet weak var window: NSWindow!
    /// outlet for the pdf view
    @IBOutlet weak var pdfview : PDFView!
    /// outlet for the dropdown list of bookmarks
    @IBOutlet weak var putValuesInDropDown: NSPopUpButton!
    /// outlet for the about view
    @IBOutlet weak var AboutImage: NSImageView!
    /// outlet for the search/find window
    @IBOutlet weak var findWindow: NSWindow!
    /// outlet for the search box
    @IBOutlet weak var findSearch: NSSearchField!
    /// outlet to display the number of words fount
    @IBOutlet weak var numberFound: NSTextField!
    /// outlet for the text notes
    @IBOutlet weak var getNotes: NSTextField!
    /// outlet for the open recent menu item
    @IBOutlet weak var fileOpenRecent: NSMenu!
    /// outlet for the jump to NSTextField
    @IBOutlet weak var jumpPage : NSTextField!
    /// outlet for the about window
    @IBOutlet weak var aboutPanel: NSWindow!
    
    
    var oldPage: String
    var current : Int = -1
    var recentUrlslist : [NSURL] = []
    var openDocs : [NSURL] = []
    var currentDoc : PDFDocument!
    var notes = [NSURL : [String : String]]()
    // dictonary for bookmarked page
    var bookmarks = [NSURL: [String]]()
    // used in the
    var curPDF: PDFDocument? = nil
    var pageUpdateRunning: Bool = false
    var stopping: Bool = false

    
    
    /**
     Opens the find window
     
     - parameter sender: Find button
     */
    @IBAction func openFind(sender: AnyObject){
        findWindow.makeKeyAndOrderFront(nil)
    }
    
    
    /**
     Searchs the pdf document for the given string
     
     - parameter sender: Find NSSearchField
     */
    @IBAction func find(sender: AnyObject) {
        let str = findSearch.stringValue
        let selections = currentDoc.findString(str, withOptions: 1)
        if str != ""{
            pdfview.setHighlightedSelections(selections)
            numberFound.stringValue = String(selections.count)
        if selections.count > 0{
                pdfview.goToSelection(selections[0] as! PDFSelection)
            }
        }
        else{ numberFound.stringValue = "0"
            pdfview.setHighlightedSelections(nil)
        }
    }
    
    
    /**
     Sets old page to 1 on instantiation
     */
    override init() {
        oldPage = "1"
        
    }
    
    /**
     Action method to open a file
     
     - parameter sender: Open new file or command O
     */
    @IBAction func browseFile(sender: AnyObject){
        /// this stops the setPageNum method from running while the new pdf is opened
        stopping = true
        
        let dialog = NSOpenPanel();
        
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["pdf"];

        if (dialog.runModal() == NSModalResponseOK){
            let result = dialog.URL
            let mydoc = PDFDocument(URL: result)
            pdfview.setDocument(mydoc)
            pdfview.setAutoScales(true)
            pdfview.allowsDragging()
            currentDoc = mydoc
            curPDF = mydoc
            startPageUpdate()
            stopping = false
            recentUrlslist.append(result!)
            openDocs.append(result!)
            current += 1
            setBookmarksWhenOpenFile()
            clearNotes()
            reloadNotes()
            IntroPanel.close()
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    /**
     Action method to jump to a given page
     
     - parameter sender: Go button
     */
    @IBAction func jumpTo(sender:AnyObject){
        pdfview.goToPage(currentDoc.pageAtIndex(jumpPage.integerValue-1))
        clearNotes()
        reloadNotes()
    }
    
    
    /**
     Traverses to the next open document in the set
     
     - parameter sender: Next Document button
     */
    @IBAction func nextDoc(sender:AnyObject){
        if recentUrlslist.count > 1 && current != recentUrlslist.count - 1{
            let nextDocIndex: Int = (current + 1) % recentUrlslist.count
            current = nextDocIndex
            let url = recentUrlslist[nextDocIndex]
            let mydoc = PDFDocument(URL: url)
            pdfview.setDocument(mydoc)
            currentDoc = mydoc
            curPDF = mydoc
            stopping = false
            setBookmarksWhenOpenFile()
            clearNotes()
            reloadNotes()
            
        }
    }
    
    
    /**
     Traverses to the previous open document
     
     - parameter sender: Previous Document button
     */
    @IBAction func prevDoc(sender:AnyObject){
        if recentUrlslist.count > 1 && current != 0{
            let nextDocIndex: Int = (current + 1) % recentUrlslist.count
            current = nextDocIndex
            let url = recentUrlslist[nextDocIndex]
            let mydoc = PDFDocument(URL: url)
            pdfview.setDocument(mydoc)
            currentDoc = mydoc
            curPDF = mydoc
            stopping = false
            setBookmarksWhenOpenFile()
            clearNotes()
            reloadNotes()
        }
   }
    

    /**
     Open the about viel
     
     - parameter sender: The About button
     */
    @IBAction func about(sender:AnyObject){
        AboutImage.image = NSImage(named: "AppIcon")
        aboutPanel.makeKeyAndOrderFront(nil)
    
    }
   
    /**
     Saves the bookmard to the bookmarks dict
     
     - parameter sender: Save button
     */
    @IBAction func bookmark(sender: AnyObject) {
        if var array = bookmarks[(curPDF?.documentURL())!] {
            if !array.contains("\((curPDF?.indexForPage(pdfview.currentPage()))! + 1)") {
                array.append("\((curPDF?.indexForPage(pdfview.currentPage()))! + 1)")
                bookmarks.updateValue(array, forKey: (curPDF?.documentURL())!)
                putValuesInDropDown.addItemsWithTitles(array)
            }
        }else{
            bookmarks.updateValue(["\((curPDF?.indexForPage(pdfview.currentPage()))! + 1)"], forKey: (curPDF?.documentURL())!)
            putValuesInDropDown.addItemsWithTitles(["\((curPDF?.indexForPage(pdfview.currentPage()))! + 1)"])
        }

    }
    
    /**
     Shows the given page according to the page number in bookmard
     
     - parameter sender: Drop down box button
     */
    @IBAction func goToBookmark(sender: AnyObject) {
        pdfview.goToPage(currentDoc.pageAtIndex(Int(sender.titleOfSelectedItem!!)!-1))
    }
    
    /**
     Skips to the next page in the pdf
     
     - parameter sender: Next Page button
     */
    @IBAction func nextPage(sender:AnyObject){
        if pdfview.canGoToNextPage(){
        pdfview.goToNextPage(sender)
            clearNotes()
        }
    }
    
    
    /**
     Goes back one page in the current pdf
     
     - parameter sender: Previous page button
     */
    @IBAction func previousPage(sender:AnyObject){
        if pdfview.canGoToPreviousPage(){
            pdfview.goToPreviousPage(sender)
            clearNotes()
        }
    }
    
    /**
     Zooms in on the pdf
     
     - parameter sender: Zoom + button
     */
    @IBAction func zoomIn(sender:AnyObject){
        if pdfview.canZoomIn(){
            pdfview.zoomIn(sender)
        }
    }
    
    
    
    /**
     Zooms out of the current pdf
     
     - parameter sender: Zoom - button
     */
    @IBAction func zoomOut(sender:AnyObject){
        if pdfview.canZoomOut(){
            pdfview.zoomOut(sender)
        }
    }
    
    
    
    /**
     Clears the notes for the given pdf doc page
     
     - parameter sender: Clear button
     */
    @IBAction func deleteNotes(sender: AnyObject) {
        getNotes.stringValue = ""
        getNotes.placeholderString = "Enter some notes here \nfor page \(oldPage)"
        if (notes[(curPDF?.documentURL())!] != nil) {
            let curPage: String = String((curPDF?.indexForPage(pdfview.currentPage()))! + 1)
            var dict = notes[(curPDF?.documentURL())!]
            if dict![curPage] != nil {
                dict!.removeValueForKey(curPage)
                if dict![curPage] == nil {
                    notes.removeValueForKey((curPDF?.documentURL())!)
                }
            }
        }
    }
    
    /**
     Gets the note from the text field and stores it in a dictionary
     
     - parameter sender: The Save button
     */
    @IBAction func getTextNote(sender: AnyObject) {
        let input: String? = getNotes.stringValue
        let thisURL: NSURL = (curPDF?.documentURL())!
        let x: String = String((curPDF?.indexForPage(pdfview.currentPage()))! + 1)
        if var dict = notes[thisURL]{
            if var note = dict[x] {
                note = input!
                dict[x] = note
                notes.updateValue(dict, forKey: thisURL)
            }else{
                var newDixt = notes[thisURL]
                newDixt!.updateValue(input!, forKey: x)
                notes.updateValue(newDixt!, forKey: thisURL)
            }
        }else{
            let input: String? = getNotes.stringValue
            var newDict = [String: String]()
            newDict.updateValue(input!, forKey: String((curPDF?.indexForPage(pdfview.currentPage()))! + 1)
            )
            notes.updateValue(newDict, forKey: thisURL)
        }
    }
    
    
    /**
     Clears the text in the Notes textfield and puts the place holder string in it
     */
    func clearNotes(){
        getNotes.stringValue = ""
        getNotes.placeholderString = "Enter some notes here \nfor page \(oldPage)"
    }
    
    /**
     Reloads the notes for the given pdf page
     */
    func reloadNotes(){
        if (notes[(curPDF?.documentURL())!] != nil) {
            let curPage: String = String((curPDF?.indexForPage(pdfview.currentPage()))! + 1)
            let dict = notes[(curPDF?.documentURL())!]
            if dict![curPage] != nil {
                let content = dict![curPage]
                getNotes.stringValue = content!

            }
        }
    }
    
    
    
    /**
     checks to see if there is a note for the current page
     
     - returns: True if there is a note saved for the given page of the current pdf
     */
    func checkNoNoteForPage() -> Bool {
        if let dict = notes[(curPDF?.documentURL())!] {
            let curPage: String = String((curPDF?.indexForPage(pdfview.currentPage()))! + 1)
            if dict[curPage] != nil {
                return true
            }
        }
        return false
    }
    
    
    /**
      clears the drop down list when you open a new file
      if the file has prevoiusly been opened it restores
      the prevois book marks
     */
    func setBookmarksWhenOpenFile(){
        if (bookmarks[(curPDF?.documentURL())!] != nil) {
            putValuesInDropDown.removeAllItems()
             if let array = bookmarks[(curPDF?.documentURL())!] {
                putValuesInDropDown.addItemsWithTitles(array)
            }
        }else{
            putValuesInDropDown.removeAllItems()
        }
    }
    
    
    
    /**
     starts the timer object which calls setPageNum()
     */
    func startPageUpdate(){
        if pageUpdateRunning { return }
        let timer = NSTimer(timeInterval: 0.000001, target: self, selector: #selector(self.setPageNum(_:)), userInfo: nil, repeats: true)
        let loop = NSRunLoop.currentRunLoop()
        loop.addTimer(timer, forMode: NSRunLoopCommonModes)
        pageUpdateRunning = true
    }
    
    
    
    /**
     
     sets the page number at the top of the reader and in the Notes textfield
     the system timer polls this method
     
     - parameter theTimer: System timer
     */
    func setPageNum(theTimer:NSTimer){
        if !stopping {
            let url = curPDF?.documentURL()
            let title = url!.lastPathComponent
            let num: Int = currentDoc.pageCount()
            let currentPage = pdfview.currentPage()
            let currentPageIndex = curPDF?.indexForPage(currentPage)
            if(String(currentPageIndex! + 1) != oldPage && !checkNoNoteForPage()){
                oldPage = String(currentPageIndex! + 1)
                clearNotes()
            }else if (String(currentPageIndex! + 1) != oldPage && checkNoNoteForPage()){
                oldPage = String(currentPageIndex! + 1)
                reloadNotes()
            }
            window.title = title! + " (page \(currentPageIndex! + 1) of \(num))"
        }
    }
    /**
     saves the notes to the file saveNotes
     */
    func saveNotes() {
        NSKeyedArchiver.archiveRootObject(notes, toFile: "./saveNotes")
    }
    
    
    /**
     Checks to see if it is OK to open the saveNotes file
     
     - returns: Ture if file has been written to
     */
    func testOpenNotes() -> Bool{
        guard (NSKeyedUnarchiver.unarchiveObjectWithFile("./saveNotes") as? [NSURL: [String: String]]) != nil else {return false}
        return true
    }
    
    
    /**
     Opens the notes from disk
     */
    func openNotes(){
       notes = (NSKeyedUnarchiver.unarchiveObjectWithFile("./saveNotes") as? [NSURL: [String: String]])!
    }
    
    
    /**
     Operation starts here, called when application launches
     
     - parameter aNotification: aNotification
     */
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if testOpenNotes() {
            openNotes()
        }
       AnnotateImage.image = NSImage(named: "AppIcon")!
        
    }
    
    /**
     Called when application closes
     
     - parameter aNotification: aNotification
     */
    func applicationWillTerminate(aNotification: NSNotification) {
        saveNotes()
    }
}

