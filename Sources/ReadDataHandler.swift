import Foundation
import NIO

class ReadDataHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    private var numBytes = 0
    
    var dataReceivedBlock: ((ByteBuffer) -> ())?
    
    func channelActive(ctx: ChannelHandlerContext) {
        ctx.fireChannelActive()
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        
        let buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        dataReceivedBlock?(buffer)
        
        if readableBytes == 0 {
            print("nothing left to read, close the channel")
            ctx.close(promise: nil)
        }
        
        ctx.fireChannelRead(data)
        
    }
    
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        ctx.close(promise: nil)
    }
}
