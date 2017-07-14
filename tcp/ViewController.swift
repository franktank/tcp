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
    
    let cluster = ["192.168.10.57", "192.168.10.58", "192.168.10.60"]
    var tcpSendSocket: GCDAsyncSocket?
    var tcpReceiveSocket: GCDAsyncSocket?
    
    @IBOutlet weak var sendButton: UIButton!
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

    @IBAction func touchSendButton(_ sender: Any) {
        for server in cluster {
            if (server == getIFAddresses()[1]) {
                continue
            }
            sendMessage(server: server)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to: " + host + " " + port.description)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("WROTEE")
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("WHAT")
        tcpReceiveSocket = newSocket
        receiveMessages()
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

    func sendMessage(server: String) {
        do {
            try tcpSendSocket?.connect(toHost: server, onPort: 20011)
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

    func receiveMessages() {
        //        DispatchQueue.main.async {
        tcpReceiveSocket?.readData(withTimeout: -1, tag: 0)
        //        }
    }
    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        return addresses
    }
    
}

