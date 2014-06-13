# C structure packing for Swift

Class for packing C structures in Swift, modeled after the [struct](https://docs.python.org/2/library/struct.html) module in Python.

Sample usage:

    import GUStructPacker
    
    var error: NSError?
    let packer = StructPacker()
    if let result = packer.pack(["H", "e", "l", "l", "o"], format: "ccccc", error: &error) {
        // result is now 15 bytes of NSData.
    } else {
        // Data could not be encoded according to format, check error.
    }
