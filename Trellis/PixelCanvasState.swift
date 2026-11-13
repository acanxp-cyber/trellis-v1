import Foundation

enum PixelTool: Equatable, Sendable {
    case color(Int)
    case eraser
}

struct PixelCanvasState: Equatable, Sendable {
    static let allowedGridSizes = [8, 16, 24, 32, 48, 64]

    private(set) var gridSize: Int
    private(set) var brushSize = 1
    private(set) var pixels: [Int]
    private(set) var tool: PixelTool = .color(0)
    private var undoStack: [Snapshot] = []
    private var isStroking = false

    init(gridSize: Int = 16) {
        let safeGridSize = Self.allowedGridSizes.contains(gridSize)
            ? gridSize
            : 16
        self.gridSize = safeGridSize
        pixels = Array(
            repeating: -1,
            count: safeGridSize * safeGridSize
        )
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    var isEmpty: Bool {
        pixels.allSatisfy { $0 < 0 }
    }

    mutating func selectColor(_ index: Int) {
        tool = .color(index)
    }

    mutating func selectEraser() {
        tool = .eraser
    }

    mutating func setGridSize(_ size: Int) {
        guard size != gridSize,
              Self.allowedGridSizes.contains(size)
        else {
            return
        }
        rememberUndo()
        let oldGridSize = gridSize
        let oldPixels = pixels
        var resized = Array(repeating: -1, count: size * size)
        for row in 0..<size {
            for column in 0..<size {
                let oldColumn = min(
                    oldGridSize - 1,
                    column * oldGridSize / size
                )
                let oldRow = min(
                    oldGridSize - 1,
                    row * oldGridSize / size
                )
                resized[row * size + column] =
                    oldPixels[oldRow * oldGridSize + oldColumn]
            }
        }
        gridSize = size
        pixels = resized
    }

    mutating func setBrushSize(_ size: Int) {
        brushSize = min(3, max(1, size))
    }

    mutating func beginStroke() {
        guard !isStroking else {
            return
        }
        rememberUndo()
        isStroking = true
    }

    mutating func endStroke() {
        isStroking = false
    }

    mutating func paint(column: Int, row: Int) {
        guard (0..<gridSize).contains(column),
              (0..<gridSize).contains(row)
        else {
            return
        }
        if !isStroking {
            rememberUndo()
        }

        switch tool {
        case let .color(color):
            paintBlock(
                column: column,
                row: row,
                color: color
            )
        case .eraser:
            paintBlock(
                column: column,
                row: row,
                color: -1
            )
        }
    }

    mutating func colorIndex(column: Int, row: Int) -> Int {
        guard (0..<gridSize).contains(column),
              (0..<gridSize).contains(row)
        else {
            return -1
        }
        return pixels[row * gridSize + column]
    }

    mutating func undo() {
        guard let previous = undoStack.popLast() else {
            return
        }
        pixels = previous.pixels
        gridSize = previous.gridSize
        brushSize = previous.brushSize
    }

    mutating func clear() {
        guard !isEmpty else {
            return
        }
        rememberUndo()
        pixels = Array(repeating: -1, count: gridSize * gridSize)
    }

    private mutating func rememberUndo() {
        undoStack.append(
            Snapshot(
                pixels: pixels,
                gridSize: gridSize,
                brushSize: brushSize
            )
        )
        if undoStack.count > 30 {
            undoStack.removeFirst()
        }
    }

    private mutating func paintBlock(
        column: Int,
        row: Int,
        color: Int
    ) {
        let maxRow = min(gridSize - 1, row + brushSize - 1)
        let maxColumn = min(gridSize - 1, column + brushSize - 1)
        for targetRow in row...maxRow {
            for targetColumn in column...maxColumn {
                pixels[targetRow * gridSize + targetColumn] = color
            }
        }
    }

    private struct Snapshot: Equatable, Sendable {
        let pixels: [Int]
        let gridSize: Int
        let brushSize: Int
    }
}
