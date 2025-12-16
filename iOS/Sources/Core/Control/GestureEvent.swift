enum GestureEvent: Equatable {
    /// intensity: 0.0 ~ 1.0
    case jump(intensity: Float)
    case moveLeft(intensity: Float)
    case moveRight(intensity: Float)
}
