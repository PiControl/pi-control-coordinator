//
//  String+path.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 10.11.24.
//

import Foundation

extension String {
    
    var lastPathComponent: String {
        let url = URL(fileURLWithPath: self)
        return url.lastPathComponent
    }
    
    var pathExtension: String {
        let url = URL(fileURLWithPath: self)
        return url.pathExtension
    }
    
    func appendingPathComponent(_ component: String) -> String {
        let url = URL(fileURLWithPath: self)
        return url.appendingPathComponent(component).path
    }
    
    func appendingPathExtension(_ pathExtension: String) -> String {
        let url = URL(fileURLWithPath: self)
        return url.appendingPathExtension(pathExtension).path
    }
    
}
