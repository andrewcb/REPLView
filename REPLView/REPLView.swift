//
//  REPLView.swift
//  REPLView
//
//  Created by acb on 17/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

/**
 A REPLView is an interface element which implements the interface for a Read-Eval-Print Loop (REPL), encapsulated within a NSView subclass.
 */
@IBDesignable
public class REPLView: NSView {
    
    // MARK: the REPL interface
    
    
    /// A possible response from the evaluator
    public enum EvalResponse {
        case output(String) // An output value to be printed
        case error(String) // An error message to be printed
    }
    
    /** The function the REPL calls when the user enters a line of text they wish to have evaluated; this function runs the evaluator process and returns either nothing (if there is no synchronous result to be printed), or a response (containing either output or an error message) */
    public var evaluator: ((String)->(EvalResponse?))?
    
    /* Functions for asynchronously printing output to the console */
    /** Print a response asynchronously. */
    public func println(response: EvalResponse) {
        switch(response) {
        case .output(let line): self.emit(line: line, withColor: self.outputColor)
        case .error(let line): self.emit(line: line, withColor: self.errorColor)
        }
    }
    /** Print an output string asynchronously. */
    public func printOutputLn(_ line: String) { self.println(response: .output(line)) }
    /** Print an error string asynchronously. */
    public func printErrorLn(_ line: String) { self.println(response: .error(line)) }

    // MARK: UI configuration
    
    @IBInspectable
    public var backgroundColor: NSColor {
        get {
            return self.scrollView.backgroundColor
        }
        set(v) {
            self.layer?.backgroundColor = v.cgColor
            self.scrollView.backgroundColor = v
            self.scrollbackTextView.backgroundColor = v
            self.inputTextView.backgroundColor = v
        }
    }
    /** The colour for REPL non-error result output */
    @IBInspectable
    public var outputColor: NSColor = .darkGray {
        didSet {
            self.inputTextView.textColor = self.outputColor
            self.inputTextView.insertionPointColor = self.outputColor
        }
    }
    /** The colour for REPL error output */
    @IBInspectable
    public var errorColor: NSColor = .red
    /** The colour for echoes of the user's input, if enabled */
    @IBInspectable
    public var echoColor: NSColor = .lightGray

    /** A function for formatting a typed line to an echo */
    public var echoFormatter: ((String)->(String))? = { ">>> \($0)" }
    
    /** The maximum number of history lines to save*/
    @IBInspectable
    public var maxHistoryLines: Int = 20
    
    class KeyInterceptingTextView: NSTextView {
        var submitText: ((String)->())?
        var handleSpecialKey: ((SpecialKey)->())?
        
        enum SpecialKey: UInt16 {
            case up = 126
            case down = 125
        }
        
        override func keyUp(with event: NSEvent) {
            if event.keyCode == 36 /* Enter */ && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.submitText?(self.string.trimmingCharacters(in: CharacterSet(charactersIn: "\n")))
                self.string = ""
            } else if let specialKey = SpecialKey(rawValue: event.keyCode) {
                self.handleSpecialKey?(specialKey)
            } else {
                super.keyUp(with: event)
            }
        }
    }
    
    var scrollView: NSScrollView = NSScrollView()
    var scrollbackTextView: NSTextView = NSTextView()
    var inputTextView: KeyInterceptingTextView = KeyInterceptingTextView()
    
    //MARK: history handling
    var history: [String] = []
    var currentlyEditedLine: String? = nil // the line being entered at the moment, which the user can return to
    // where the user is currently in navigating the history (or not)
    enum HistoryNavigationState: Equatable {
        case currentLine
        case historyItem(Int)
    }
    var historyNavigationState = HistoryNavigationState.currentLine {
        didSet(prev) {
            guard self.historyNavigationState != prev else { return }
            if prev == .currentLine { self.currentlyEditedLine = self.inputTextView.string }
            switch(self.historyNavigationState) {
            case .currentLine: self.inputTextView.string = self.currentlyEditedLine ?? ""
            case .historyItem(let index): self.inputTextView.string = self.history[index]
            }
            self.needsLayout = true
        }
    }
    func addToHistory(line: String) {
        if self.history.count >= self.maxHistoryLines {
            self.history.removeFirst(self.history.count - (self.maxHistoryLines - 1))
        }
        self.history.append(line)
    }
    
    //MARK: -----
    
    @IBInspectable
    var font: NSFont? {
        get {
            return scrollbackTextView.font
        }
        set(v) {
            self.scrollbackTextView.font = v
            self.inputTextView.font = v
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        self.configureSubviews()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.configureSubviews()
    }
    
    private func emit(line: String, withColor color: NSColor) {
        let visibleRect = self.scrollView.documentVisibleRect
        let docHeight = self.scrollView.documentView!.frame.size.height
        let distanceFromBottom = docHeight - (visibleRect.origin.y+visibleRect.size.height)
        
        guard let textStorage = self.scrollbackTextView.textStorage else { fatalError("No text storage?!") }
        if !self.scrollbackTextView.string.isEmpty {
            textStorage.append(NSAttributedString(string: "\n"))
        }
        let attStr = NSMutableAttributedString(string: line, attributes: [NSAttributedStringKey.foregroundColor : color,
             NSAttributedStringKey.font: self.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)])
        textStorage.append(attStr)
        if distanceFromBottom < 1.0 {
            self.scrollView.documentView?.scrollToEndOfDocument(nil)
        }
        self.needsLayout = true
    }
    
    private func configureSubviews() {
        self.wantsLayer = true
        self.addSubview(self.scrollView)
        self.scrollView.documentView = self.scrollbackTextView
        self.scrollView.borderType = .noBorder
        self.scrollView.hasVerticalScroller = true
        self.scrollView.autohidesScrollers = true
        self.addSubview(self.inputTextView)
        self.inputTextView.string = ""
        self.inputTextView.delegate = self
        
        self.inputTextView.submitText = self.submitText
        self.inputTextView.handleSpecialKey = self.handleInputSpecialKey
        
        self.scrollbackTextView.isEditable = false
        
        self.needsLayout = true
        
        self.scrollbackTextView.wantsLayer = true
        self.scrollbackTextView.layer?.backgroundColor = NSColor.green.cgColor
        self.inputTextView.wantsLayer = true
        self.inputTextView.layer?.backgroundColor = NSColor.yellow.cgColor
        
    }
    
    override public func layout() {
        super.layout()
        // prime widths of text elements to ensure correct line breaking
        self.inputTextView.frame.size = CGSize(width: self.frame.size.width, height: 50.0)
        self.scrollbackTextView.frame.size = CGSize(width: self.frame.size.width, height: 50.0)
        guard let inLayoutManager = inputTextView.layoutManager, let inTextCtr = inputTextView.textContainer else { fatalError(":-P")}
        inLayoutManager.ensureLayout(for: inTextCtr)
        let inTextSize = inLayoutManager.usedRect(for: inTextCtr)
        self.inputTextView.frame = NSRect(x: 0, y: 0, width: self.frame.width, height: ceil(inTextSize.height))
        
        if let layoutManager = self.scrollbackTextView.layoutManager, let textContainer = self.scrollbackTextView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let textSize = layoutManager.usedRect(for: textContainer)
            self.scrollView.frame = NSRect(x: 0.0, y: self.inputTextView.frame.height, width: self.frame.width, height: min(self.frame.height - self.inputTextView.frame.height, textSize.height))
            self.scrollbackTextView.frame = NSRect(x: 0.0, y: 0.0, width: self.scrollView.frame.width, height: ceil(textSize.height))
        }
    }
    
    func submitText( _ line: String) {
        if let echo = self.echoFormatter?(line) {
            self.emit(line: echo, withColor: self.echoColor)
        }
        if let output = self.evaluator?(line) {
            self.println(response: output)
        }
        self.addToHistory(line: line)
        self.historyNavigationState = .currentLine

    }
    
    func handleInputSpecialKey(_ key: KeyInterceptingTextView.SpecialKey) {
        switch(key) {
        case .up:
            if !self.history.isEmpty {
                switch(self.historyNavigationState) {
                case .currentLine:
                    self.historyNavigationState = .historyItem(self.history.count - 1)
                case .historyItem(let item):
                    if item > 0 {
                        self.historyNavigationState = .historyItem(item - 1)
                    }
                }
            }
        case .down:
            if case let .historyItem(item) = self.historyNavigationState {
                self.historyNavigationState = (item < self.history.count - 1) ? .historyItem(item+1) : .currentLine
            }
        }
    }
}

extension REPLView: NSTextViewDelegate {
    public func textDidChange(_ obj: Notification) {
        self.needsLayout = true
    }
}
