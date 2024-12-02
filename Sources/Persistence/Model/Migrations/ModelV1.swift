//
//  ModelV1.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 14.11.24.
//

import SQLite

struct ModelV1: Migration {
    
    func migrate(_ db: SQLite.Connection) async throws {
        
        try await withEntity(Controller.self) { c in
            try db.run(c.table().create(ifNotExists: true) { t in
                
                t.column(c.id(), primaryKey: true)
                t.column(c.controllerId())
                t.column(c.isOwner())
                t.column(c.passwordHash())
                t.column(c.salt())

            })
        }
        
        try await withEntity(Accessory.self) { a in
            
            try db.run(a.table().create(ifNotExists: true) { t in
                
                t.column(a.id(), primaryKey: true)
                t.column(a.name())
                t.column(a.authenticationMethod())
                
            })
            
        }
        
        try await withEntity(Device.self) { d in
            
            try db.run(d.table().create(ifNotExists: true) { t in
                
                t.column(d.id(), primaryKey: true)
                t.column(d.name())
                t.column(d.accesoryId())
                t.foreignKey(d.accesoryId(), references: Accessory.table(), Accessory.id(), delete: .setNull)
                
            })
            
        }
        
    }

}
