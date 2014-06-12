//
//  GUStructPackerTests.swift
//  GUStructPackerTests
//
//  Created by Pelle on 2014-06-12.
//  Copyright (c) 2014 Göteborgs universitet. All rights reserved.
//

import XCTest
import GUStructPacker


class GUStructPackerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHello() {
        let facit = "Hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        var error: NSError?
        
        if let result = Struct.pack("ccccc", data: ["H", "e", "l", "l", "o"], error: &error) {
            XCTAssertEqual(result, facit)
        } else {
            XCTFail("result is nil")
        }
        if let result = Struct.pack("5c", data: ["H", "e", "l", "l", "o"], error: &error) {
            XCTAssertEqual(result, facit)
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testInts() {
        var error: NSError?
        let signedFacit = NSData(bytes: [0xff, 0xfe, 0xff, 0xfd, 0xff, 0xff, 0xff, 0xfc, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff] as UInt8[], length: 15)
        if let result = Struct.pack("<bhiq", data: [-1, -2, -3, -4], error: &error) {
            XCTAssertEqual(signedFacit, result)
        } else {
            XCTFail("result is nil")
        }
        let unsignedFacit = NSData(bytes: [0x01, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as UInt8[], length: 15)
        if let result = Struct.pack("<BHIQ", data: [1, 2, 3, 4], error: &error) {
            println("Unsigned result: \(result)")
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testAlignment() {
        // This test will fail on bigendian platforms.
        var error: NSError?
        
        let signedFacit16 = NSData(bytes: [0x01, 0x00, 0x02, 0x00] as UInt8[], length: 4)
        if let result = Struct.pack("@BH", data: [1, 2], error: &error) {
            XCTAssertEqual(signedFacit16, result)
        } else {
            XCTFail("result is nil")
        }
        
        let signedFacit32 = NSData(bytes: [0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00] as UInt8[], length: 8)
        if let result = Struct.pack("@BI", data: [1, 2], error: &error) {
            XCTAssertEqual(signedFacit32, result)
        } else {
            XCTFail("result is nil")
        }
        
        let signedFacit64 = NSData(bytes: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as UInt8[], length: 16)
        if let result = Struct.pack("@BQ", data: [1, 2], error: &error) {
            XCTAssertEqual(signedFacit64, result)
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testBigEndian() {
        var error: NSError?
        
        let facit = NSData(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e] as UInt8[], length: 14)
        
        if let result = Struct.pack(">HIQ", data: [0x0102, 0x03040506, 0x0708090a0b0c0d0e], error: &error) {
            XCTAssertEqual(facit, result)
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testBadArgs() {
        var error: NSError?
        
//        if let result = Struct.pack("10c", data: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], error: &error) {
//            XCTFail("result should be nil")
//        }
//        if let result = Struct.pack("10c", data: [1, 2, 3, 4, 5, 6, 7, 8, 9], error: &error) {
//            XCTFail("result should be nil")
//        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
