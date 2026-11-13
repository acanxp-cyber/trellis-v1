import CoreGraphics
import Foundation

enum StickerCategory: String, CaseIterable, Identifiable, Sendable {
    case emotions = "表情"
    case weather = "天气"
    case status = "状态"
    case food = "食物"
    case sports = "运动"
    case nature = "自然"

    var id: String { rawValue }
}

struct StickerDefinition: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let category: StickerCategory
    let systemImage: String
    let colorHex: String
}

enum StickerCatalog {
    static let stickers: [StickerDefinition] = [
        sticker("face.happy", "开心", .emotions, "face.smiling.inverse", "E5A84B"),
        sticker("face.laugh", "大笑", .emotions, "face.smiling", "F29D49"),
        sticker("face.calm", "平静", .emotions, "face.dashed", "7FA99B"),
        sticker("face.love", "喜欢", .emotions, "heart.circle.fill", "E46A83"),
        sticker("face.sad", "低落", .emotions, "cloud.rain.fill", "7389AE"),
        sticker("face.tired", "累了", .emotions, "zzz", "8A81A9"),
        sticker("face.surprise", "惊喜", .emotions, "exclamationmark.bubble.fill", "E28B4A"),
        sticker("face.angry", "生气", .emotions, "flame.fill", "C95E4B"),
        sticker("sun", "太阳", .weather, "sun.max.fill", "E5A84B"),
        sticker("cloud", "云", .weather, "cloud.fill", "7B9EAD"),
        sticker("rain", "下雨", .weather, "cloud.rain.fill", "648BA3"),
        sticker("storm", "雷雨", .weather, "cloud.bolt.rain.fill", "6F7E91"),
        sticker("snow", "下雪", .weather, "cloud.snow.fill", "7FA6B7"),
        sticker("wind", "有风", .weather, "wind", "84A59D"),
        sticker("rainbow", "彩虹", .weather, "rainbow", "D37C78"),
        sticker("moon", "夜晚", .weather, "moon.stars.fill", "776B9D"),
        sticker("done", "完成", .status, "checkmark.seal.fill", "6D9B73"),
        sticker("sparkle", "闪闪", .status, "sparkles", "B88D4B"),
        sticker("heart", "用心", .status, "heart.fill", "D96E83"),
        sticker("star", "重要", .status, "star.fill", "D3A94D"),
        sticker("pause", "暂停", .status, "pause.circle.fill", "8B8797"),
        sticker("flag", "里程碑", .status, "flag.fill", "C7684D"),
        sticker("bell", "提醒", .status, "bell.fill", "C58C45"),
        sticker("lock", "专注", .status, "lock.fill", "737B7D"),
        sticker("coffee", "咖啡", .food, "cup.and.saucer.fill", "A87552"),
        sticker("tea", "茶", .food, "mug.fill", "82915F"),
        sticker("apple", "苹果", .food, "apple.logo", "C85C4A"),
        sticker("cake", "甜点", .food, "birthday.cake.fill", "D88AA6"),
        sticker("bread", "面包", .food, "birthday.cake", "C99A5A"),
        sticker("noodles", "面", .food, "takeoutbag.and.cup.and.straw.fill", "C58A51"),
        sticker("water", "喝水", .food, "drop.fill", "5D9DB9"),
        sticker("leaf.food", "清淡", .food, "leaf.fill", "6E9B66"),
        sticker("run", "跑步", .sports, "figure.run", "C7654B"),
        sticker("walk", "散步", .sports, "figure.walk", "728E70"),
        sticker("yoga", "拉伸", .sports, "figure.flexibility", "8A79A5"),
        sticker("strength", "力量", .sports, "dumbbell.fill", "7A818A"),
        sticker("ball", "球类", .sports, "sportscourt.fill", "C68B48"),
        sticker("bike", "骑行", .sports, "bicycle", "6687A1"),
        sticker("swim", "游泳", .sports, "figure.pool.swim", "5E9CB0"),
        sticker("steps", "步数", .sports, "shoeprints.fill", "B47854"),
        sticker("leaf", "叶子", .nature, "leaf.fill", "6D9D70"),
        sticker("tree", "树", .nature, "tree.fill", "62845F"),
        sticker("mountain", "山", .nature, "mountain.2.fill", "857967"),
        sticker("flower", "小花", .nature, "camera.macro", "C7869F"),
        sticker("fire", "火苗", .nature, "flame.fill", "C96746"),
        sticker("wave", "水波", .nature, "water.waves", "5E98AA"),
        sticker("cloud.sun", "晴间多云", .nature, "cloud.sun.fill", "D09B50"),
        sticker("globe", "地球", .nature, "globe.asia.australia.fill", "5F8FA0"),
    ]

    static func definition(id: String) -> StickerDefinition? {
        stickers.first { $0.id == id }
    }

    private static func sticker(
        _ id: String,
        _ title: String,
        _ category: StickerCategory,
        _ systemImage: String,
        _ colorHex: String
    ) -> StickerDefinition {
        StickerDefinition(
            id: id,
            title: title,
            category: category,
            systemImage: systemImage,
            colorHex: colorHex
        )
    }
}

struct StickerLayer: Identifiable, Equatable, Sendable {
    let id: UUID
    let stickerID: String
    var positionX: Double
    var positionY: Double
    var scale: Double
    var rotationDegrees: Double

    init(
        id: UUID = UUID(),
        stickerID: String,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        scale: Double = 1,
        rotationDegrees: Double = 0
    ) {
        self.id = id
        self.stickerID = stickerID
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotationDegrees = rotationDegrees
    }
}

struct StickerCanvasState: Equatable, Sendable {
    private(set) var layers: [StickerLayer] = []
    private(set) var selectedLayerID: UUID?
    private var undoStack: [[StickerLayer]] = []

    var selectedLayer: StickerLayer? {
        guard let selectedLayerID else {
            return nil
        }
        return layers.first { $0.id == selectedLayerID }
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    mutating func add(_ sticker: StickerDefinition) {
        rememberUndo()
        let layer = StickerLayer(stickerID: sticker.id)
        layers.append(layer)
        selectedLayerID = layer.id
    }

    mutating func select(_ id: UUID) {
        selectedLayerID = id
    }

    mutating func moveSelected(x: Double, y: Double) {
        guard let index = selectedIndex else {
            return
        }
        layers[index].positionX = min(1, max(0, x))
        layers[index].positionY = min(1, max(0, y))
    }

    mutating func scaleSelected(_ scale: Double) {
        guard let index = selectedIndex else {
            return
        }
        layers[index].scale = min(3, max(0.35, scale))
    }

    mutating func rotateSelected(_ degrees: Double) {
        guard let index = selectedIndex else {
            return
        }
        layers[index].rotationDegrees = degrees
    }

    mutating func deleteSelected() {
        guard let index = selectedIndex else {
            return
        }
        rememberUndo()
        layers.remove(at: index)
        selectedLayerID = layers.last?.id
    }

    mutating func undo() {
        guard let previous = undoStack.popLast() else {
            return
        }
        layers = previous
        if !layers.contains(where: { $0.id == selectedLayerID }) {
            selectedLayerID = layers.last?.id
        }
    }

    private var selectedIndex: Int? {
        guard let selectedLayerID else {
            return nil
        }
        return layers.firstIndex { $0.id == selectedLayerID }
    }

    private mutating func rememberUndo() {
        undoStack.append(layers)
        if undoStack.count > 30 {
            undoStack.removeFirst()
        }
    }
}
