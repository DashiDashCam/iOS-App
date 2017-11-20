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
    private static var refreshToken: String? = nil;
    private static var accessToken: String? = nil;
    private static var accessTokenExpires: Date? = nil;
    
    private static func authenticatedRequest(request: URLRequest) {
        
    }
    
    static func getAllVideoMetaData() {
        
    }
    
    static func downloadVideoContent() {
        
    }
    
    static func uploadVideoMetaData(id: String, timestamp: String, size: Int, length: Int) {
        
    }
    
    static func uploadVideoContent() {
        
    }
    
    static func createAccount() {
        
    }
    
    static func modifiyAccount() {
        
    }
    
    static func getAccountDetails() {
        
    }
    
    static func loginWithPassword() {
        
    }
    
    static func loginWithToken() {

    }
    
    static func logout() {
        
    }
}
