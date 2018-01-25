//
//  ViewController.swift
//  iOS Example
//
//  Created by GongXiang on 1/25/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import UIKit
import Evil

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let recognizer = ChineseIDCardRecognizer.`default` {
            debugPrint(recognizer)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

