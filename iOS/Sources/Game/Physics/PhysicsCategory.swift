struct PhysicsCategory {
    static let none: UInt32 = 0
    static let character: UInt32 = 0b1      // 1
    static let platform: UInt32 = 0b10      // 2
    static let boundary: UInt32 = 0b100     // 4
}
