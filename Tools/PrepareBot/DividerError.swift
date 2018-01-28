//
//  Error.swift
//  DividerPackageDescription
//
//  Created by Gix on 1/21/18.
//

import Foundation

public enum DividerError: Error {
    case originalImageSourceNotFound
}

extension DividerError: LocalizedError {
    
    public var localizedDescription: String {
        switch self {
        case .originalImageSourceNotFound:
            return "in original image path no image sources."
        }
    }
}
