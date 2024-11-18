//
//  ModelV1.swift
//  pi-control-coordinator
//
//  Created by Thomas Bonk on 14.11.24.
//

import SQLite

struct ModelV1: Migration {
    
    func migrate(_ db: SQLite.Connection) async throws {
        try await withEntity(Controller.self) { d in
            try db.run(d.table().create(ifNotExists: true) { t in
                
                t.column(d.id(), primaryKey: true)
                t.column(d.controllerId())
                t.column(d.isOwner())
                t.column(d.passwordHash())
                t.column(d.salt())

            })
        }
    }

}
