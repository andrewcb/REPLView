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
class REPLView: NSView {
    
    
    /** The maximum number of history lines to save*/
    @IBInspectable
    var maxHistoryLines: Int = 20
    
    class TextField: NSTextField {
        var submitText: ((String)->())?
        var handleSpecialKey: ((SpecialKey)->())?
        
        enum SpecialKey: UInt16 {
            case up = 126
            case down = 125
        }
        
        override func keyUp(with event: NSEvent) {
            if event.keyCode == 36 /* Enter */ && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.submitText?(self.stringValue)
                self.stringValue = ""
            } else if let specialKey = SpecialKey(rawValue: event.keyCode) {
                self.handleSpecialKey?(specialKey)
            } else {
                super.keyUp(with: event)
            }
        }
    }
    
    var scrollView: NSScrollView = NSScrollView()
    var scrollbackTextView: NSTextView = NSTextView()
    var inputField: TextField = TextField()
    
    // history handling
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
            if prev == .currentLine { self.currentlyEditedLine = self.inputField.stringValue }
            switch(self.historyNavigationState) {
            case .currentLine: self.inputField.stringValue = self.currentlyEditedLine ?? ""
            case .historyItem(let index): self.inputField.stringValue = self.history[index]
            }
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
            self.inputField.font = v
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        self.configureSubviews()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.configureSubviews()
    }
    
    private func println(_ line: String) {
        let visibleRect = self.scrollView.documentVisibleRect
        let docHeight = self.scrollView.documentView!.frame.size.height
        let distanceFromBottom = docHeight - (visibleRect.origin.y+visibleRect.size.height)
        
        if !self.scrollbackTextView.string.isEmpty {
            self.scrollbackTextView.string.append("\n")
        }
        self.scrollbackTextView.string.append(line)
        if distanceFromBottom < 1.0 {
            self.scrollView.documentView?.scrollToEndOfDocument(nil)
        }
        self.needsLayout = true
    }
    
    private func configureSubviews() {
        self.addSubview(self.scrollView)
        self.scrollView.documentView = self.scrollbackTextView
        self.scrollView.borderType = .noBorder
        self.scrollView.hasVerticalScroller = true
        self.scrollView.autohidesScrollers = true
        self.addSubview(self.inputField)
        self.inputField.placeholderString = " "
        self.inputField.preferredMaxLayoutWidth = self.frame.width
        self.inputField.delegate = self
        self.inputField.maximumNumberOfLines = 0
        self.inputField.submitText = { line in
            self.println(line)
            self.addToHistory(line: line)
            self.historyNavigationState = .currentLine
        }
        
        self.inputField.handleSpecialKey = self.handleInputSpecialKey
        
        self.scrollbackTextView.isEditable = false
        
        self.needsLayout = true
        
        self.scrollbackTextView.wantsLayer = true
        self.scrollbackTextView.layer?.backgroundColor = NSColor.green.cgColor
        self.inputField.wantsLayer = true
        self.inputField.layer?.backgroundColor = NSColor.yellow.cgColor
        
    }
    
    override func layout() {
        super.layout()
        self.inputField.stringValue = self.inputField.stringValue
        let inputTextSize = self.inputField.sizeThatFits(self.frame.size)
        self.inputField.preferredMaxLayoutWidth = self.frame.width
        self.inputField.frame = NSRect(x: 0.0, y: 0.0, width: self.frame.width, height: max(inputTextSize.height, 24.0))
        
        
        if let layoutManager = self.scrollbackTextView.layoutManager, let textContainer = self.scrollbackTextView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let textSize = layoutManager.usedRect(for: textContainer)
            self.scrollView.frame = NSRect(x: 0.0, y: self.inputField.frame.height, width: self.frame.width, height: min(self.frame.height - self.inputField.frame.height, textSize.height))
            self.scrollbackTextView.frame = NSRect(x: 0.0, y: 0.0, width: self.scrollView.frame.width, height: textSize.height)
        }
    }
    
    func handleInputSpecialKey(_ key: TextField.SpecialKey) {
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

extension REPLView: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        self.needsLayout = true
    }
}
