import PencilKit
import SwiftUI
import UIKit

struct PencilDrawingEditor: View {
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var drawing = PKDrawing()

    var body: some View {
        NavigationStack {
            PencilCanvas(drawing: $drawing)
                .background(Color.white)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("手绘涂鸦")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("添加") {
                            let image = drawing.image(
                                from: drawing.bounds,
                                scale: UIScreen.main.scale
                            )
                            if let data = image.pngData() {
                                onSave(data)
                                dismiss()
                            }
                        }
                        .disabled(drawing.strokes.isEmpty)
                    }
                }
        }
    }
}

private struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.delegate = context.coordinator
        canvas.drawing = drawing

        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        context.coordinator.toolPicker = toolPicker
        return canvas
    }

    func updateUIView(
        _ uiView: PKCanvasView,
        context: Context
    ) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        var toolPicker: PKToolPicker?

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}

struct PixelSketchEditor: View {
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pixels = Array(repeating: -1, count: 16 * 16)
    @State private var undoStack: [[Int]] = []
    @State private var selectedColor = 0
    @State private var lastPaintedIndex: Int?

    private let palette: [UIColor] = [
        .black,
        .white,
        UIColor(red: 0.76, green: 0.58, blue: 0.31, alpha: 1),
        UIColor(red: 0.44, green: 0.56, blue: 0.48, alpha: 1),
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemBlue,
        .systemPink,
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                GeometryReader { proxy in
                    let side = min(proxy.size.width, proxy.size.height)
                    Canvas { context, _ in
                        let pixelSize = side / 16
                        for index in pixels.indices {
                            let row = index / 16
                            let column = index % 16
                            let colorIndex = pixels[index]
                            let fill = colorIndex < 0
                                ? Color.white
                                : Color(uiColor: palette[colorIndex])
                            context.fill(
                                Path(
                                    CGRect(
                                        x: CGFloat(column) * pixelSize,
                                        y: CGFloat(row) * pixelSize,
                                        width: pixelSize,
                                        height: pixelSize
                                    )
                                ),
                                with: .color(fill)
                            )
                        }
                    }
                    .frame(width: side, height: side)
                    .overlay {
                        Rectangle()
                            .stroke(Color.black.opacity(0.35))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                paint(
                                    at: value.location,
                                    side: side
                                )
                            }
                            .onEnded { _ in
                                lastPaintedIndex = nil
                            }
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
                .aspectRatio(1, contentMode: .fit)

                HStack(spacing: 12) {
                    ForEach(palette.indices, id: \.self) { index in
                        Button {
                            selectedColor = index
                        } label: {
                            Circle()
                                .fill(Color(uiColor: palette[index]))
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selectedColor == index
                                                ? Color.trellisBrass
                                                : Color.black.opacity(0.18),
                                            lineWidth: selectedColor == index ? 3 : 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    Button("撤销") {
                        guard let previous = undoStack.popLast() else {
                            return
                        }
                        pixels = previous
                    }
                    .disabled(undoStack.isEmpty)

                    Spacer()

                    Button("清空") {
                        rememberUndo()
                        pixels = Array(repeating: -1, count: 16 * 16)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            .navigationTitle("像素涂鸦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        if let data = renderPNG() {
                            onSave(data)
                            dismiss()
                        }
                    }
                    .disabled(pixels.allSatisfy { $0 < 0 })
                }
            }
        }
    }

    private func paint(at point: CGPoint, side: CGFloat) {
        guard point.x >= 0, point.y >= 0,
              point.x < side, point.y < side
        else {
            return
        }
        let column = min(15, max(0, Int(point.x / side * 16)))
        let row = min(15, max(0, Int(point.y / side * 16)))
        let index = row * 16 + column
        guard lastPaintedIndex != index else {
            return
        }
        rememberUndo()
        lastPaintedIndex = index
        pixels[index] = selectedColor
    }

    private func rememberUndo() {
        undoStack.append(pixels)
        if undoStack.count > 30 {
            undoStack.removeFirst()
        }
    }

    private func renderPNG() -> Data? {
        let size = CGSize(width: 512, height: 512)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: format
        )
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let pixelSize = size.width / 16
            for index in pixels.indices {
                let colorIndex = pixels[index]
                guard colorIndex >= 0 else {
                    continue
                }
                let row = index / 16
                let column = index % 16
                palette[colorIndex].setFill()
                context.fill(
                    CGRect(
                        x: CGFloat(column) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                )
            }
        }
        return image.pngData()
    }
}

private struct StickerChoice: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let color: UIColor
}

struct StickerCanvasEditor: View {
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected = 0
    @State private var position = CGPoint(x: 0.5, y: 0.5)
    @State private var size: CGFloat = 120
    @State private var rotation = Angle.zero

    private let stickers: [StickerChoice] = [
        .init(id: "sun", title: "太阳", systemImage: "sun.max.fill", color: .systemOrange),
        .init(id: "cloud", title: "云", systemImage: "cloud.fill", color: .systemBlue),
        .init(id: "heart", title: "心", systemImage: "heart.fill", color: .systemPink),
        .init(id: "star", title: "星", systemImage: "star.fill", color: .systemYellow),
        .init(id: "leaf", title: "叶", systemImage: "leaf.fill", color: .systemGreen),
        .init(id: "moon", title: "月", systemImage: "moon.stars.fill", color: .systemIndigo),
        .init(id: "bolt", title: "闪电", systemImage: "bolt.fill", color: .systemOrange),
        .init(id: "drop", title: "水", systemImage: "drop.fill", color: .systemCyan),
        .init(id: "sparkle", title: "闪闪", systemImage: "sparkles", color: .systemPurple),
        .init(id: "face", title: "笑脸", systemImage: "face.smiling.inverse", color: .systemTeal),
        .init(id: "mountain", title: "山", systemImage: "mountain.2.fill", color: .brown),
        .init(id: "shoe", title: "运动", systemImage: "figure.run", color: .systemRed),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                GeometryReader { proxy in
                    let side = min(proxy.size.width, proxy.size.height)
                    ZStack {
                        Color.white
                        Image(systemName: stickers[selected].systemImage)
                            .font(.system(size: size, weight: .regular))
                            .foregroundStyle(
                                Color(uiColor: stickers[selected].color)
                            )
                            .rotationEffect(rotation)
                            .position(
                                x: position.x * side,
                                y: position.y * side
                            )
                    }
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                position = CGPoint(
                                    x: min(1, max(0, value.location.x / side)),
                                    y: min(1, max(0, value.location.y / side))
                                )
                            }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .aspectRatio(1, contentMode: .fit)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(stickers.indices, id: \.self) { index in
                            Button {
                                selected = index
                            } label: {
                                Image(systemName: stickers[index].systemImage)
                                    .font(.title2)
                                    .foregroundStyle(
                                        Color(uiColor: stickers[index].color)
                                    )
                                    .frame(width: 46, height: 46)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 16) {
                    Text("大小")
                    Slider(value: $size, in: 44...220)
                    Text("旋转")
                    Slider(
                        value: Binding(
                            get: { rotation.degrees },
                            set: { rotation = .degrees($0) }
                        ),
                        in: -180...180
                    )
                }
                .font(.caption)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("手作贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        if let data = renderPNG() {
                            onSave(data)
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func renderPNG() -> Data? {
        let canvasSize = CGSize(width: 512, height: 512)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: canvasSize,
            format: format
        )
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            let configuration = UIImage.SymbolConfiguration(
                pointSize: size * 512 / 340
            )
            guard let symbol = UIImage(
                systemName: stickers[selected].systemImage,
                withConfiguration: configuration
            )?.withTintColor(
                stickers[selected].color,
                renderingMode: .alwaysOriginal
            ) else {
                return
            }

            context.cgContext.translateBy(
                x: position.x * canvasSize.width,
                y: position.y * canvasSize.height
            )
            context.cgContext.rotate(by: CGFloat(rotation.radians))
            symbol.draw(
                at: CGPoint(
                    x: -symbol.size.width / 2,
                    y: -symbol.size.height / 2
                )
            )
        }
        return image.pngData()
    }
}
