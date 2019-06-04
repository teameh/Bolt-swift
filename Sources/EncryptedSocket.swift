import Foundation
import PackStream
import NIOSSL
import NIOTLS
import NIO
import NIOExtras

import NIOTransportServices

import Network

public class EncryptedSocket: UnencryptedSocket {
    
    
    override func setupBootstrap(_ group: MultiThreadedEventLoopGroup, _ dataHandler: ReadDataHandler) -> (NIOTSConnectionBootstrap) {
        
        // let group = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .utility)
        let group = NIOTSEventLoopGroup()
        
        return NIOTSConnectionBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                //return channel.pipeline.addHandler(ChatHandler())
                //return channel.pipeline.addHandler(ReadDataHandler())
                return channel.pipeline.addHandler(dataHandler)
            }
            .tlsConfigOneTrustedCert()
    }
}

extension NIOTSConnectionBootstrap {
    
    class func getCert() -> SecCertificate {
        let path = "/tmp/server.der"
        let data: Data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let cert = SecCertificateCreateWithData(nil, data as CFData)
        return cert!
    }
    
    
    func tlsConfigOneTrustedCert() -> NIOTSConnectionBootstrap {
        let options = NWProtocolTLS.Options()
        let verifyQueue = DispatchQueue(label: "verifyQueue")
        let mySelfSignedCert: SecCertificate = NIOTSConnectionBootstrap.getCert()
        let verifyBlock: sec_protocol_verify_t = { (metadata, trust, verifyCompleteCB) in
            let actualTrust = sec_trust_copy_ref(trust).takeRetainedValue()
            SecTrustSetAnchorCertificates(actualTrust, [mySelfSignedCert] as CFArray)
            SecTrustSetPolicies(actualTrust, SecPolicyCreateSSL(true, nil))
            SecTrustEvaluateAsync(actualTrust, verifyQueue) { (_, result) in
                switch result {
                case .proceed, .unspecified:
                    verifyCompleteCB(true)
                default:
                    verifyCompleteCB(false)
                }
            }
        }
        
        sec_protocol_options_set_verify_block(options.securityProtocolOptions, verifyBlock, verifyQueue)
        return self.tlsOptions(options)
    }
    
    func tlsConfigDefault() -> NIOTSConnectionBootstrap {
        return self.tlsOptions(.init()) // To remove TLS (unencrypted), just return self
    }
    
    
}
