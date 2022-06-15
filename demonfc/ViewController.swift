//
//  ViewController.swift
//  demonfc
//
//  Created by Avaneesh on 20/04/22.
//

import UIKit
import CoreNFC

class ViewController: UIViewController {
    
    @IBOutlet weak var startScanButton : UIButton!
    @IBOutlet weak var resultDetails : UITextView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.resultDetails.text = "Test results"
        // Do any additional setup after loading the view.
    }

    @IBAction func startScan(sender : UIButton) {
        guard NFCTagReaderSession.readingAvailable else {
            return self.showAlert()
        }
        //[iso15693,iso14443,iso18092]
        let session = NFCTagReaderSession(
            pollingOption: .iso14443, // Choose based on tag type
            delegate: self
        )
        session?.alertMessage = "Hold the tag to the back of your phone to scan it."
        session?.begin()
        
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Warning!!", message: "NFC is not available with device Please check with other devices.", preferredStyle:.alert)
        let alertAction = UIAlertAction(title: "Ok ", style: .default) { alert in }
        alert.addAction(alertAction)
        self.present(alert, animated: true)
        
    }

}


extension ViewController :NFCTagReaderSessionDelegate {
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        session.restartPolling()
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if case let NFCTag.miFare(tag) = tags.first! {
            session.connect(to: tags.first!) { (error: Error?) in
                let apdu = NFCISO7816APDU(instructionClass: 0, instructionCode: 0xB0, p1Parameter: 0, p2Parameter: 0, data: Data(), expectedResponseLength: 16)
                tag.sendMiFareISO7816Command(apdu) { (apduData, sw1, sw2, error) in
                    let tagUIDData = tag.identifier
                    var byteData: [UInt8] = []
                    tagUIDData.withUnsafeBytes { byteData.append(contentsOf: $0) }
                    var uidString = ""
                    for byte in byteData {
                        let decimalNumber = String(byte, radix: 16)
                        if (Int(decimalNumber) ?? 0) < 10 { // add leading zero
                            uidString.append("0\(decimalNumber)")
                        } else {
                            uidString.append(decimalNumber)
                        }
                    }
                    debugPrint("\(byteData) converted to Tag UID: \(uidString)")
                    DispatchQueue.main.async {
                        self.resultDetails.text.append("\n converted to Tag UID: \(uidString)")
                    }
                    session.invalidate()
                }
            }
        }
        if case let NFCTag.iso15693(tag) = tags.first! {
            session.connect(to: tags.first!) { (error: Error?) in
                let identifier = tag.identifier
                let serialNumber = tag.icSerialNumber
                print("\(identifier) is identifier and serial number is \(serialNumber)")
                let serialHex = serialNumber.reversed() .map { (data) -> String in
                     return String(format: "%02X", data)
                 }.joined()
               let finalString = "\n identifier : \(identifier) \n serialNumber : \(serialNumber) \n HexDetails\(serialHex)"
                 self.resultDetails.text.append(finalString)
                 session.invalidate()
                }
            }
        }

}
