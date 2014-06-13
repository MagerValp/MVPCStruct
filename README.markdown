# C struct handling for Swift

Class for packing and unpacking C structs in Swift, modeled after the [struct](https://docs.python.org/2/library/struct.html) module in Python.

## Sample Code

    import MVPCStruct
    
    // Receiver expects a message with a header like this:
    //  typedef struct {
    //      uint16_t version;  // Message format version, currently 0x0100.
    //      uint16_t reserved; // Reserved for future use.
    //      uint32_t length;   // Length of data in bytes.
    //      uint8_t data[];    // Binary encoded plist.
    //  } __attribute__((packed)) mma_msg_t;
    func sendMessageHeader(msgData: NSData) -> Bool {
        var error: NSError?
        
        let version = 0x0100
        let reserved = 0
        
        let packer = CStruct(format: "=HHI")
        if let packedHeader = packer.pack([version, reserved, msgData.length], error: &error) {
            return 8 == send(socket_fd, packedHeader.bytes, packedHeader.length)
        } else {
            return false
        }
    }

# Tasks

## Creating CStruct Objects

### - initWithFormat:

    init(format: String)

## Unpacking data

### - unpack:format:error:

    func unpack(data: NSData, format: String, error: NSErrorPointer) -> AnyObject[]?

### - unpack:error:

    func unpack(data: NSData, error: NSErrorPointer) -> AnyObject[]?

## Packing values

### - pack:format:error:

    func pack(values: AnyObject[], format: String, error: NSErrorPointer) -> NSData?

### - pack:error:

    func pack(values: AnyObject[], error: NSErrorPointer) -> NSData? {


# Format strings

## Control characters

<table>
    <tr>
        <th></th>
        <th>BYTE ORDER</th>
        <th>SIZE</th>
        <th>ALIGNMENT</th>
    </tr>
    <tr>
        <td>@</td>
        <td>native</td>
        <td>native</td>
        <td>native</td>
    </tr>
    <tr>
        <td>=</td>
        <td>native</td>
        <td>standard</td>
        <td>none</td>
    </tr>
    <tr>
        <td>&lt;</td>
        <td>little-endian</td>
        <td>standard</td>
        <td>none</td>
    </tr>
    <tr>
        <td>&gt;</td>
        <td>big-endian</td>
        <td>standard</td>
        <td>none</td>
    </tr>
    <tr>
        <td>!</td>
        <td>network (BE)</td>
        <td>standard</td>
        <td>none</td>
    </tr>
</table>

## Format characters

<table>
    <tr>
        <th>FORMAT</th>
        <th>C TYPE</th>
        <th>SWIFT TYPE</th>
        <th>SIZE</th>
    </tr>
    <tr>
        <td>x</td>
        <td>pad byte</td>
        <td>no value</td>
        <td></td>
    </tr>
    <tr>
        <td>c</td>
        <td>char</td>
        <td>String of length 1</td>
        <td>1</td>
    </tr>
    <tr>
        <td>b</td>
        <td>signed char</td>
        <td>Int</td>
        <td>1</td>
    </tr>
    <tr>
        <td>B</td>
        <td>unsigned char</td>
        <td>UInt</td>
        <td>1</td>
    </tr>
    <tr>
        <td>?</td>
        <td>_Bool</td>
        <td>Bool</td>
        <td>1</td>
    </tr>
    <tr>
        <td>h</td>
        <td>short</td>
        <td>Int</td>
        <td>2</td>
    </tr>
    <tr>
        <td>H</td>
        <td>unsigned short</td>
        <td>UInt</td>
        <td>2</td>
    </tr>
    <tr>
        <td>i</td>
        <td>int</td>
        <td>Int</td>
        <td>4</td>
    </tr>
    <tr>
        <td>I</td>
        <td>unsigned int</td>
        <td>UInt</td>
        <td>4</td>
    </tr>
    <tr>
        <td>l</td>
        <td>long</td>
        <td>Int</td>
        <td>4</td>
    </tr>
    <tr>
        <td>L</td>
        <td>unsigned long</td>
        <td>UInt</td>
        <td>4</td>
    </tr>
    <tr>
        <td>q</td>
        <td>long long</td>
        <td>Int</td>
        <td>8</td>
    </tr>
    <tr>
        <td>Q</td>
        <td>unsigned long long</td>
        <td>UInt</td>
        <td>8</td>
    </tr>
    <tr>
        <td>f</td>
        <td>float</td>
        <td>Float</td>
        <td>4</td>
    </tr>
    <tr>
        <td>d</td>
        <td>double</td>
        <td>Double</td>
        <td>8</td>
    </tr>
    <tr>
        <td>s</td>
        <td>char[]</td>
        <td>String</td>
        <td></td>
    </tr>
    <tr>
        <td>p</td>
        <td>char[]</td>
        <td>String</td>
        <td></td>
    </tr>
    <tr>
        <td>P</td>
        <td>void *</td>
        <td>UInt</td>
        <td>4/8</td>
    </tr>
</table>
