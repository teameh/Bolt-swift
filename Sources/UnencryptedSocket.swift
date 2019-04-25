import Foundation
import PackStream
import NIO

public class UnencryptedSocket {
    
    let hostname: String
    let port: Int
    
    var group: EventLoopGroup?
    var bootstrap: ClientBootstrap?
    var channel: Channel?
    
    var readGroup: DispatchGroup?
    var receivedData: [UInt8] = []
//    var receivedBuffers: [ByteBuffer] = []
//    var receivedBuffersQueue: DispatchQueue
    
    fileprivate static let readBufferSize = 8192
    
    public init(hostname: String, port: Int) throws {
        // self.receivedBuffersQueue = /* OperationQueue.current?.underlyingQueue ??*/ DispatchQueue.global(qos: .background)
        self.hostname = hostname
        self.port = port
    }
    
    func setupBootstrap(_ group: MultiThreadedEventLoopGroup, _ dataHandler: ReadDataHandler) -> (ClientBootstrap) {
        return ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler: dataHandler)
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
        buffer.write(bytes: bytes)
        _ = channel.writeAndFlush(buffer)
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
