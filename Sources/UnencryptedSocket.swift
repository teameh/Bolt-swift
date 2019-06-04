import Foundation
import PackStream
import NIO
import NIOTransportServices

public class UnencryptedSocket {
    
    let hostname: String
    let port: Int
    
    var group: EventLoopGroup?
    var bootstrap: NIOTSConnectionBootstrap?
    var channel: Channel?
    
    var readGroup: DispatchGroup?
    var receivedData: [UInt8] = []
    
    fileprivate static let readBufferSize = 8192
    
    public init(hostname: String, port: Int) throws {
        self.hostname = hostname
        self.port = port
    }
    
    func setupBootstrap(_ group: MultiThreadedEventLoopGroup, _ dataHandler: ReadDataHandler) -> (NIOTSConnectionBootstrap) {
        
        let overrideGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .utility)
        
        return NIOTSConnectionBootstrap(group: overrideGroup)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([dataHandler], position: .last)
            }
    }
    
    public func connect(timeout: Int) throws {
        
        let dataHandler = ReadDataHandler()
        let leave = { [weak self] (identifier: String) in
            self?.readGroup?.leave()
        }
        
        dataHandler.dataReceivedBlock = { data in
            self.receivedData = data
            leave("leave")
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        let bootstrap = setupBootstrap(group, dataHandler)
        self.bootstrap = bootstrap
        let channel = try bootstrap.connect(host: hostname, port: port).wait()
        self.channel = channel
    }
}

extension UnencryptedSocket: SocketProtocol {
    
    
    public func disconnect() {
        try? channel?.close(mode: .all).wait()
        try? group?.syncShutdownGracefully()
    }
    
    public func send(bytes: [Byte]) throws {
        
        guard let channel = channel else { return }
        
        var buffer = channel.allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        try _ = channel.writeAndFlush(buffer).wait()
    }
    
    public func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {
        
        if self.readGroup != nil {
            print("Error: already reading")
            return []
        }
        self.readGroup = DispatchGroup()
        self.readGroup?.enter()
        
        self.channel?.read()
        
        self.readGroup?.wait()
        self.readGroup = nil
        
        let outData = self.receivedData
        self.receivedData = []
        return outData
    }
}
