import CoreGraphics

enum GameConfig {
    enum Physics {
        static let gravity = CGVector(dx: 0, dy: -9.8)
        static let characterRadius: CGFloat = 25.0
        static let characterFriction: CGFloat = 0.2
        static let characterRestitution: CGFloat = 0.0
        static let minJumpImpulse: CGFloat = 60.0
        static let maxJumpImpulse: CGFloat = 120.0
        static let maxJumpCount: Int = 2
        static let minMoveSpeed: CGFloat = 50.0
        static let maxMoveSpeed: CGFloat = 175.0

        /// 입력이 없을 때 감속(지상)
        static let groundDeceleration: CGFloat = 0.85

        /// 입력이 없을 때 감속(공중) - 관성 유지
        static let airDeceleration: CGFloat = 0.98

        static let idleMoveStopThreshold: CGFloat = 5.0
    }

    enum Platform {
        static let size = CGSize(width: 100, height: 20)
        static let verticalSpacing: CGFloat = 120.0
        static let horizontalSpacing: CGFloat = 100.0
    }
}
