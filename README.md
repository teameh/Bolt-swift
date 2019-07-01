# Bolt-swift
The Bolt network protocol is a network protocol designed for high-performance access to graph databases. Bolt is a connection-oriented protocol, using a compact binary encoding over TCP or web sockets for higher throughput and lower latency.

The reference implementation can be found [here](https://github.com/neo4j-contrib/boltkit). This codebase is the Swift implementation, and is used by [Theo, the Swift Neo4j driver](https://github.com/Neo4j-Swift/Neo4j-Swift).

## Connection
The implementation supports both SSL-encrypted and plain-text connections, built on [SwiftNIO 2](https://github.com/apple/swift-nio). SSL connections can be both have a regular chain of trust, be given an explicit certificate to trust, or be untrusted. Further more, you can implement your own trust behaviour on top.

## Tests

Note, tests are destructive to the data in the database under test, so run them on a database created especially for running the tests

## Getting started

To use directly with Xcode, type "swift package generate-xcodeproj"


### Swift Package Manager
Add the following to your dependencies array in Package.swift:
```swift
.package(url: "https://github.com/Neo4j-Swift/Bolt-swift.git", .branch("master")),
```
and you can now do a
```bash
swift build
```

### CocoaPods
Add the 
```ruby
pod "BoltProtocol"
```
to your Podfile, and you can now do
```bash
pod install
```
to have Bolt included in your Xcode project via CocoaPods

### Carthage
Put 
```ogdl
github "Neo4j-Swift/Bolt-swift"
```
in your Cartfile. If this is your entire Cartfile, do
```bash
carthage bootstrap
```
If you have already done that, do
```bash
carthage update
```
instead.

Then do 
```bash
cd Carthage/Checkouts/bolt-swift
swift package generate-xcodeproj
cd -
```

And Carthage is now set up. You can now do
```bash
carthage build --platform Mac
```
and you should find a build for macOS. If you want to build for iOS, before generating the Xcode project, remove the ShellOut dependency from Package.swift, and then use --platoform iOS instead.
tvOS and watchOS builds with Carthage are currently unavailable.
