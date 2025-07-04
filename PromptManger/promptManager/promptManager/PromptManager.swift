import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

class PromptManager: ObservableObject {
    @Published var prompts: [Prompt] = []
    @Published var categories: [Category] = Category.defaultCategories
    @Published var purposes: [Purpose] = Purpose.defaultPurposes
    @Published var searchFilter = SearchFilter()
    @Published var selectedPrompt: Prompt?
    
    private let userDefaults = UserDefaults.standard
    private let promptsKey = "SavedPrompts"
    private let categoriesKey = "SavedCategories"
    private let purposesKey = "SavedPurposes"
    
    init() {
        loadData()
        // 自动补全“艺术创作”分类
        if !categories.contains(where: { $0.name == "艺术创作" }) {
            categories.append(Category.artCreation)
        }
        // 自动补全“影像生成”用途
        if !purposes.contains(where: { $0.name == "影像生成" }) {
            purposes.append(Purpose.imageGeneration)
        }
        addSampleData()
    }
    
    // MARK: - 数据持久化
    private func loadData() {
        // 加载提示词
        if let data = userDefaults.data(forKey: promptsKey),
           let decodedPrompts = try? JSONDecoder().decode([Prompt].self, from: data) {
            self.prompts = decodedPrompts
        }
        
        // 加载分类
        if let data = userDefaults.data(forKey: categoriesKey),
           let decodedCategories = try? JSONDecoder().decode([Category].self, from: data) {
            self.categories = decodedCategories
        }
        
        // 加载用途
        if let data = userDefaults.data(forKey: purposesKey),
           let decodedPurposes = try? JSONDecoder().decode([Purpose].self, from: data) {
            self.purposes = decodedPurposes
        }
    }
    
    private func saveData() {
        // 保存提示词
        if let encoded = try? JSONEncoder().encode(prompts) {
            userDefaults.set(encoded, forKey: promptsKey)
        }
        
        // 保存分类
        if let encoded = try? JSONEncoder().encode(categories) {
            userDefaults.set(encoded, forKey: categoriesKey)
        }
        
        // 保存用途
        if let encoded = try? JSONEncoder().encode(purposes) {
            userDefaults.set(encoded, forKey: purposesKey)
        }
    }
    
    // MARK: - 提示词操作
    func addPrompt(_ prompt: Prompt) {
        prompts.append(prompt)
        saveData()
    }
    
    func updatePrompt(_ prompt: Prompt) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            var updatedPrompt = prompt
            updatedPrompt.lastModified = Date()
            prompts[index] = updatedPrompt
            saveData()
        }
    }
    
    func deletePrompt(_ prompt: Prompt) {
        prompts.removeAll { $0.id == prompt.id }
        if selectedPrompt?.id == prompt.id {
            selectedPrompt = nil
        }
        saveData()
    }
    
    // MARK: - 图像操作
    func addImageToPrompt(_ prompt: Prompt, imageData: Data, fileName: String, description: String = "") {
        let generatedImage = GeneratedImage(fileName: fileName, imageData: imageData, description: description)
        var updatedPrompt = prompt
        updatedPrompt.generatedImages.append(generatedImage)
        updatedPrompt.lastModified = Date()
        updatePrompt(updatedPrompt)
    }
    
    func removeImageFromPrompt(_ prompt: Prompt, imageId: UUID) {
        var updatedPrompt = prompt
        updatedPrompt.generatedImages.removeAll { $0.id == imageId }
        updatedPrompt.lastModified = Date()
        updatePrompt(updatedPrompt)
    }
    
    // MARK: - 分类操作
    func addCategory(_ category: Category) {
        categories.append(category)
        saveData()
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveData()
        }
    }
    
    func deleteCategory(_ category: Category) {
        // 找到第一个剩余的类别（排除要删除的）
        let remainingCategories = categories.filter { $0.id != category.id }
        let fallbackCategory = remainingCategories.first
        // 更新所有属于该类别的提示词
        for i in prompts.indices {
            if prompts[i].category.id == category.id, let fallback = fallbackCategory {
                prompts[i].category = fallback
            }
        }
        categories.removeAll { $0.id == category.id }
        saveData()
    }
    
    // MARK: - 用途操作
    func addPurpose(_ purpose: Purpose) {
        purposes.append(purpose)
        saveData()
    }
    
    func updatePurpose(_ purpose: Purpose) {
        if let index = purposes.firstIndex(where: { $0.id == purpose.id }) {
            purposes[index] = purpose
            saveData()
        }
    }
    
    func deletePurpose(_ purpose: Purpose) {
        // 找到第一个剩余的用途（排除要删除的）
        let remainingPurposes = purposes.filter { $0.id != purpose.id }
        let fallbackPurpose = remainingPurposes.first
        // 更新所有属于该用途的提示词
        for i in prompts.indices {
            if prompts[i].purpose.id == purpose.id, let fallback = fallbackPurpose {
                prompts[i].purpose = fallback
            }
        }
        purposes.removeAll { $0.id == purpose.id }
        saveData()
    }
    
    // MARK: - 搜索和过滤
    var filteredPrompts: [Prompt] {
        return prompts.filter { searchFilter.matches(prompt: $0) }
            .sorted { $0.lastModified > $1.lastModified }
    }
    
    func clearSearch() {
        searchFilter = SearchFilter()
    }
    
    // MARK: - 剪贴板操作
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func copyPromptToClipboard(_ prompt: Prompt) {
        copyToClipboard(prompt.content)
    }
    
    // MARK: - 导入导出功能
    func exportData(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [UTType.json]
            panel.nameFieldStringValue = "PromptManager_Export_\(Date().timeIntervalSince1970).json"
            panel.title = "导出提示词数据"
            panel.message = "选择保存位置"
            
            if panel.runModal() == .OK, let url = panel.url {
                self.performExport(to: url, completion: completion)
            }
        }
    }
    
    private func performExport(to url: URL, completion: (() -> Void)? = nil) {
        let exportData = ExportData(
            prompts: prompts,
            categories: categories,
            purposes: purposes,
            exportDate: Date()
        )
        
        do {
            guard let jsonData = try? JSONEncoder().encode(exportData) else {
                print("[导出] JSON 编码失败")
                return
            }
            try jsonData.write(to: url)
            print("[导出] JSON 数据写入成功: \(url.path)")
            
            // 创建图像文件夹
            let imagesFolder = url.deletingPathExtension().appendingPathComponent("images")
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            print("[导出] 图像文件夹创建成功: \(imagesFolder.path)")
            
            // 导出所有图像
            for prompt in prompts {
                for image in prompt.generatedImages {
                    let imageUrl = imagesFolder.appendingPathComponent(image.fileName)
                    if image.imageData.isEmpty {
                        print("[导出] 跳过空图片: \(image.fileName)")
                        continue
                    }
                    do {
                        try image.imageData.write(to: imageUrl)
                        print("[导出] 图片写入成功: \(imageUrl.lastPathComponent)")
                    } catch {
                        print("[导出] 图片写入失败: \(imageUrl.lastPathComponent) 错误: \(error)")
                    }
                }
            }
            // 写入成功后主线程回调
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        } catch {
            print("[导出] 导出失败: \(error)")
        }
    }
    
    func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.title = "导入提示词数据"
        panel.message = "选择要导入的JSON文件"
        
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let importData = try JSONDecoder().decode(ExportData.self, from: jsonData)
            
            // 导入分类和用途
            for category in importData.categories {
                if !categories.contains(where: { $0.name == category.name }) {
                    addCategory(category)
                }
            }
            
            for purpose in importData.purposes {
                if !purposes.contains(where: { $0.name == purpose.name }) {
                    addPurpose(purpose)
                }
            }
            
            // 导入提示词和图像
            let imagesFolder = url.deletingPathExtension().appendingPathComponent("images")
            
            for prompt in importData.prompts {
                var importedPrompt = prompt
                
                // 重新加载图像数据
                if FileManager.default.fileExists(atPath: imagesFolder.path) {
                    for i in importedPrompt.generatedImages.indices {
                        let imageUrl = imagesFolder.appendingPathComponent(importedPrompt.generatedImages[i].fileName)
                        if let imageData = try? Data(contentsOf: imageUrl) {
                            importedPrompt.generatedImages[i].imageData = imageData
                        }
                    }
                }
                
                addPrompt(importedPrompt)
            }
            
        } catch {
            print("导入失败: \(error)")
        }
    }
    
    // MARK: - 示例数据
    private func addSampleData() {
        guard prompts.isEmpty else { return }
        
        let samplePrompts = [
            Prompt(
                title: "代码审查助手",
                content: "请帮我审查以下代码，重点关注：\n1. 代码质量和可读性\n2. 潜在的bug和安全问题\n3. 性能优化建议\n4. 代码结构和设计模式\n\n代码：\n```\n[在此粘贴代码]\n```",
                category: .coding,
                purpose: .codeReview,
                keywords: ["代码", "审查", "优化", "bug", "安全"]
            ),
            Prompt(
                title: "文章写作助手",
                content: "请帮我写一篇关于 [主题] 的文章，要求：\n\n1. 目标读者：[描述目标读者]\n2. 文章长度：[字数要求]\n3. 写作风格：[正式/非正式/学术等]\n4. 关键信息：[需要包含的要点]\n\n请确保文章结构清晰，逻辑连贯，语言流畅。",
                category: .writing,
                purpose: .contentGeneration,
                keywords: ["写作", "文章", "内容", "创作"]
            ),
            Prompt(
                title: "翻译专家",
                content: "请将以下文本从 [源语言] 翻译为 [目标语言]，要求：\n\n1. 保持原文的语气和风格\n2. 确保专业术语的准确性\n3. 符合目标语言的表达习惯\n4. 如有文化差异，请适当调整\n\n原文：\n[在此粘贴需要翻译的文本]",
                category: .learning,
                purpose: .translation,
                keywords: ["翻译", "语言", "本地化"]
            ),
            Prompt(
                title: "创意头脑风暴",
                content: "我需要为 [项目/产品/问题] 进行创意头脑风暴。请从以下角度提供创新想法：\n\n1. 目标：[具体目标描述]\n2. 约束条件：[时间、预算、技术等限制]\n3. 目标用户：[用户群体描述]\n4. 期望效果：[希望达到的效果]\n\n请提供至少5个不同角度的创意方案，每个方案包含具体的实施建议。",
                category: .creative,
                purpose: .brainstorming,
                keywords: ["创意", "头脑风暴", "创新", "方案"]
            ),
            Prompt(
                title: "商务邮件助手",
                content: "请帮我写一封商务邮件：\n\n收件人：[姓名/职位]\n目的：[邮件目的]\n背景：[相关背景信息]\n关键信息：[需要传达的要点]\n期望回应：[希望对方做什么]\n\n请确保邮件：\n- 语气专业且礼貌\n- 结构清晰\n- 内容简洁明了\n- 包含适当的问候和结尾",
                category: .business,
                purpose: .contentGeneration,
                keywords: ["商务", "邮件", "沟通", "专业"]
            ),
            Prompt(
                title: "学习总结助手",
                content: "请帮我总结以下学习材料的核心内容：\n\n材料类型：[书籍/文章/视频/课程等]\n主题：[学习主题]\n重点关注：[需要重点关注的方面]\n\n学习材料：\n[在此粘贴学习材料或描述]\n\n请提供：\n1. 核心概念和要点\n2. 关键结论\n3. 实际应用建议\n4. 进一步学习的建议",
                category: .learning,
                purpose: .summarization,
                keywords: ["学习", "总结", "知识", "要点"]
            ),
            Prompt(
                title: "AI图像生成提示词",
                content: "请生成一张 [图像类型] 图像，要求：\n\n1. 风格：[艺术风格描述]\n2. 主题：[具体主题内容]\n3. 色彩：[色彩要求]\n4. 构图：[构图要求]\n5. 细节：[细节描述]\n\n请确保生成的图像：\n- 符合主题要求\n- 具有艺术美感\n- 细节丰富\n- 风格统一",
                category: .artCreation,
                purpose: .imageGeneration,
                keywords: ["AI", "图像生成", "艺术", "创意"]
            )
        ]
        
        for prompt in samplePrompts {
            addPrompt(prompt)
        }
    }
} 