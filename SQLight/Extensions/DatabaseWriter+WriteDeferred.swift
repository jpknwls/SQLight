//
//  File.swift
//  SQLight
//
//  Created by John Knowles on 1/3/25.
//

import Foundation
import GRDB
///
extension DatabaseWriter {
    func writeWithDeferredForeignKeys(_ updates: (Database) throws -> Void) throws {
        try writeWithoutTransaction { db in
            // Disable foreign keys
            try db.execute(sql: "PRAGMA foreign_keys = OFF");
            do {
                // Perform updates in a transaction
                try db.inTransaction {
                    try updates(db)
                    return .commit
                }
                // Re-enable foreign keys
                try db.execute(sql: "PRAGMA foreign_keys = ON");
            } catch {
                // Re-enable foreign keys and rethrow
                try db.execute(sql: "PRAGMA foreign_keys = ON");
                throw error
            }
        }
    }
}
