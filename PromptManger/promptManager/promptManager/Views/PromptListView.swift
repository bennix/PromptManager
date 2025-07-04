import SwiftUI

struct PromptListView: View {
    @ObservedObject var promptManager: PromptManager
    @State private var showingAddPrompt = false
    @State private var promptToEdit: Prompt?
    @State private var showCopiedAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 搜索和过滤栏
            searchAndFilterBar
            
            // 提示词列表
            if promptManager.filteredPrompts.isEmpty {
                emptyStateView
            } else {
                promptsList
            }
        }
        .sheet(isPresented: $showingAddPrompt) {
            PromptEditView(promptManager: promptManager, prompt: nil)
        }
        .sheet(item: $promptToEdit) { prompt in
            PromptEditView(promptManager: promptManager, prompt: prompt)
        }
        .alert("已复制", isPresented: $showCopiedAlert) {
            Button("好的") { }
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("search_prompts", text: $promptManager.searchFilter.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !promptManager.searchFilter.text.isEmpty {
                    Button(action: { promptManager.searchFilter.text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // 过滤器
            HStack {
                // 分类过滤
                Picker("category", selection: $promptManager.searchFilter.category) {
                    Text("全部分类").tag(Category?.none)
                    ForEach(promptManager.categories, id: \.id) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text("分类")
                        }.tag(Category?.some(category))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                
                // 用途过滤
                Picker("purpose", selection: $promptManager.searchFilter.purpose) {
                    Text("全部用途").tag(Purpose?.none)
                    ForEach(promptManager.purposes, id: \.id) { purpose in
                        Text(purpose.name).tag(Purpose?.some(purpose))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                
                // 清除过滤器按钮
                if promptManager.searchFilter.category != nil || promptManager.searchFilter.purpose != nil {
                    Button("清除过滤器") {
                        promptManager.clearSearch()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("未找到提示词")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button("新建提示词") {
                showingAddPrompt = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var promptsList: some View {
        List(promptManager.filteredPrompts, id: \.id, selection: $promptManager.selectedPrompt) { prompt in
            PromptRowView(
                prompt: prompt,
                onCopy: {
                    promptManager.copyPromptToClipboard(prompt)
                    showCopiedAlert = true
                },
                onEdit: {
                    promptToEdit = prompt
                },
                onDelete: {
                    promptManager.deletePrompt(prompt)
                }
            )
            .tag(prompt)
        }
        .listStyle(PlainListStyle())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("新建提示词") {
                    showingAddPrompt = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct PromptRowView: View {
    let prompt: Prompt
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题和操作按钮
            HStack {
                Text(prompt.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 4) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("复制到剪贴板")
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("编辑提示词")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.red)
                    .help("删除提示词")
                }
            }
            
            // 内容预览
            Text(prompt.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 图像预览
            if !prompt.generatedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(prompt.generatedImages.prefix(3), id: \.id) { image in
                            if let nsImage = NSImage(data: image.imageData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        if prompt.generatedImages.count > 3 {
                            Text("+\(prompt.generatedImages.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // 分类和用途标签
            HStack {
                // 分类标签
                HStack(spacing: 4) {
                    Image(systemName: prompt.category.icon)
                    Text(prompt.category.name)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(categoryColor(prompt.category.color).opacity(0.2))
                .foregroundColor(categoryColor(prompt.category.color))
                .cornerRadius(4)
                .font(.caption)
                
                // 用途标签
                Text(prompt.purpose.name)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(4)
                    .font(.caption)
                
                Spacer()
                
                // 时间戳
                Text(prompt.lastModified, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 关键词
            if !prompt.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(prompt.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.vertical, 4)
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
    PromptListView(promptManager: PromptManager())
} 