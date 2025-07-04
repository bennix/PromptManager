import SwiftUI

struct CategoryManagementView: View {
    @ObservedObject var promptManager: PromptManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var deletingCategory: Category? = nil
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // 分类列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(promptManager.categories, id: \.id) { category in
                        CategoryRowView(
                            category: category,
                            onEdit: { editingCategory = category },
                            onDelete: {
                                deletingCategory = category
                                showDeleteAlert = true
                            }
                        )
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // 底部按钮
            bottomButtons
        }
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditSheet(
                promptManager: promptManager,
                category: nil
            )
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(
                promptManager: promptManager,
                category: category
            )
        }
        .alert(isPresented: $showDeleteAlert) {
            let promptCount = promptManager.prompts.filter { $0.category.id == deletingCategory?.id }.count
            return Alert(
                title: Text("确定要删除该分类？"),
                message: Text(promptCount > 0 ? "该分类下还有\(promptCount)条提示词，删除后这些提示词将自动归为其它分类。" : "删除后无法恢复。"),
                primaryButton: .destructive(Text("删除")) {
                    if let category = deletingCategory {
                        promptManager.deleteCategory(category)
                    }
                    deletingCategory = nil
                },
                secondaryButton: .cancel {
                    deletingCategory = nil
                }
            )
        }
    }
    
    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("分类管理")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("manage_your_categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("close") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var bottomButtons: some View {
        HStack {
            Spacer()
            Button("新增分类") {
                showingAddCategory = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct CategoryRowView: View {
    let category: Category
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 分类图标和颜色
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: category.icon)
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            // 分类信息
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                
                Text(String(format: NSLocalizedString("icon_format", comment: ""), category.icon))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 8) {
                Button("edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var categoryColor: Color {
        switch category.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
}

struct CategoryEditSheet: View {
    @ObservedObject var promptManager: PromptManager
    let category: Category?
    
    @State private var name: String = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedIcon: String = "folder"
    
    @Environment(\.presentationMode) var presentationMode
    
    private let availableColors = ["blue", "green", "orange", "purple", "red", "pink"]
    private let availableIcons = [
        "folder", "pencil", "paintbrush", "book", "briefcase", "chart.bar",
        "gear", "star", "heart", "bolt", "leaf", "flame"
    ]
    
    private var isEditing: Bool {
        category != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text(isEditing ? "编辑分类" : "新增分类")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                // 名称输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("分类名称")
                        .font(.headline)
                    
                    TextField("请输入分类名称", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 颜色选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 图标选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("icon")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? colorFromString(selectedColor) : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // 底部按钮
            HStack(spacing: 12) {
                Button("cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(isEditing ? "save" : "add") {
                    saveCategory()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .onAppear {
            setupForm()
        }
    }
    
    private func setupForm() {
        if let category = category {
            name = category.name
            selectedColor = category.color
            selectedIcon = category.icon
        }
    }
    
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingCategory = category {
            var updatedCategory = existingCategory
            updatedCategory.name = trimmedName
            updatedCategory.color = selectedColor
            updatedCategory.icon = selectedIcon
            promptManager.updateCategory(updatedCategory)
        } else {
            let newCategory = Category(name: trimmedName, color: selectedColor, icon: selectedIcon)
            promptManager.addCategory(newCategory)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    CategoryManagementView(promptManager: PromptManager())
} 