import Foundation
import SwiftUI

// MARK: - 提示词模型
struct Prompt: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var category: Category
    var purpose: Purpose
    var keywords: [String]
    var createdAt: Date
    var lastModified: Date
    var generatedImages: [GeneratedImage] // 新增：生成的图像
    
    init(title: String, content: String, category: Category, purpose: Purpose, keywords: [String] = [], generatedImages: [GeneratedImage] = []) {
        self.title = title
        self.content = content
        self.category = category
        self.purpose = purpose
        self.keywords = keywords
        self.createdAt = Date()
        self.lastModified = Date()
        self.generatedImages = generatedImages
    }
}

// MARK: - 生成的图像模型
struct GeneratedImage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var fileName: String
    var imageData: Data
    var createdAt: Date
    var description: String
    
    init(fileName: String, imageData: Data, description: String = "") {
        self.fileName = fileName
        self.imageData = imageData
        self.createdAt = Date()
        self.description = description
    }
}

// MARK: - 导出数据模型
struct ExportData: Codable {
    var prompts: [Prompt]
    var categories: [Category]
    var purposes: [Purpose]
    var exportDate: Date
    var version: String = "1.0"
}

// MARK: - 类别模型
struct Category: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var color: String // 存储颜色的名称
    var icon: String // SF Symbol 图标名
    
    // 预定义的分类
    static let writing = Category(name: "写作", color: "blue", icon: "pencil")
    static let coding = Category(name: "编程", color: "green", icon: "chevron.left.forwardslash.chevron.right")
    static let analysis = Category(name: "分析", color: "orange", icon: "chart.bar")
    static let creative = Category(name: "创意", color: "purple", icon: "paintbrush")
    static let business = Category(name: "商务", color: "red", icon: "briefcase")
    static let learning = Category(name: "学习", color: "pink", icon: "book")
    static let artCreation = Category(name: "艺术创作", color: "indigo", icon: "paintpalette") // 新增艺术创作分类
    
    static let defaultCategories = [writing, coding, analysis, creative, business, learning, artCreation]
}

// MARK: - 用途模型
struct Purpose: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var description: String
    
    // 预定义的用途
    static let chatbot = Purpose(name: "聊天机器人", description: "用于与AI聊天和对话")
    static let contentGeneration = Purpose(name: "内容生成", description: "生成文章、博客等内容")
    static let codeReview = Purpose(name: "代码审查", description: "审查和优化代码")
    static let translation = Purpose(name: "翻译", description: "文本翻译和本地化")
    static let summarization = Purpose(name: "总结", description: "总结长文本和文档")
    static let brainstorming = Purpose(name: "头脑风暴", description: "创意思维和想法生成")
    static let imageGeneration = Purpose(name: "影像生成", description: "生成图像和视觉内容") // 新增影像生成用途
    
    static let defaultPurposes = [chatbot, contentGeneration, codeReview, translation, summarization, brainstorming, imageGeneration]
}

// MARK: - 搜索过滤器
struct SearchFilter {
    var text: String = ""
    var category: Category?
    var purpose: Purpose?
    
    func matches(prompt: Prompt) -> Bool {
        let textMatch = text.isEmpty || 
            prompt.title.localizedCaseInsensitiveContains(text) ||
            prompt.content.localizedCaseInsensitiveContains(text) ||
            prompt.keywords.contains { $0.localizedCaseInsensitiveContains(text) }
        
        let categoryMatch = category == nil || prompt.category.id == category?.id
        let purposeMatch = purpose == nil || prompt.purpose.id == purpose?.id
        
        return textMatch && categoryMatch && purposeMatch
    }
} 