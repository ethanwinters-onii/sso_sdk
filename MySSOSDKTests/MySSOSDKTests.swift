//
//  MySSOSDKTests.swift
//  MySSOSDKTests
//
//  Created by Nguyen Quyet on 12/3/26.
//

import XCTest
@testable import MySSOSDK

final class MySSOSDKTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private var storage: BaseAuthStorage!

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
        storage = BaseAuthStorage(userDefaults: userDefaults)
    }

    override func tearDownWithError() throws {
        storage.clearAll()
        userDefaults.removePersistentDomain(forName: #file)
        storage = nil
        userDefaults = nil
    }

    func testSaveAndGetValue() throws {
        storage.save("access-token", for: .accessToken)

        XCTAssertEqual(storage.getValue(for: .accessToken), "access-token")
    }

    func testRemoveValue() throws {
        storage.save("refresh-token", for: .refreshToken)

        storage.removeValue(for: .refreshToken)

        XCTAssertNil(storage.getValue(for: .refreshToken))
    }

    func testClearAll() throws {
        storage.save("access-token", for: .accessToken)
        storage.save("refresh-token", for: .refreshToken)
        storage.save("id-token", for: .idToken)
        storage.save("https://example.com/.well-known/openid-configuration", for: .discoveryURL)

        storage.clearAll()

        XCTAssertNil(storage.getValue(for: .accessToken))
        XCTAssertNil(storage.getValue(for: .refreshToken))
        XCTAssertNil(storage.getValue(for: .idToken))
        XCTAssertNil(storage.getValue(for: .discoveryURL))
    }

}
