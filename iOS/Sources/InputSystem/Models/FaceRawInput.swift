struct FaceRawInput: Equatable {
    /// 머리 기울기 (radians). 왼쪽 기울임(+), 오른쪽 기울임(-)
    let roll: Double

    /// 입 오므리기 (0.0 ~ 1.0)
    let mouthPucker: Double
}
