//
//  Error.swift
//  Preprocessing
//
//  Created by Gix on 1/24/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation

public enum PreprocessError: Error {
    case notFound
    case inline(Error)
    case abort(String)
}
