import Foundation

class PrefetchingBlockReader: Sequence, IteratorProtocol {
    let fileHandle: FileHandle
    let blockSize: Int
    private let dispatchQueue: DispatchQueue
    private var data: Data?

    init(from fileHandle: FileHandle, ofSize blockSize: Int) {
        self.fileHandle = fileHandle
        self.blockSize = blockSize
        let globalQueue = DispatchQueue.global(qos: .userInitiated)
        dispatchQueue = DispatchQueue(label: "File prefetch queue",
                                      target: globalQueue)
        prefetch()
    }

    func next() -> Data? {
        guard let data = dispatchQueue.sync(execute: { self.data }),
            !data.isEmpty
        else {
            return nil
        }
        defer { prefetch() }
        return data
    }

    private func prefetch() {
        dispatchQueue.async {
            self.data = self.fileHandle.readData(ofLength: self.blockSize)
        }
    }
}

extension FileHandle {
    func blocks(ofSize blockSize: Int) -> PrefetchingBlockReader {
        return PrefetchingBlockReader(from: self, ofSize: blockSize)
    }
}
