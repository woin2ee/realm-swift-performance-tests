//
//  RealmSwiftPerformanceTests.swift
//  RealmSwiftPerformanceTests
//
//  Created by Jaewon Yun on 2/19/24.
//

import Foundation
import Realm
import RealmSwift
import XCTest

/// Read 테스트를 위해 준비할 아이템 갯수
fileprivate let PREPARED_ITEM_COUNT = 100_000 // 변경 가능

/// 테스트 중 쿼리가 실행되는 횟수
fileprivate let QUERY_EXECUTION_COUNT = 5_000 // 변경 가능

/// 실제 테스트가 실행되는 범위. 1에서 `QUERY_EXECUTION_COUNT`까지 무작위로 섞는다.
fileprivate let TEST_SCOPE = (1...QUERY_EXECUTION_COUNT).shuffled()

final class RealmPerformanceTests: XCTestCase {
    
    var sut: Realm!
    var config: Realm.Configuration!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        self.continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        sut = nil
        config = nil
    }
    
    func test_performanceWithoutIndex_whenWrite() throws {
        // Arrange
        config = .init()
        config.fileURL?.deleteLastPathComponent()
        config.fileURL?.append(path: "RealmWriteTestsWithoutIndex")
        config.fileURL?.appendPathExtension("realm")
        
        sut = try! .init(configuration: config)
//        print(config.fileURL!)
        
        defer { // 측정 대상 보존 상태 검증
            let objects = sut.objects(Item.self)
            XCTAssertTrue(objects.isEmpty)
        }
        
        // Act
        self.measure {
            do { // 측정 대상 준비 상태 검증
                let objects = sut.objects(Item.self)
                XCTAssertTrue(objects.isEmpty)
            }
            
            TEST_SCOPE.forEach { number in
                let newItem: Item = .init(number: "\(number)")
                
                do {
                    try sut.write {
                        sut.add(newItem)
                    }
                } catch {
                    XCTFail("저장 실패.")
                }
            }
            
            do {
                try sut.write {
                    sut.deleteAll()
                }
            } catch {
                XCTFail("삭제 실패.")
            }
        }
    }
    
    func test_performanceWithIndex_whenWrite() throws {
        // Arrange
        config = .init()
        config.fileURL?.deleteLastPathComponent()
        config.fileURL?.append(path: "RealmWriteTestsWithIndex")
        config.fileURL?.appendPathExtension("realm")
        
        sut = try! .init(configuration: config)
//        print(config.fileURL!)
        
        defer { // 측정 대상 보존 상태 검증
            let objects = sut.objects(IndexingItem.self)
            XCTAssertTrue(objects.isEmpty)
        }
        
        // Act
        self.measure {
            do { // 측정 대상 준비 상태 검증
                let objects = sut.objects(IndexingItem.self)
                XCTAssertTrue(objects.isEmpty)
            }
            
            TEST_SCOPE.forEach { number in
                let newItem: IndexingItem = .init(number: "\(number)")
                
                do {
                    try sut.write {
                        sut.add(newItem)
                    }
                } catch {
                    XCTFail("저장 실패.")
                }
            }
            
            do {
                try sut.write {
                    sut.deleteAll()
                }
            } catch {
                XCTFail("삭제 실패.")
            }
        }
    }
    
    func test_performanceWithoutIndex_whenRead() throws {
        // Arrange
        config = .init()
        config.fileURL?.deleteLastPathComponent()
        config.fileURL?.append(path: "RealmReadTestsWithoutIndex")
        config.fileURL?.appendPathExtension("realm")
        
        sut = try! .init(configuration: config)
//        print(config.fileURL!)
        
        XCTAssertGreaterThanOrEqual(PREPARED_ITEM_COUNT, QUERY_EXECUTION_COUNT, "준비된 아이템 갯수가 Query 실행 횟수보다 많아야합니다.")
        
        if sut.objects(Item.self).count != PREPARED_ITEM_COUNT {
            try sut.write {
                sut.deleteAll()
                (1...PREPARED_ITEM_COUNT).forEach { number in
                    let item: Item = .init(number: "\(number)")
                    sut.add(item)
                }
            }
        }
        
        // Act
        self.measure {
            TEST_SCOPE.forEach { number in
                let objects = sut.objects(Item.self)
                let object = objects.where { $0.number.equals("\(number)") }
                XCTAssertNotNil(object)
            }
        }
    }
    
    func test_performanceWithIndex_whenRead() throws {
        // Arrange
        config = .init()
        config.fileURL?.deleteLastPathComponent()
        config.fileURL?.append(path: "RealmReadTestsWithIndex")
        config.fileURL?.appendPathExtension("realm")
        
        sut = try! .init(configuration: config)
//        print(config.fileURL!)
        
        XCTAssertGreaterThanOrEqual(PREPARED_ITEM_COUNT, QUERY_EXECUTION_COUNT, "준비된 아이템 갯수가 Query 실행 횟수보다 많아야합니다.")
        
        if sut.objects(Item.self).count != PREPARED_ITEM_COUNT {
            try sut.write {
                sut.deleteAll()
                (1...PREPARED_ITEM_COUNT).forEach { number in
                    let item: IndexingItem = .init(number: "\(number)")
                    sut.add(item)
                }
            }
        }
        
        // Act
        self.measure {
            TEST_SCOPE.forEach { number in
                let objects = sut.objects(IndexingItem.self)
                let object = objects.where { $0.number.equals("\(number)") }
                XCTAssertNotNil(object)
            }
        }
    }
}

final class Item: Object {
    
    @Persisted(primaryKey: true) var id: ObjectId = .generate()
    
    @Persisted var number: String
    
    convenience init(number: String) {
        self.init()
        self.number = number
    }
}

final class IndexingItem: Object {
    
    @Persisted(primaryKey: true) var id: ObjectId = .generate()
    
    @Persisted(indexed: true) var number: String
    
    convenience init(number: String) {
        self.init()
        self.number = number
    }
}
