//
//  DashiAPI.swift
//  Dashi
//
//  Created by Chris Henk on 11/20/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import Foundation

// This class is a set of wrapper functions for easy use of the Dashi API

class DashiAPI {
    // Base URL to be prepended to all routes
    private static let API_ROOT = "http://api.dashidashcam.com"

    // Authenication credentials and metadata
    private static var refreshToken: String?
    private static var accessToken: String?
    private static var accessTokenExpires: Date?

    private static func authenticatedRequest(request _: URLRequest) {
    }

    static func getAllVideoMetaData() {
    }

    static func downloadVideoContent() {
    }

    static func uploadVideoMetaData(id _: String, timestamp _: String, size _: Int, length _: Int) {
    }

    static func uploadVideoContent() {
    }

    static func createAccount(name _: String, email _: String, password _: String, callback : (() -> Void)) {
        callback()
    }

    static func modifiyAccount() {
    }

    static func getAccountDetails() {
    }

    static func loginWithPassword(email _: String, password _: String, callback : (() -> Void)) {
        callback()
    }

    static func loginWithToken() {
    }

    static func logout() {
    }
}
