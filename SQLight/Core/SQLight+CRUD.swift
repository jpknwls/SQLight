//
//  SQLight+CRUD.swift
//  SQLight
//
//  Created by Aaron Pearce on 11/06/23.
//

import Foundation
import GRDB
import CloudKit
import os.log

public extension SQLight {

    func read<T>(_ block: (Database) throws -> T) throws -> T {
        try reader.read(block)
    }

    func read<T>(_ block: @Sendable @escaping (Database) throws -> T) async throws -> T {
        try await reader.read { db in
            try block(db)
        }
    }
    
    func write<T>(_ block: (Database) throws -> T) throws -> T{
        try database.write(block)
    }


    func create<T: SyncableRecord>(record: T) async throws {
        try await database.write { db in
            try record.insert(db)
        }

        queueSaves(for: [record])
    }
    
    func create<T: SyncableRecord>(records: [T]) async throws {
        try await database.write { db in
            try records.forEach {
                try $0.insert(db)
            }
        }
        queueSaves(for: records)
    }

    func save<T: SyncableRecord>(record: T) async throws {
        try await database.write { db in
            try record.save(db)
        }

        queueSaves(for: [record])
    }

    func save<T: SyncableRecord>(records: [T]) async throws {
        _ = try await database.write { db in
            try records.forEach {
                try $0.save(db)
            }
        }

        queueSaves(for: records)
    }

    func delete<T: SyncableRecord>(record: T) async throws {
        _ = try await database.write { db in
            try record.delete(db)
        }

        queueDeletions(for: [record])
    }

    func delete<T: SyncableRecord>(records: [T]) async throws {
        _ = try await database.write { db in
            try records.forEach {
                try $0.delete(db)
            }
        }

        queueDeletions(for: records)
    }

    private func queueSaves(for records: [any SyncableRecord]) {
        Logger.database.info("Queuing saves")
        let pendingSaves: [CKSyncEngine.PendingRecordZoneChange] = records.map { 
            .saveRecord($0.recordID)
        }
        self.syncEngine.state.add(pendingRecordZoneChanges: pendingSaves)
    }

    private func queueDeletions(for records: [any SyncableRecord]) {
        Logger.database.info("Queuing deletions")
        let pendingDeletions: [CKSyncEngine.PendingRecordZoneChange] = records.map {
            .deleteRecord($0.recordID)
        }

        self.syncEngine.state.add(pendingRecordZoneChanges: pendingDeletions)
    }

    /// Pushes all of the given record type to CloudKit
      /// This occurs regardless of changes.
      /// Sometimes used during migration for schema changes.
      func pushAll<T: HRecord>(for recordType: T.Type) throws {
          let records = try read { db in
              return try recordType.fetchAll(db)
          }

          queueSaves(for: records)
      }

    
    func sendChanges() async throws {
        try await self.syncEngine.sendChanges()
    }

    func fetchChanges() async throws {
        try await self.syncEngine.fetchChanges()
    }
}




public extension SQLight {
    
    func create<T: SyncableRecord>(record: T)  throws {
        try database.write { db in
            try record.insert(db)
        }

        queueSaves(for: [record])
    }
    
    func create<T: SyncableRecord>(records: [T])  throws {
        try  database.write { db in
            try records.forEach {
                try $0.insert(db)
            }
        }
        queueSaves(for: records)
    }

    func save<T: SyncableRecord>(record: T)  throws {
        try  database.write { db in
            try record.save(db)
        }

        queueSaves(for: [record])
    }

    func save<T: SyncableRecord>(records: [T])  throws {
        _ = try  database.write { db in
            try records.forEach {
                try $0.save(db)
            }
        }

        queueSaves(for: records)
    }

    func delete<T: SyncableRecord>(record: T)  throws {
        _ = try  database.write { db in
            try record.delete(db)
        }

        queueDeletions(for: [record])
    }

    func delete<T: SyncableRecord>(records: [T])  throws {
        _ = try  database.write { db in
            try records.forEach {
                try $0.delete(db)
            }
        }

        queueDeletions(for: records)
    }
    
    
}
