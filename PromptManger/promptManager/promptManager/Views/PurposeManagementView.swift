import SwiftUI

struct PurposeManagementView: View {
    @ObservedObject var promptManager: PromptManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddPurpose = false
    @State private var editingPurpose: Purpose?
    @State private var deletingPurpose: Purpose? = nil
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            titleBar
            
            Divider()
            
            // 用途列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(promptManager.purposes, id: \.id) { purpose in
                        PurposeRowView(
                            purpose: purpose,
                            onEdit: { editingPurpose = purpose },
                            onDelete: {
                                deletingPurpose = purpose
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
        .sheet(isPresented: $showingAddPurpose) {
            PurposeEditSheet(
                promptManager: promptManager,
                purpose: nil
            )
        }
        .sheet(item: $editingPurpose) { purpose in
            PurposeEditSheet(
                promptManager: promptManager,
                purpose: purpose
            )
        }
        .alert(isPresented: $showDeleteAlert) {
            let promptCount = promptManager.prompts.filter { $0.purpose.id == deletingPurpose?.id }.count
            return Alert(
                title: Text("确定要删除该用途？"),
                message: Text(promptCount > 0 ? "该用途下还有\(promptCount)条提示词，删除后这些提示词将自动归为其它用途。" : "删除后无法恢复。"),
                primaryButton: .destructive(Text("删除")) {
                    if let purpose = deletingPurpose {
                        promptManager.deletePurpose(purpose)
                    }
                    deletingPurpose = nil
                },
                secondaryButton: .cancel {
                    deletingPurpose = nil
                }
            )
        }
    }
    
    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("用途管理")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("管理您的提示词用途")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var bottomButtons: some View {
        HStack {
            Spacer()
            
            Button("添加用途") {
                showingAddPurpose = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct PurposeRowView: View {
    let purpose: Purpose
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 用途图标
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "target")
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            // 用途信息
            VStack(alignment: .leading, spacing: 4) {
                Text(purpose.name)
                    .font(.headline)
                
                Text(purpose.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 8) {
                Button("编辑") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("删除") {
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
}

struct PurposeEditSheet: View {
    @ObservedObject var promptManager: PromptManager
    let purpose: Purpose?
    
    @State private var name: String = ""
    @State private var description: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    private var isEditing: Bool {
        purpose != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text(isEditing ? "编辑用途" : "添加用途")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                // 名称输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("用途名称")
                        .font(.headline)
                    
                    TextField("输入用途名称", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 描述输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("用途描述")
                        .font(.headline)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $description)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .frame(minHeight: 80, maxHeight: 120)
                        
                        if description.isEmpty {
                            Text("输入用途描述...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // 底部按钮
            HStack(spacing: 12) {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(isEditing ? "保存" : "添加") {
                    savePurpose()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .onAppear {
            setupForm()
        }
    }
    
    private func setupForm() {
        if let purpose = purpose {
            name = purpose.name
            description = purpose.description
        }
    }
    
    private func savePurpose() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingPurpose = purpose {
            var updatedPurpose = existingPurpose
            updatedPurpose.name = trimmedName
            updatedPurpose.description = trimmedDescription
            promptManager.updatePurpose(updatedPurpose)
        } else {
            let newPurpose = Purpose(name: trimmedName, description: trimmedDescription)
            promptManager.addPurpose(newPurpose)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    PurposeManagementView(promptManager: PromptManager())
} 