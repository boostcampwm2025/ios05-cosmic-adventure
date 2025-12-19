protocol InputMapperProtocol {
    associatedtype Raw

    func map(_ raw: Raw) -> InputSnapshot
}
