//
//  Preferences.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Foundation

class Preferences {
    public var plans: [Plan] = []
    
    func toYaml() -> String {
        var result = "---\nplans:\n"
        for plan in plans {
            result += "-\n".indent(2)
            result += "\(plan.toYaml(indent: 4))"
        }
        result = result.trimmingCharacters(in: CharacterSet.newlines)
        return result
    }
}
