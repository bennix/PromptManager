import SwiftUI

struct PromptDetailView: View {
    @ObservedObject var promptManager: PromptManager
    let prompt: Prompt
    @State private var showingEditPrompt = false
    @State private var showCopiedAlert = false
    @State private var showingImagePreview = false
    @State private var selectedImageForPreview: GeneratedImage?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和基本信息
                headerSection
                
                // 内容区域
                contentSection
                
                // 图像区域（如果有图像）
                if !prompt.generatedImages.isEmpty {
                    imagesSection
                }
                
                // 分类和用途信息
                categoryAndPurposeSection
                
                // 关键词
                keywordsSection
                
                // 时间信息
                timeInfoSection
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(prompt.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("复制到剪贴板") {
                    promptManager.copyPromptToClipboard(prompt)
                    showCopiedAlert = true
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("编辑提示词") {
                    showingEditPrompt = true
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingEditPrompt) {
            PromptEditView(promptManager: promptManager, prompt: prompt)
        }
        .sheet(item: $selectedImageForPreview) { image in
            ImagePreviewView(image: image)
        }
        .alert("已复制", isPresented: $showCopiedAlert) {
            Button("确定") { }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .lineLimit(3)
            
            HStack(spacing: 16) {
                Button("复制到剪贴板") {
                    promptManager.copyPromptToClipboard(prompt)
                    showCopiedAlert = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("编辑提示词") {
                    showingEditPrompt = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("内容")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(prompt.content)
                .font(.body)
                .lineSpacing(4)
                .textSelection(.enabled)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.textBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
    }
    
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生成的图像")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 12)
            ], spacing: 12) {
                ForEach(prompt.generatedImages, id: \.id) { image in
                    Button(action: {
                        selectedImageForPreview = image
                        showingImagePreview = true
                    }) {
                        VStack(spacing: 8) {
                            if let nsImage = NSImage(data: image.imageData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            Text(image.fileName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("删除", role: .destructive) {
                            promptManager.removeImageFromPrompt(prompt, imageId: image.id)
                        }
                    }
                }
            }
        }
    }
    
    private var categoryAndPurposeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分类信息
            VStack(alignment: .leading, spacing: 8) {
                Text("分类")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Image(systemName: prompt.category.icon)
                        .font(.title2)
                        .foregroundColor(categoryColor(prompt.category.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prompt.category.name)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(categoryColor(prompt.category.color).opacity(0.1))
                )
            }
            
            // 用途信息
            VStack(alignment: .leading, spacing: 8) {
                Text("用途")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt.purpose.name)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text(prompt.purpose.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
    }
    
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关键词")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if prompt.keywords.isEmpty {
                Text("无关键词")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(prompt.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .foregroundColor(.blue)
                            .font(.body)
                    }
                }
            }
        }
    }
    
    private var timeInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间信息")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("创建时间")
                        .foregroundColor(.secondary)
                    Text(prompt.createdAt, style: .date)
                    Text(prompt.createdAt, style: .time)
                }
                
                HStack {
                    Text("最后修改")
                        .foregroundColor(.secondary)
                    Text(prompt.lastModified, style: .relative)
                }
            }
            .font(.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func categoryColor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

#Preview {
    let promptManager = PromptManager()
    let samplePrompt = Prompt(
        title: "代码审查助手",
        content: "请帮我审查以下代码，重点关注：\n1. 代码质量和可读性\n2. 潜在的bug和安全问题\n3. 性能优化建议\n4. 代码结构和设计模式",
        category: .coding,
        purpose: .codeReview,
        keywords: ["代码", "审查", "优化", "bug", "安全"]
    )
    
    return PromptDetailView(promptManager: promptManager, prompt: samplePrompt)
} 