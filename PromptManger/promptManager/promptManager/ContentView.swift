//
//  ContentView.swift
//  promptManager
//
//  Created by Nelle Rtcai on 2025/7/4.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var promptManager = PromptManager()
    @State private var selectedCategory: Category?
    @State private var selectedPurpose: Purpose?
    @State private var showingCategoryManagement = false
    @State private var showingPurposeManagement = false
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏 - 分类和用途
            sidebar
        } content: {
            // 中间栏 - 提示词列表
            PromptListView(promptManager: promptManager)
        } detail: {
            // 详细视图
            detailView
        }
        .navigationTitle("prompt_manager")
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView(promptManager: promptManager)
        }
        .sheet(isPresented: $showingPurposeManagement) {
            PurposeManagementView(promptManager: promptManager)
        }
    }
    
    private var sidebar: some View {
        List(selection: $selectedCategory) {
            Section {
                ForEach(promptManager.categories, id: \.id) { category in
                    CategorySidebarRow(
                        category: category,
                        promptCount: promptCount(for: category)
                    )
                    .tag(category)
                    .onTapGesture {
                        if selectedCategory?.id == category.id {
                            selectedCategory = nil
                            promptManager.searchFilter.category = nil
                        } else {
                            selectedCategory = category
                            promptManager.searchFilter.category = category
                        }
                    }
                }
            } header: {
                HStack {
                    Text("分类")
                    Spacer()
                    Button(action: { showingCategoryManagement = true }) {
                        Image(systemName: "gear")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
                    .help("管理分类")
                }
            }
            
            Section {
                ForEach(promptManager.purposes, id: \.id) { purpose in
                    PurposeSidebarRow(
                        purpose: purpose,
                        promptCount: promptCount(for: purpose)
                    )
                    .tag(purpose)
                    .onTapGesture {
                        if selectedPurpose?.id == purpose.id {
                            selectedPurpose = nil
                            promptManager.searchFilter.purpose = nil
                        } else {
                            selectedPurpose = purpose
                            promptManager.searchFilter.purpose = purpose
                        }
                    }
                }
            } header: {
                HStack {
                    Text("用途")
                    Spacer()
                    Button(action: { showingPurposeManagement = true }) {
                        Image(systemName: "gear")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.secondary)
                    .help("管理用途")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("prompt_manager")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("管理分类") {
                        showingCategoryManagement = true
                    }
                    
                    Button("管理用途") {
                        showingPurposeManagement = true
                    }
                    
                    Divider()
                    
                    Button("清除所有过滤器") {
                        selectedCategory = nil
                        selectedPurpose = nil
                        promptManager.clearSearch()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                } primaryAction: {
                    selectedCategory = nil
                    selectedPurpose = nil
                    promptManager.clearSearch()
                }
            }
        }
    }
    
    private var detailView: some View {
        Group {
            if let selectedPrompt = promptManager.selectedPrompt {
                PromptDetailView(promptManager: promptManager, prompt: selectedPrompt)
            } else {
                welcomeView
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("提示词管理器")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("欢迎使用提示词管理器")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Text("功能特点：")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "magnifyingglass", text: "智能搜索和过滤")
                    FeatureRow(icon: "doc.on.clipboard", text: "一键复制到剪贴板")
                    FeatureRow(icon: "folder", text: "分类和用途管理")
                    FeatureRow(icon: "globe", text: "多语言界面支持")
        }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            Text("选择一个提示词查看详细内容")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func promptCount(for category: Category) -> Int {
        return promptManager.prompts.filter { $0.category.id == category.id }.count
    }
    
    private func promptCount(for purpose: Purpose) -> Int {
        return promptManager.prompts.filter { $0.purpose.id == purpose.id }.count
    }
}

struct CategorySidebarRow: View {
    let category: Category
    let promptCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(categoryColor)
                .frame(width: 20)
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            if promptCount > 0 {
                Text("\(promptCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
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

struct PurposeSidebarRow: View {
    let purpose: Purpose
    let promptCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: "target")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(purpose.name)
                    .font(.body)
                
                Text(purpose.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if promptCount > 0 {
                Text("\(promptCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
