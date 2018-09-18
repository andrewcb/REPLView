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
    
    class TextField: NSTextField {
        var submitText: ((String)->())?
        
        override func keyUp(with event: NSEvent) {
            print("keyUp: keyCode = \(event.keyCode); modifierFlags = \(event.modifierFlags) \(event.modifierFlags.intersection(.deviceIndependentFlagsMask))")
            if event.keyCode == 36 /* Enter */ && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.submitText?(self.stringValue)
                self.stringValue = ""
            } else {
                super.keyUp(with: event)
            }
        }
    }
    
    
    var scrollView: NSScrollView = NSScrollView()
    var scrollbackTextView: NSTextView = NSTextView()
    var inputField: TextField = TextField()
    
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
        // TODO: scroller
        self.addSubview(self.scrollView)
//        self.scrollView.contentView.addSubview(self.scrollbackTextView)
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
        }
        
//        self.scrollbackTextView.string.append("Hello world!\n")
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
//        print("\(inputField.stringValue) -> \(inputTextSize)")
        self.inputField.preferredMaxLayoutWidth = self.frame.width
        self.inputField.frame = NSRect(x: 0.0, y: 0.0, width: self.frame.width, height: max(inputTextSize.height, 24.0))
        
        
        if let layoutManager = self.scrollbackTextView.layoutManager, let textContainer = self.scrollbackTextView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let textSize = layoutManager.usedRect(for: textContainer)
            self.scrollView.frame = NSRect(x: 0.0, y: self.inputField.frame.height, width: self.frame.width, height: min(self.frame.height - self.inputField.frame.height, textSize.height))
            self.scrollbackTextView.frame = NSRect(x: 0.0, y: 0.0, width: self.scrollView.frame.width, height: textSize.height)
//            self.scrollView.documentView?.frame = NSRect(origin: .zero, size: textSize.size)
//            self.scrollbackTextView.frame = NSRect(x: 0.0, y: self.inputField.frame.height, width: textSize.width, height: textSize.height)
        }
    }
    
}

extension REPLView: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        self.needsLayout = true
    }
}
