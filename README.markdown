# Structure packing for Swift

Proof of concept for packing structures in Swift, modeled after the [struct](https://docs.python.org/2/library/struct.html) module in Python.

Sample usage:

    import GUStructPacker
    
    var error: NSError?
    if let result = Struct.pack("<bhiq", data: [-1, -2, -3, -4], error: &error) {
        // result is now 15 bytes of NSData.
    } else {
        // Data could not be encoded according to format.
        println("\(error?.localizedDescription)")
    }
