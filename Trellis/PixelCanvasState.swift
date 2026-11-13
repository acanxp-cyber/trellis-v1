import Foundation

enum PixelTool: Equatable, Sendable {
    case color(Int)
    case eraser
}

struct PixelCanvasState: Equatable, Sendable {
    static let gridSize = 16

    private(set) var pixels = Array(
        repeating: -1,
        count: gridSize * gridSize
    )
    private(set) var tool: PixelTool = .color(0)
    private var undoStack: [[Int]] = []
    private var isStroking = false

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
        guard (0..<Self.gridSize).contains(column),
              (0..<Self.gridSize).contains(row)
        else {
            return
        }
        if !isStroking {
            rememberUndo()
        }
        let index = row * Self.gridSize + column
        switch tool {
        case let .color(color):
            pixels[index] = color
        case .eraser:
            pixels[index] = -1
        }
    }

    mutating func colorIndex(column: Int, row: Int) -> Int {
        pixels[row * Self.gridSize + column]
    }

    mutating func undo() {
        guard let previous = undoStack.popLast() else {
            return
        }
        pixels = previous
    }

    mutating func clear() {
        guard !isEmpty else {
            return
        }
        rememberUndo()
        pixels = Array(repeating: -1, count: Self.gridSize * Self.gridSize)
    }

    private mutating func rememberUndo() {
        undoStack.append(pixels)
        if undoStack.count > 30 {
            undoStack.removeFirst()
        }
    }
}
