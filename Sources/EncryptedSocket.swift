import Foundation
import PackStream
import NIOOpenSSL
import NIO

public class EncryptedSocket: UnencryptedSocket {
    
    var handler: OpenSSLClientHandler!

    override func setupBootstrap(_ group: MultiThreadedEventLoopGroup, _ dataHandler: ReadDataHandler) -> (ClientBootstrap) {
        return ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler: self.handler).then { v in
                    channel.pipeline.add(handler: dataHandler)
                }
        }
    }
    
    override public func connect(timeout: Int) throws {
        
        let configuration = TLSConfiguration.forClient(certificateVerification: .none) // allow self signed
        let sslContext = try SSLContext(configuration: configuration)
        let handler = try OpenSSLClientHandler(context: sslContext)
        self.handler = handler
        try super.connect(timeout: timeout)
    }

}
