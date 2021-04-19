//
//  CallManager.swift
//  VidyoConnector
//

import UIKit
import CallKit

class CallManager {
    
    enum CallState: String {
        case start = "startCall"

        case startVideoCall = "startVideoCall"

        case end = "endCall"
        case hold = "holdCall"
    }
    
    let callController = CXCallController()
    
    // MARK: Actions
    func startCall(handle: String, video: Bool = false) {
        let uuid = UUID()
        
        let cxHandle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: cxHandle)
        
        startCallAction.isVideo = video
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        requestTransaction(transaction, action: CallState.start.rawValue) {
            [weak self] (status) in
            guard let this = self else { fatalError() }
            
            if (status) {
                let call = Call(uuid: uuid)
                call.handle = handle
                this.addCall(call)
            }
            
            print("VidyoCall: Start call requested. UUID: \(uuid.uuidString). Status: \(status)")
        }
    }
    
    func end(call: Call) {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        
        requestTransaction(transaction, action: CallState.end.rawValue) { status in
            print("VidyoCall: End call requested. UUID: \(call.uuid.uuidString). Status: \(status)")
        }
    }
    
    func setHeld(call: Call, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
        
        requestTransaction(transaction, action: CallState.hold.rawValue) { (status) in
            print("Held transaction completed: \(status)")
        }
    }
    
    private func requestTransaction(_ transaction: CXTransaction, action: String = "",
                                    completion: @escaping ((Bool) -> ())) {
        callController.request(transaction) { error in
            if let error = error {
                completion(false)
                print("Error requesting transaction: \(error)")
            } else {
                completion(true)
                print("Requested transaction \(action) successfully")
            }
        }
    }
    
    // MARK: Call Management
    
    public static let CallsChangedNotification = Notification.Name("CallManagerCallsChangedNotification")
    
    private(set) var calls = [Call]()
    
    func callWithUUID(uuid: UUID) -> Call? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else {
            return nil
        }
        
        return calls[index]
    }
    
    func startVideoCall() -> Void {
        postCallsChangedNotification(userInfo: ["action": CallState.startVideoCall.rawValue])
    }
    
    func addCall(_ call: Call) {
        calls.append(call)
        postCallsChangedNotification(userInfo: ["action": CallState.start.rawValue])
    }
    
    func removeCall(_ call: Call) {
        calls = calls.filter {$0 === call}
        postCallsChangedNotification(userInfo: ["action": CallState.end.rawValue])
    }
    
    func removeAllCalls() {
        calls.removeAll()
        postCallsChangedNotification(userInfo: ["action": CallState.end.rawValue])
    }
    
    private func postCallsChangedNotification(userInfo: [String: Any]? = nil) {
        NotificationCenter.default.post(name: type(of: self).CallsChangedNotification, object: self, userInfo: userInfo)
    }
}
