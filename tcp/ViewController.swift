//
//  ViewController.swift
//  tcp
//
//  Created by Frank the Tank on 7/14/17.
//  Copyright © 2017 Frank the Tank. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import SwiftyJSON

class ViewController: UIViewController, GCDAsyncSocketDelegate {
    
    @IBOutlet weak var sendButton: UIButton!
    var tcpSendSocket: GCDAsyncSocket?
    var tcpReceiveSocket: GCDAsyncSocket?
    
    
    @IBOutlet weak var messageTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let sendSocketQueue = DispatchQueue.init(label: "send")
        tcpSendSocket = GCDAsyncSocket(delegate: self, delegateQueue: sendSocketQueue)
        let receiveSocketQueue = DispatchQueue.init(label: "recv")
        tcpReceiveSocket = GCDAsyncSocket(delegate: self, delegateQueue: receiveSocketQueue)
//        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try tcpReceiveSocket?.accept(onPort: 20011)
        } catch {
            print(error)
        }
        receiveMessages()
        
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to: " + host + " " + port.description)
    }
    
    func sendMessage() {
        do {
//            try tcpSendSocket?.connect(toHost: "192.168.10.60", onPort: 20011) // frank tank
            try tcpSendSocket?.connect(toHost: "192.168.10.58", onPort: 20011) // ipad
        } catch {
            print(error)
        }
        let sendJson: JSON = [
            "type": "message",
            "message": "Some stuff"
        ]
        
        guard let sendData = sendJson.rawString()?.data(using: String.Encoding.utf8) else {
            print("Failed to create sendData")
            return
        }
        
        tcpSendSocket?.write(sendData, withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("WROTEE")
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("WHAT")
        tcpReceiveSocket = newSocket
        receiveMessages()
    }
    
    func receiveMessages() {
//        DispatchQueue.main.async {
//            while true {
//                self.tcpSocket?.readData(withTimeout: -1, tag: 0)
//            }
            tcpReceiveSocket?.readData(withTimeout: -1, tag: 0)
//        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let receiveJson = JSON(data: data)
        print(receiveJson)
        print("READ!")
        if (receiveJson["type"].stringValue == "message") {
            DispatchQueue.main.async {
                self.messageTextView.text = self.messageTextView.text + receiveJson["message"].stringValue
            }
            receiveMessages()
        }
    }

    @IBAction func touchSendButton(_ sender: Any) {
        sendMessage()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

