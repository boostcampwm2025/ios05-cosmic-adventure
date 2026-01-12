import Fluent
import Vapor

protocol TimestampedMigration: AsyncMigration {
    static var timestamp: Int { get }
}

enum MigrationRegistry {
    static func registerAll(in app: Application) {
        // TODO: 마이그레이션 등록 - (MigrationClass(), MigrationClass.timestamp)
        let migrations: [(migration: any AsyncMigration, timestamp: Int)] = [
        ]

        validateOrder(migrations.map(\.timestamp))
        migrations.forEach { app.migrations.add($0.migration) }
    }

    private static func validateOrder(_ timestamps: [Int]) {
        #if DEBUG
        precondition(timestamps == timestamps.sorted(), "Migration 순서가 timestamp와 일치하지 않습니다")
        #endif
    }
}
