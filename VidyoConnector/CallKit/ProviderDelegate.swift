//
//  ProviderDelegate.swift
//  VidyoConnector
//

import UIKit
import AVFoundation
import CallKit
import Foundation

class ProviderDelegate: NSObject {
    
    private let callManager: CallManager
    private let provider: CXProvider
    
    var outgoingCall: Call?
    var answerCall: Call?
    
    init(callManager: CallManager) {
        
        self.callManager = callManager
        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)
        
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    /// The app's provider configuration, representing its CallKit capabilities
    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Vidyo")
        
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        
        // TODO: Provide own icon
        // providerConfiguration.iconTemplateImageData = #imageLiteral(resourceName: "OwnIcon").pngData()
        
        return providerConfiguration
    }()
    
    func reportIncomingCall(uuid: UUID, handle: String) {
        let update = CXCallUpdate()
        
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = true
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                let call = Call(uuid: uuid)
                call.handle = handle
                
                self.callManager.addCall(call)
            }
        }
    }
    
    /// See https://forums.developer.apple.com/thread/64544
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print(error)
        }
    }
}

extension ProviderDelegate: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
        /*
         End any ongoing calls if the provider resets, and remove them from the app's list of calls,
         since they are no longer valid.
         */
    }
    
    // MARK: Start Action
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        let call = Call(uuid: action.callUUID, isOutgoing: true)
        call.handle = action.handle.value
        
        print("VidyoCall: CXStartCallAction. UUID: \(call.uuid.uuidString)")
        
        configureAudioSession()
        
        self.outgoingCall = call
        provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())

        action.fulfill()
    }
    
    // MARK: Answer Action
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            fatalError("Error gathering call item.")
        }
        
        print("VidyoCall: CXAnswerCallAction. UUID: \(call.uuid.uuidString)")
        configureAudioSession()
        
        self.answerCall = call
        action.fulfill()
    }
    
    // MARK: End Action
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            fatalError("Error gathering call item.")
        }
        
        print("VidyoCall: CXEndCallAction UUID: \(call.uuid.uuidString)")
        
        action.fulfill()
        callManager.removeCall(call)
    }
    
    // MARK: Timeout Action

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("VidyoCall: \(#function)")
    }
    
    // MARK: Activate Audio Session Action

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        /* Call has been answered */
        if let _ = answerCall {
            print("VidyoCall: DidActivate AudioSession as Incoming")
        } else if let call = outgoingCall {
            print("VidyoCall: DidActivate AudioSession as Outgoing")
            provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
        } else {
            print("VidyoCall: DidActivate Error: not detected call item.")
            return
        }
        
        callManager.startVideoCall()
    }
    
    // MARK: Deactivate Audio Session Action

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("VidyoCall: DidDeactivate AudioSession.")
        
        outgoingCall = nil
        answerCall = nil
        callManager.removeAllCalls()
    }
}
