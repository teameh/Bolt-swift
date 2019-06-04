###################################
### Swift Package Manager (SPM) ###
###################################
alias genxcode="swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig"
alias boltbuild='swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.14"'
alias bolttest='swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.14"'
