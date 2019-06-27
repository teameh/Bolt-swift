import Foundation

public protocol CertificateValidatorProtocol {
    
    var hostname: String { get }
    var port: UInt { get }
    var trustedCertificates: [SecCertificate] { get }
    func shouldTrustCertificate(withSHA1: String) -> Bool
    func didTrustCertificate(withSHA1: String)
}
