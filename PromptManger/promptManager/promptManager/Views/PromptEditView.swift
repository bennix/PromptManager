import SwiftUI
import AppKit

struct PromptEditView: View {
    @ObservedObject var promptManager: PromptManager
    let prompt: Prompt?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: Category = Category.writing
    @State private var selectedPurpose: Purpose = Purpose.chatbot
    @State private var keywordsText: String = ""
    @State private var showingImagePicker = false
    @State private var showingImagePreview = false
    @State private var selectedImageForPreview: GeneratedImage?
    
    @Environment(\.presentationMode) var presentationMode
    
    private var isEditing: Bool {
        prompt != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // 滚动内容
            ScrollView {
                VStack(spacing: 20) {
                    // 基本信息区域
                    basicInfoSection
                    
                    // 分类选择区域
                    categorySection
                    
                    // 用途和关键词区域
                    additionalInfoSection
                    
                    // 图像管理区域
                    if selectedPurpose.id == Purpose.imageGeneration.id {
                        imageManagementSection
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // 底部按钮
            bottomButtons
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 700, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            setupForm()
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleImageImport(result)
        }
        .sheet(isPresented: $showingImagePreview) {
            if let selectedImage = selectedImageForPreview {
                ImagePreviewView(image: selectedImage)
            }
        }
    }
    
    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "编辑提示词" : "新建提示词")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(isEditing ? "请修改提示词内容" : "请填写新提示词内容")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("取消") {
                presentationMode.wrappedValue.dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "基本信息", icon: "info.circle")
            VStack(alignment: .leading, spacing: 12) {
                // 标题输入
                VStack(alignment: .leading, spacing: 6) {
                    Label("标题", systemImage: "textformat")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextField("请输入提示词标题", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                // 内容输入
                VStack(alignment: .leading, spacing: 6) {
                    Label("内容", systemImage: "doc.text")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $content)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .frame(minHeight: 150, maxHeight: 300)
                        if content.isEmpty {
                            Text("请输入提示词内容")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "分类", icon: "folder")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(promptManager.categories, id: \.id) { category in
                    CategorySelectionView(
                        category: category,
                        isSelected: selectedCategory.id == category.id,
                        onTap: { selectedCategory = category }
                    )
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "附加信息", icon: "tag")
            VStack(alignment: .leading, spacing: 16) {
                // 用途选择
                VStack(alignment: .leading, spacing: 8) {
                    Label("用途", systemImage: "target")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Picker("用途", selection: $selectedPurpose) {
                        ForEach(promptManager.purposes, id: \.id) { purpose in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(purpose.name)
                                    .font(.body)
                                Text(purpose.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(purpose)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
                // 关键词输入
                VStack(alignment: .leading, spacing: 8) {
                    Label("关键词", systemImage: "number")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextField("请输入关键词，用逗号分隔", text: $keywordsText)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                    Text("多个关键词请用逗号分隔")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private var imageManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "生成的图像", icon: "photo")
            VStack(alignment: .leading, spacing: 12) {
                // 添加图像按钮
                Button(action: { showingImagePicker = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("添加图像")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 图像预览
                if let currentPrompt = prompt, !currentPrompt.generatedImages.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(currentPrompt.generatedImages, id: \.id) { image in
                            Button(action: {
                                selectedImageForPreview = image
                                showingImagePreview = true
                            }) {
                                if let nsImage = NSImage(data: image.imageData) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button("删除", role: .destructive) {
                                    if let currentPrompt = prompt {
                                        promptManager.removeImageFromPrompt(currentPrompt, imageId: image.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button("取消") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .keyboardShortcut(.escape, modifiers: [])
            Spacer()
            Button(isEditing ? "保存" : "创建") {
                savePrompt()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                     content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func setupForm() {
        if let prompt = prompt {
            title = prompt.title
            content = prompt.content
            selectedCategory = prompt.category
            selectedPurpose = prompt.purpose
            keywordsText = prompt.keywords.joined(separator: ", ")
        } else {
            // 设置默认值
            if let firstCategory = promptManager.categories.first {
                selectedCategory = firstCategory
            }
            if let firstPurpose = promptManager.purposes.first {
                selectedPurpose = firstPurpose
            }
        }
    }
    
    private func handleImageImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                if let imageData = try? Data(contentsOf: url),
                   let currentPrompt = prompt {
                    let fileName = url.lastPathComponent
                    promptManager.addImageToPrompt(currentPrompt, imageData: imageData, fileName: fileName)
                }
            }
        case .failure(let error):
            print("图像导入失败: \(error)")
        }
    }
    
    private func savePrompt() {
        let keywords = keywordsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let existingPrompt = prompt {
            // 更新现有提示词
            var updatedPrompt = existingPrompt
            updatedPrompt.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedPrompt.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedPrompt.category = selectedCategory
            updatedPrompt.purpose = selectedPurpose
            updatedPrompt.keywords = keywords
            
            promptManager.updatePrompt(updatedPrompt)
        } else {
            // 创建新提示词
            let newPrompt = Prompt(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                purpose: selectedPurpose,
                keywords: keywords
            )
            
            promptManager.addPrompt(newPrompt)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// 图像预览视图
struct ImagePreviewView: View {
    let image: GeneratedImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text("图像预览")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            
            if let nsImage = NSImage(data: image.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            
            if !image.description.isEmpty {
                Text(image.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// 节标题组件
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.headline)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct CategorySelectionView: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : categoryColor)
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? categoryColor : categoryColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(categoryColor, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
        switch category.color {
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
    PromptEditView(promptManager: PromptManager(), prompt: nil)
} 