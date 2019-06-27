import Foundation
import PackStream
import NIO
import NIOTransportServices
import Network
import Security
import CommonCrypto

extension Data {
    func sha1() -> String {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(self.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

public class EncryptedSocket: UnencryptedSocket {
    
    lazy var certificateValidator: CertificateValidatorProtocol = UnsecureCertificateValidator(hostname: self.hostname, port: UInt(self.port))
    
    override func setupBootstrap(_ group: MultiThreadedEventLoopGroup, _ dataHandler: ReadDataHandler) -> (NIOTSConnectionBootstrap) {
        
        let group = NIOTSEventLoopGroup()
        
        // let certStoreFilePath = URL(fileURLWithPath: NSTemporaryDirectory(),
        //                                isDirectory: true).appendingPathComponent("certStore").path
        
        return NIOTSConnectionBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHandler(dataHandler)
            }
            .tlsConfig(validator: self.certificateValidator)
            //.tlsConfig(validator: StoreCertSignaturesInFileCertificateValidator(hostname: self.hostname, port: UInt(self.port), filePath: certStoreFilePath) )
    }
}

extension NIOTSConnectionBootstrap {
    
    func tlsConfig(validator: CertificateValidatorProtocol) -> NIOTSConnectionBootstrap {
        let options = NWProtocolTLS.Options()
        let verifyQueue = DispatchQueue(label: "verifyQueue")
        let verifyBlock: sec_protocol_verify_t = { (metadata, trust, verifyCompleteCB) in
            let actualTrust = sec_trust_copy_ref(trust).takeRetainedValue()
            if(validator.trustedCertificates.count > 0) {
                SecTrustSetAnchorCertificates(actualTrust, validator.trustedCertificates as CFArray)
            }
            SecTrustSetPolicies(actualTrust, SecPolicyCreateSSL(true, nil))
            
            // only available starting with macOS 10.15 & iOS 13
            // let serverName = sec_protocol_metadata_get_server_name(metadata)
            
            SecTrustEvaluateAsync(actualTrust, verifyQueue) { (trust, result) in
                
                var optionalSha1: String? = nil
                let count = SecTrustGetCertificateCount(trust)
                if count >= 1 {
                    for index in 0..<count {
                        if let cert = SecTrustGetCertificateAtIndex(trust, index) {
                            let certData = SecCertificateCopyData(cert) as Data
                            optionalSha1 = certData.sha1()
                            break
                        }
                    }
                } else {
                    verifyCompleteCB(false)
                    return
                }
                
                guard let sha1 = optionalSha1, sha1 != "" else {
                    verifyCompleteCB(false)
                    return
                }

                switch result {
                case .proceed, .unspecified:
                    validator.didTrustCertificate(withSHA1: sha1)
                    verifyCompleteCB(true)
                default:
                    if(!validator.shouldTrustCertificate(withSHA1: sha1)) {
                        verifyCompleteCB(false)
                    } else {
                        validator.didTrustCertificate(withSHA1: sha1)
                        verifyCompleteCB(true)
                    }
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
