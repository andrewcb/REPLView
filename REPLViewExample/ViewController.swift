//
//  ViewController.swift
//  REPLView
//
//  Created by acb on 17/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet var replView: REPLView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.replView.font = NSFont(name: "Monaco", size: 24.0)
        self.replView.evaluator = { (line) in
            guard let numeric = Int(line) else { return .error("Not a number: “\(line)”")}
            return .output(String(format:"0x%08x", numeric))
        }
        self.replView.printOutputLn("Welcome! Enter a number in decimal to see its  hexadecimal representation.")

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

