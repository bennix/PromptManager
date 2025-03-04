# AI智能记账

AI智能记账是一款功能强大的个人财务管理应用，使用SwiftUI和CoreData构建，提供交易管理、财务分析和AI驱动的智能洞察。

## 功能特点

- 交易记录：轻松记录支出、收入和转账
- 预算管理：设置和跟踪各类别的预算
- 数据分析：通过图表和可视化工具分析财务状况
- AI助手：获取智能财务建议和洞察
- 小票识别：通过拍照或从相册选择小票自动提取交易信息

## 小票识别功能

应用支持通过拍照或从相册选择小票照片，自动识别并提取以下信息：

- 商家名称
- 交易金额
- 交易日期
- 消费项目明细

### 使用方法

1. 在"添加交易"页面点击"拍照识别"
2. 选择拍照或从相册选择小票照片
3. 系统会自动识别小票信息并填充到表单中
4. 检查识别结果，必要时进行修改
5. 点击"应用"将识别结果应用到交易表单
6. 完成后点击"保存"添加交易记录

## 项目设置说明

### 必要的框架

项目需要以下框架支持：

- SwiftUI
- CoreData
- Vision
- VisionKit
- PhotosUI

### 权限设置

应用需要以下权限：

- 相机访问权限：用于拍摄小票照片
- 相册访问权限：用于选择已有的小票照片

请在Xcode项目中添加相应的权限描述：

1. 打开Xcode项目
2. 选择项目 > Target > Info选项卡
3. 添加以下键值对：
   - Privacy - Camera Usage Description (NSCameraUsageDescription)
     - 值: 需要访问相机以拍摄小票照片进行识别
   - Privacy - Photo Library Usage Description (NSPhotoLibraryUsageDescription)
     - 值: 需要访问相册以选择小票照片进行识别

### 框架添加

如果项目中缺少Vision和VisionKit框架，请按以下步骤添加：

1. 在Xcode中选择项目 > Target
2. 选择"General"选项卡
3. 滚动到"Frameworks, Libraries, and Embedded Content"部分
4. 点击"+"按钮
5. 搜索并添加以下框架：
   - Vision.framework
   - VisionKit.framework

## 开发者注意事项

- 小票识别功能使用Vision框架进行文本识别
- 识别准确度取决于小票照片的质量和清晰度
- 对于复杂格式的小票可能需要手动调整识别结果
- 目前支持中文和英文小票的识别
