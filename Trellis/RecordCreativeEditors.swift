import PencilKit
import Observation
import SwiftUI
import UIKit

enum PencilBrushPreset: String, CaseIterable, Identifiable, Sendable {
    case chalk
    case calligraphy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chalk:
            return "粉笔"
        case .calligraphy:
            return "书法"
        }
    }

    var systemImage: String {
        switch self {
        case .chalk:
            return "pencil.and.scribble"
        case .calligraphy:
            return "pencil.tip"
        }
    }

    var inkType: PKInkingTool.InkType {
        switch self {
        case .chalk:
            return .crayon
        case .calligraphy:
            return .fountainPen
        }
    }

    var width: CGFloat {
        switch self {
        case .chalk:
            return 10
        case .calligraphy:
            return 6
        }
    }
}

struct PencilDrawingEditor: View {
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var drawing = PKDrawing()
    @State private var controller = PencilCanvasController()
    @State private var selectedBrush: PencilBrushPreset = .chalk

    private let boardColor = Color(
        red: 0.035,
        green: 0.055,
        blue: 0.045
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                brushPicker
                PencilCanvas(
                    drawing: $drawing,
                    controller: controller
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(12)
            }
            .background(boardColor)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("黑板手绘")
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
                    .disabled(drawing.strokes.isEmpty)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("撤销") {
                        controller.undo()
                    }
                    .disabled(!controller.canUndo)

                    Button("重做") {
                        controller.redo()
                    }
                    .disabled(!controller.canRedo)

                    Spacer()

                    Button("清空", role: .destructive) {
                        controller.clear()
                    }
                    .disabled(drawing.strokes.isEmpty)
                }
            }
        }
    }

    private var brushPicker: some View {
        HStack(spacing: 10) {
            ForEach(PencilBrushPreset.allCases) { preset in
                Button {
                    selectedBrush = preset
                    controller.setBrush(preset)
                } label: {
                    Label(preset.title, systemImage: preset.systemImage)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            selectedBrush == preset
                                ? Color.white.opacity(0.22)
                                : Color.white.opacity(0.08)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("黑板")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private func renderPNG() -> Data? {
        let measuredSize = controller.canvasSize
            ?? CGSize(width: 1024, height: 1024)
        let logicalSize = measuredSize.width > 0
            && measuredSize.height > 0
            ? measuredSize
            : CGSize(width: 1024, height: 1024)
        let outputSize = CGSize(width: 1024, height: 1024)
        let scale = max(
            outputSize.width / max(logicalSize.width, 1),
            outputSize.height / max(logicalSize.height, 1)
        )
        let drawingImage = drawing.image(
            from: CGRect(origin: .zero, size: logicalSize),
            scale: scale
        )
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let image = renderer.image { context in
            UIColor(
                red: 0.035,
                green: 0.055,
                blue: 0.045,
                alpha: 1
            ).setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))
            drawingImage.draw(in: CGRect(origin: .zero, size: outputSize))
        }
        return image.pngData()
    }
}

private struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let controller: PencilCanvasController

    func makeCoordinator() -> Coordinator {
        Coordinator(
            drawing: $drawing,
            controller: controller
        )
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = UIColor(
            red: 0.035,
            green: 0.055,
            blue: 0.045,
            alpha: 1
        )
        let initialTool = PKInkingTool(
            .crayon,
            color: .white,
            width: 10
        )
        canvas.tool = initialTool
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        controller.attach(canvas)

        let toolPicker = PKToolPicker()
        toolPicker.selectedTool = initialTool
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
        let controller: PencilCanvasController
        var toolPicker: PKToolPicker?

        init(
            drawing: Binding<PKDrawing>,
            controller: PencilCanvasController
        ) {
            _drawing = drawing
            self.controller = controller
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
            controller.refresh()
        }
    }
}

@MainActor
@Observable
final class PencilCanvasController {
    private weak var canvas: PKCanvasView?
    private(set) var canUndo = false
    private(set) var canRedo = false
    var canvasSize: CGSize? {
        canvas?.bounds.size
    }

    func attach(_ canvas: PKCanvasView) {
        self.canvas = canvas
        refresh()
    }

    func refresh() {
        canUndo = canvas?.undoManager?.canUndo == true
        canRedo = canvas?.undoManager?.canRedo == true
    }

    func undo() {
        canvas?.undoManager?.undo()
        refresh()
    }

    func redo() {
        canvas?.undoManager?.redo()
        refresh()
    }

    func clear() {
        guard let canvas, !canvas.drawing.strokes.isEmpty else {
            return
        }
        let previous = canvas.drawing
        canvas.undoManager?.registerUndo(
            withTarget: canvas
        ) { target in
            target.drawing = previous
        }
        canvas.drawing = PKDrawing()
        refresh()
    }

    func setBrush(_ preset: PencilBrushPreset) {
        canvas?.tool = PKInkingTool(
            preset.inkType,
            color: .white,
            width: preset.width
        )
    }
}

struct PixelSketchEditor: View {
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = PixelCanvasState()
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
                pixelControls

                GeometryReader { proxy in
                    let side = min(proxy.size.width, proxy.size.height)
                    Canvas { context, _ in
                        let gridSize = canvas.gridSize
                        let pixelSize = side / CGFloat(gridSize)
                        for index in canvas.pixels.indices {
                            let row = index / gridSize
                            let column = index % gridSize
                            let colorIndex = canvas.pixels[index]
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
                                canvas.beginStroke()
                                paint(
                                    at: value.location,
                                    side: side
                                )
                            }
                            .onEnded { _ in
                                canvas.endStroke()
                                lastPaintedIndex = nil
                            }
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
                .aspectRatio(1, contentMode: .fit)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: 6
                    ),
                    spacing: 10
                ) {
                    ForEach(palette.indices, id: \.self) { index in
                        Button {
                            canvas.selectColor(index)
                        } label: {
                            Circle()
                                .fill(Color(uiColor: palette[index]))
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selectedColorIndex == index
                                                ? Color.trellisBrass
                                                : Color.black.opacity(0.18),
                                            lineWidth: selectedColorIndex == index ? 3 : 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        canvas.selectEraser()
                    } label: {
                        Image(systemName: "eraser.fill")
                            .foregroundStyle(
                                canvas.tool == .eraser
                                    ? Color.trellisBrass
                                    : Color.trellisAsh
                            )
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("橡皮")
                }

                HStack {
                    Button("撤销") {
                        canvas.undo()
                    }
                    .disabled(!canvas.canUndo)

                    Spacer()

                    Button("清空") {
                        canvas.clear()
                    }
                    .disabled(canvas.isEmpty)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            .navigationTitle("像素画布")
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
                    .disabled(canvas.isEmpty)
                }
            }
        }
    }

    private var selectedColorIndex: Int? {
        guard case let .color(index) = canvas.tool else {
            return nil
        }
        return index
    }

    private var pixelControls: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(PixelCanvasState.allowedGridSizes, id: \.self) { size in
                    Button("\(size)×\(size)") {
                        canvas.setGridSize(size)
                    }
                }
            } label: {
                Label(
                    "网格 \(canvas.gridSize)×\(canvas.gridSize)",
                    systemImage: "square.grid.3x3"
                )
                .font(.caption.weight(.semibold))
            }

            Menu {
                ForEach(1...3, id: \.self) { size in
                    Button("\(size)×\(size) 像素") {
                        canvas.setBrushSize(size)
                    }
                }
            } label: {
                Label(
                    "笔刷 \(canvas.brushSize)×\(canvas.brushSize)",
                    systemImage: "paintbrush.pointed.fill"
                )
                .font(.caption.weight(.semibold))
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private func paint(at point: CGPoint, side: CGFloat) {
        guard point.x >= 0, point.y >= 0,
              point.x < side, point.y < side
        else {
            return
        }
        let gridSize = canvas.gridSize
        let column = min(
            gridSize - 1,
            max(0, Int(point.x / side * CGFloat(gridSize)))
        )
        let row = min(
            gridSize - 1,
            max(0, Int(point.y / side * CGFloat(gridSize)))
        )
        let index = row * gridSize + column
        guard lastPaintedIndex != index else {
            return
        }
        lastPaintedIndex = index
        canvas.paint(column: column, row: row)
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
            let gridSize = canvas.gridSize
            let pixelSize = size.width / CGFloat(gridSize)
            for index in canvas.pixels.indices {
                let colorIndex = canvas.pixels[index]
                guard colorIndex >= 0 else {
                    continue
                }
                let row = index / gridSize
                let column = index % gridSize
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

struct StickerCanvasEditor: View {
    let onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = StickerCanvasState()
    @State private var selectedCategory: StickerCategory = .emotions
    @State private var scaleBases: [UUID: Double] = [:]
    @State private var rotationBases: [UUID: Double] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categoryPicker
                    stickerPicker

                    canvasView

                    if let selectedLayer = canvas.selectedLayer {
                        layerControls(selectedLayer)
                    }

                    HStack {
                        Button("撤销") {
                            canvas.undo()
                        }
                        .disabled(!canvas.canUndo)

                        Spacer()

                        Button("删除选中", role: .destructive) {
                            canvas.deleteSelected()
                        }
                        .disabled(canvas.selectedLayerID == nil)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.trellisInk.ignoresSafeArea())
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
                    .disabled(canvas.layers.isEmpty)
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StickerCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                selectedCategory == category
                                    ? Color.trellisInk
                                    : Color.trellisAsh
                            )
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category
                                    ? Color.trellisBrass
                                    : Color.black.opacity(0.18)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var stickerPicker: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 9),
                count: 4
            ),
            spacing: 9
        ) {
            ForEach(stickersInSelectedCategory) { sticker in
                Button {
                    canvas.add(sticker)
                } label: {
                    VStack(spacing: 5) {
                        StickerGlyph(
                            sticker: sticker,
                            size: 34
                        )
                        Text(sticker.title)
                            .font(.caption2)
                            .foregroundStyle(Color.trellisAsh)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var canvasView: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Color.white

                if canvas.layers.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 34, weight: .light))
                        Text("点上方贴纸加入画布")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.black.opacity(0.35))
                }

                ForEach(canvas.layers) { layer in
                    if let sticker = StickerCatalog.definition(
                        id: layer.stickerID
                    ) {
                        StickerLayerView(
                            sticker: sticker,
                            layer: layer,
                            side: side,
                            isSelected: canvas.selectedLayerID == layer.id
                        )
                        .gesture(dragGesture(for: layer, side: side))
                        .simultaneousGesture(
                            magnificationGesture(for: layer)
                        )
                        .simultaneousGesture(
                            rotationGesture(for: layer)
                        )
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.15))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal)
    }

    private func layerControls(
        _ layer: StickerLayer
    ) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Text("大小")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)

                Slider(
                    value: Binding(
                        get: {
                            canvas.selectedLayer?.scale ?? layer.scale
                        },
                        set: {
                            canvas.scaleSelected($0)
                        }
                    ),
                    in: 0.35...3
                )
            }

            HStack(spacing: 12) {
                Text("旋转")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)

                Slider(
                    value: Binding(
                        get: {
                            canvas.selectedLayer?.rotationDegrees
                                ?? layer.rotationDegrees
                        },
                        set: {
                            canvas.rotateSelected($0)
                        }
                    ),
                    in: -180...180
                )
            }
        }
        .padding(.horizontal)
    }

    private var stickersInSelectedCategory: [StickerDefinition] {
        StickerCatalog.stickers.filter {
            $0.category == selectedCategory
        }
    }

    private func dragGesture(
        for layer: StickerLayer,
        side: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                canvas.select(layer.id)
                canvas.moveSelected(
                    x: Double(value.location.x / side),
                    y: Double(value.location.y / side)
                )
            }
    }

    private func magnificationGesture(
        for layer: StickerLayer
    ) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                canvas.select(layer.id)
                if scaleBases[layer.id] == nil {
                    scaleBases[layer.id] = layer.scale
                }
                canvas.scaleSelected(
                    (scaleBases[layer.id] ?? layer.scale)
                        * Double(value)
                )
            }
            .onEnded { _ in
                scaleBases[layer.id] = nil
            }
    }

    private func rotationGesture(
        for layer: StickerLayer
    ) -> some Gesture {
        RotationGesture()
            .onChanged { value in
                canvas.select(layer.id)
                if rotationBases[layer.id] == nil {
                    rotationBases[layer.id] = layer.rotationDegrees
                }
                canvas.rotateSelected(
                    (rotationBases[layer.id] ?? layer.rotationDegrees)
                        + value.degrees
                )
            }
            .onEnded { _ in
                rotationBases[layer.id] = nil
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

            for layer in canvas.layers {
                guard let sticker = StickerCatalog.definition(
                    id: layer.stickerID
                ) else {
                    continue
                }
                let configuration = UIImage.SymbolConfiguration(
                    pointSize: 92 * layer.scale * canvasSize.width / 340
                )
                guard let symbol = UIImage(
                    systemName: sticker.systemImage,
                    withConfiguration: configuration
                )?.withTintColor(
                    UIColor(hex: sticker.colorHex),
                    renderingMode: .alwaysOriginal
                ) else {
                    continue
                }

                context.cgContext.saveGState()
                context.cgContext.translateBy(
                    x: CGFloat(layer.positionX) * canvasSize.width,
                    y: CGFloat(layer.positionY) * canvasSize.height
                )
                context.cgContext.rotate(
                    by: CGFloat(layer.rotationDegrees * .pi / 180)
                )
                symbol.draw(
                    at: CGPoint(
                        x: -symbol.size.width / 2,
                        y: -symbol.size.height / 2
                    )
                )
                context.cgContext.restoreGState()
            }
        }
        return image.pngData()
    }
}

private struct StickerLayerView: View {
    let sticker: StickerDefinition
    let layer: StickerLayer
    let side: CGFloat
    let isSelected: Bool

    var body: some View {
        StickerGlyph(sticker: sticker, size: 72)
            .scaleEffect(layer.scale)
            .rotationEffect(.degrees(layer.rotationDegrees))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color.trellisBrass,
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [5, 4]
                            )
                        )
                        .padding(-7)
                }
            }
            .position(
                x: CGFloat(layer.positionX) * side,
                y: CGFloat(layer.positionY) * side
            )
            .accessibilityLabel(sticker.title)
    }
}

private struct StickerGlyph: View {
    let sticker: StickerDefinition
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(Color.white.opacity(0.96))
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: size * 0.08,
                    y: size * 0.04
                )

            Image(systemName: sticker.systemImage)
                .font(.system(size: size * 0.62, weight: .medium))
                .foregroundStyle(Color(uiColor: UIColor(hex: sticker.colorHex)))
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.25)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        }
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
