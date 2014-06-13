//
//  Struct.swift
//  GUStructPacker
//
//  Created by Pelle on 2014-06-12.
//  Copyright (c) 2014 Göteborgs universitet. All rights reserved.
//

import Cocoa


//      BYTE ORDER      SIZE            ALIGNMENT
//  @   native          native          native
//  =   native          standard        none
//  <   little-endian   standard        none
//  >   big-endian      standard        none
//  !   network (BE)    standard        none


//      FORMAT  C TYPE                  SWIFT TYPE              SIZE
//      x       pad byte                no value
//      c       char                    String of length 1      1
//      b       signed char             Int                     1
//      B       unsigned char           UInt                    1
//      ?       _Bool                   Bool                    1
//      h       short                   Int                     2
//      H       unsigned short          UInt                    2
//      i       int                     Int                     4
//      I       unsigned int            UInt                    4
//      l       long                    Int                     4
//      L       unsigned long           UInt                    4
//      q       long long               Int                     8
//      Q       unsigned long long      UInt                    8
//      f       float                   Float                   4
//      d       double                  Double                  8
//      s       char[]                  String
//      p       char[]                  String
//      P       void *                  CMutableVoidPointer
//
//      Floats and doubles are packed with IEEE 754 binary32 or binary64 format.


// Split a large integer into bytes.
extension Int {
    func splitBytes(endianness: StructPacker.Endianness, size: Int) -> UInt8[] {
        var bytes = UInt8[]()
        var shift: Int
        var step: Int
        if endianness == .LittleEndian {
            shift = 0
            step = 8
        } else {
            shift = (size - 1) * 8
            step = -8
        }
        for count in 0..size {
            bytes.append(UInt8((self >> shift) & 0xff))
            shift += step
        }
        return bytes
    }
}
extension UInt {
    func splitBytes(endianness: StructPacker.Endianness, size: Int) -> UInt8[] {
        var bytes = UInt8[]()
        var shift: Int
        var step: Int
        if endianness == .LittleEndian {
            shift = 0
            step = 8
        } else {
            shift = Int((size - 1) * 8)
            step = -8
        }
        for count in 0..size {
            bytes.append(UInt8((self >> UInt(shift)) & 0xff))
            shift = shift + step
        }
        return bytes
    }
}


class StructPacker: NSObject {
    
    enum Error: Int {
        case Parsing = -1
        case Packing = -2
        case Unpacking = -3
    }
    let ERROR_DOMAIN = "se.gu.it.GUStructPacker"
    
    enum Endianness {
        case LittleEndian
        case BigEndian
    }
    
    // Packing format strings are parsed to a stream of ops.
    enum Ops {
        // Stop packing.
        case Stop
        
        // Control endianness.
        case SetNativeEndian
        case SetLittleEndian
        case SetBigEndian
        
        // Control alignment.
        case SetAlign
        case UnsetAlign
        
        // Pad bytes.
        case SkipByte
        
        // Packed values.
        case PackChar
        case PackInt8
        case PackUInt8
        case PackBool
        case PackInt16
        case PackUInt16
        case PackInt32
        case PackUInt32
        case PackInt64
        case PackUInt64
        case PackFloat
        case PackDouble
        case PackCString
        case PackPString
        case PackPointer
    }
    
    var opStream = Ops[]()
    
    let PAD_BYTE = UInt8(0)
    
    var platformEndianness: Endianness {
        return .LittleEndian
    }
    
    convenience init(format: String) {
        self.init()
        var error: NSError?
        if !self.parseFormat(format, error: &error) {
            assert(false, "format string parsing error")
        }
    }
    
    func pack(values: AnyObject[], format: String, error: NSErrorPointer) -> NSData? {
        if !self.parseFormat(format, error: error) {
            return nil
        }
        return self.pack(values, error: error)
    }
    
    func pack(values: AnyObject[], error: NSErrorPointer) -> NSData? {
        
        var bytes = UInt8[]()
        var index = 0
        var alignment = true
        var endianness = self.platformEndianness
        
        // Set error message and return nil.
        func failure(message: String) -> NSData? {
            if error {
                error.memory = NSError(domain: ERROR_DOMAIN,
                    code: Error.Packing.toRaw(),
                    userInfo: [NSLocalizedDescriptionKey: message])
            }
            return nil
        }
        
        // If alignment is requested, emit pad bytes until alignment is
        // satisfied.
        func padAlignment(size: Int) {
            if alignment {
                let mask = size - 1
                while (bytes.count & mask) != 0 {
                    bytes.append(PAD_BYTE)
                }
            }
        }
        
        for op in self.opStream {
            // First check ops that don't consume values.
            switch op {
                
            case .SetNativeEndian:
                endianness = self.platformEndianness
            case .SetLittleEndian:
                endianness = .LittleEndian
            case .SetBigEndian:
                endianness = .BigEndian
            
            case .SetAlign:
                alignment = true
            case .UnsetAlign:
                alignment = false
            
            case .SkipByte:
                bytes.append(PAD_BYTE)
            
            case .Stop:
                if index != values.count {
                    return failure("expected \(index) items for packing, got \(values.count)")
                } else {
                    return NSData(bytes: bytes, length: bytes.count)
                }
            
            default:
                // No control ops found so pop the next value.
                if index >= values.count {
                    return failure("expected at least \(index) items for packing, got \(values.count)")
                }
                let rawValue: AnyObject = values[index++]
                
                switch op {
                    
                case .PackChar:
                    if let str = rawValue as? String {
                        let codePoint = str.utf16[0]
                        if codePoint < 128 {
                            bytes.append(UInt8(codePoint))
                        } else {
                            return failure("char format requires String of length 1")
                        }
                    } else {
                        return failure("char format requires String of length 1")
                    }
                    
                case .PackInt8:
                    if let value = rawValue as? Int {
                        if value >= -0x80 && value <= 0x7f {
                            bytes.append(UInt8(value & 0xff))
                        } else {
                            return failure("value outside valid range of Int8")
                        }
                    } else {
                        return failure("cannot convert argument to Int")
                    }
                    
                case .PackUInt8:
                    if let value = rawValue as? UInt {
                        if value > 0xff {
                            return failure("value outside valid range of UInt8")
                        } else {
                            bytes.append(UInt8(value))
                        }
                    } else {
                        return failure("cannot convert argument to UInt")
                    }
                    
                case .PackBool:
                    if let value = rawValue as? Bool {
                        if value {
                            bytes.append(UInt8(1))
                        } else {
                            bytes.append(UInt8(0))
                        }
                    } else {
                        return failure("cannot convert argument to Bool")
                    }
                    
                case .PackInt16:
                    if let value = rawValue as? Int {
                        if value >= -0x8000 && value <= 0x7fff {
                            padAlignment(2)
                            bytes.extend(value.splitBytes(endianness, size: 2))
                        } else {
                            return failure("value outside valid range of Int16")
                        }
                    } else {
                        return failure("cannot convert argument to Int")
                    }
                    
                case .PackUInt16:
                    if let value = rawValue as? UInt {
                        if value > 0xffff {
                            return failure("value outside valid range of UInt16")
                        } else {
                            padAlignment(2)
                            bytes.extend(value.splitBytes(endianness, size: 2))
                        }
                    } else {
                        return failure("cannot convert argument to UInt")
                    }
                    
                case .PackInt32:
                    if let value = rawValue as? Int {
                        if value >= -0x80000000 && value <= 0x7fffffff {
                            padAlignment(4)
                            bytes.extend(value.splitBytes(endianness, size: 4))
                        } else {
                            return failure("value outside valid range of Int32")
                        }
                    } else {
                        return failure("cannot convert argument to Int")
                    }
                    
                case .PackUInt32:
                    if let value = rawValue as? UInt {
                        if value > 0xffffffff {
                            return failure("value outside valid range of UInt32")
                        } else {
                            padAlignment(4)
                            bytes.extend(value.splitBytes(endianness, size: 4))
                        }
                    } else {
                        return failure("cannot convert argument to UInt")
                    }
                    
                case .PackInt64:
                    if let value = rawValue as? Int {
                        padAlignment(8)
                        bytes.extend(value.splitBytes(endianness, size: 8))
                    } else {
                        return failure("cannot convert argument to Int")
                    }
                    
                case .PackUInt64:
                    if let value = rawValue as? UInt {
                        padAlignment(8)
                        bytes.extend(value.splitBytes(endianness, size: 8))
                    } else {
                        return failure("cannot convert argument to UInt")
                    }
                    
                case .PackFloat, .PackDouble:
                    assert(false, "float/double unimplemented")
                    
                case .PackCString, .PackPString:
                    assert(false, "cstring/pstring unimplemented")
                    
                case .PackPointer:
                    assert(false, "pointer unimplemented")
                    
                default:
                    return failure("bad character in format")
                }

            }

        }
        
        // This is actually never reached, we exit from .Stop.
        return NSData(bytes: bytes, length: bytes.count)
    }
    
    func parseFormat(format: String, error: NSErrorPointer) -> Bool {
        
        var repeat = 0
        
        opStream.removeAll(keepCapacity: false)
        
        for c in format {
            // First test if the format string contains an integer. In that case
            // we feed it into the repeat counter and go to the next character.
            if let value = String(c).toInt() {
                repeat = repeat * 10 + value
                continue
            }
            // The next step depends on if we've accumulated a repeat count.
            if repeat == 0 {
                
                // With a repeat count of 0 we check for control characters.
                switch c {
                    
                    // Control endianness.
                case "@":
                    opStream.append(.SetNativeEndian)
                    opStream.append(.SetAlign)
                case "=":
                    opStream.append(.SetNativeEndian)
                    opStream.append(.UnsetAlign)
                case "<":
                    opStream.append(.SetLittleEndian)
                    opStream.append(.UnsetAlign)
                case ">", "!":
                    opStream.append(.SetBigEndian)
                    opStream.append(.UnsetAlign)
                    
                case " ":
                    // Whitespace is allowed between formats.
                    break
                    
                default:
                    // No control character found so set the repeat count to 1
                    // and evaluate format characters.
                    repeat = 1
                }
            }
            
            // If we have a repeat count we expect a format character.
            if repeat > 0 {
                // Add one op for each repeat count.
                for i in 0..repeat {
                    switch c {
                    case "x":       opStream.append(.SkipByte)
                    case "c":       opStream.append(.PackChar)
                    case "?":       opStream.append(.PackBool)
                    case "b":       opStream.append(.PackInt8)
                    case "B":       opStream.append(.PackUInt8)
                    case "h":       opStream.append(.PackInt16)
                    case "H":       opStream.append(.PackUInt16)
                    case "i", "l":  opStream.append(.PackInt32)
                    case "I", "L":  opStream.append(.PackUInt32)
                    case "q":       opStream.append(.PackInt64)
                    case "Q":       opStream.append(.PackUInt64)
                    case "f":       opStream.append(.PackFloat)
                    case "d":       opStream.append(.PackDouble)
                    case "s":       opStream.append(.PackCString)
                    case "p":       opStream.append(.PackPString)
                    case "P":       opStream.append(.PackPointer)
                    default:
                        if error {
                            error.memory = NSError(domain: ERROR_DOMAIN,
                                code: Error.Parsing.toRaw(),
                                userInfo: [NSLocalizedDescriptionKey: "bad character in format"])
                        }
                        return false
                    }
                }
            }
            // Reset the repeat counter.
            repeat = 0
        }
        opStream.append(.Stop)
        return true
    }
}
