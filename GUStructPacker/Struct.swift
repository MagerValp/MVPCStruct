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


enum Endianness {
    case littleEndian
    case bigEndian
}

// Split a large integer into bytes.
extension Int {
    func splitBytes(endianness: Endianness, size: Int) -> UInt8[] {
        var bytes = UInt8[]()
        var shift: Int
        var step: Int
        if endianness == .littleEndian {
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
    func splitBytes(endianness: Endianness, size: Int) -> UInt8[] {
        var bytes = UInt8[]()
        var shift: Int
        var step: Int
        if endianness == .littleEndian {
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


class Struct: NSObject {
    
    //class let PAD_BYTE = UInt8(0x00)    // error: class variables not yet supported
    //class let ERROR_PACKING = -1
    
    class func platformEndianness() -> Endianness {
        return .littleEndian
    }
    
    // Pack an array of values according to the format string. Return NSData
    // or nil if there's an error.
    class func pack(format: String, values: AnyObject[], error: NSErrorPointer) -> NSData? {
        let PAD_BYTE = UInt8(0x00)
        let ERROR_PACKING = -1
        
        var bytes = UInt8[]()
        var index = 0
        var repeat = 0
        var alignment = true
        var endianness = Struct.platformEndianness()
        
        // Set error message and return nil.
        func failure(message: String) -> NSData? {
            if error {
                error.memory = NSError(domain: "se.gu.it.GUStructPacker",
                    code: ERROR_PACKING,
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
                    endianness = Struct.platformEndianness()
                    alignment = true
                case "=":
                    endianness = Struct.platformEndianness()
                    alignment = false
                case "<":
                    endianness = Endianness.littleEndian
                    alignment = false
                case ">":
                    endianness = Endianness.bigEndian
                    alignment = false
                case "!":
                    endianness = Endianness.bigEndian
                    alignment = false
                    
                case " ":
                    // Whitespace is allowed between formats.
                    break
                    
                default:
                    // No control character found so set the repeat count to 1
                    // and evaluate format characters.
                    repeat = 1
                }
            }
            
            if repeat > 0 {
                // If we have a repeat count we expect a format character.
                
                for i in 0..repeat {
                    
                    // Check if it's a pad byte.
                    if c == "x" {
                        bytes.append(PAD_BYTE)
                    } else {
                        // Otherwise we pop a value from the array.
                        if index >= values.count {
                            return failure("expected at least \(index) items for packing, got \(values.count)")
                        }
                        let rawValue: AnyObject = values[index++]
                        
                        switch c {
                            
                        case "c":
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
                            
                        case "b":
                            if let value = rawValue as? Int {
                                if value >= -0x80 && value <= 0x7f {
                                    bytes.append(UInt8(value & 0xff))
                                } else {
                                    return failure("value outside valid range of Int8")
                                }
                            } else {
                                return failure("cannot convert argument to Int")
                            }
                            
                        case "B":
                            if let value = rawValue as? UInt {
                                if value > 0xff {
                                    return failure("value outside valid range of UInt8")
                                } else {
                                    bytes.append(UInt8(value))
                                }
                            } else {
                                return failure("cannot convert argument to UInt")
                            }
                            
                        case "?":
                            if let value = rawValue as? Bool {
                                if value {
                                    bytes.append(UInt8(1))
                                } else {
                                    bytes.append(UInt8(0))
                                }
                            } else {
                                return failure("cannot convert argument to Bool")
                            }
                            
                        case "h":
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
                            
                        case "H":
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
                            
                        case "i", "l":
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
                            
                        case "I", "L":
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
                            
                        case "q":
                            if let value = rawValue as? Int {
                                padAlignment(8)
                                bytes.extend(value.splitBytes(endianness, size: 8))
                            } else {
                                return failure("cannot convert argument to Int")
                            }
                            
                        case "Q":
                            if let value = rawValue as? UInt {
                                padAlignment(8)
                                bytes.extend(value.splitBytes(endianness, size: 8))
                            } else {
                                return failure("cannot convert argument to UInt")
                            }
                            
                        case "f", "d":
                            assert(false, "float/double unimplemented")
                            
                        case "s", "p":
                            assert(false, "cstring/pstring unimplemented")
                            
                        case "P":
                            assert(false, "pointer unimplemented")
                            
                        default:
                            return failure("bad character in format")
                        }
                    }
                    
                }
            }
            // Reset the repeat counter.
            repeat = 0
        }
        
        if index != values.count {
            return failure("expected \(index) items for packing, got \(values.count)")
        }
        return NSData(bytes: bytes, length: bytes.count)
    }
    
}
