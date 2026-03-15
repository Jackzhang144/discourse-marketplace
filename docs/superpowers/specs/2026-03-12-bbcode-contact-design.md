# discourse-marketplace BBCode 联系方式设计文档

## 概述

本文档描述了如何将 discourse-marketplace 插件从使用 custom_fields 存储联系方式改为使用自定义 BBCode `[contact]`，并实现标记已解决时自动删除联系方式的功能。

## 功能需求

1. **自定义 BBCode**: 使用 `[contact]联系方式内容[/contact]` 包裹联系方式
2. **隐私显示**: 未解决时，点击按钮才显示联系方式（需达到指定 trust_level）
3. **已解决处理**: 标记已解决时删除 BBCode 并添加提示信息
4. **标题徽章**: 已解决帖子在标题旁显示绿色勾选图标
5. **编辑记录**: 删除操作保留在 Post Revisions 中

## 设置项

| 设置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `marketplace_enabled` | boolean | true | 是否启用本插件 (已存在) |
| `marketplace_enabled_categories` | category_list | [] | 启用功能的分类 (已存在) |
| `marketplace_contact_trust_level` | integer | 0 | 查看联系方式的最低 trust_level (新增) |
| `marketplace_resolved_category_id` | category | - | **(已废弃)** 标记已解决不再移动到分类 |

## 架构设计

### 文件变更

```
├── app/
│   ├── services/
│   │   └── discourse_marketplace/
│   │       └── mark_resolved.rb      # 修改：移除 custom_field 逻辑，添加 BBCode 处理
├── assets/
│   └── javascripts/
│       └── discourse/
│           ├── lib/
│           │   └── discourse-markdown/
│           │       └── contact.js    # 新增：markdown-it 扩展
│           ├── initializers/
│           │   └── extend-for-marketplace.gjs  # 修改：移除旧组件引用
│           └── components/
│               ├── marketplace-contact-button.gjs  # 新增：联系方式按钮组件
│               └── marketplace-resolved-badge.gjs  # 新增：已解决徽章组件
├── config/
│   └── settings.yml                  # 修改：添加新设置项
└── config/locales/                   # 修改：添加新本地化字符串
```

### 模块职责

#### 1. Markdown 扩展 (contact.js)

- **功能**: 解析 `[contact]...[/contact]` BBCode
- **输出**: 生成一个带有 `data-contact` 属性的占位元素
- **属性**:
  - `data-contact`: 联系方式内容（加密存储，前端解密显示）

#### 2. 前端组件 (marketplace-contact-button.gjs)

- **功能**:
  1. 检查用户 trust_level 是否达到配置要求
  2. 渲染"点击查看联系方式"按钮
  3. 点击后显示联系方式内容
- **样式**: 使用 Discourse 原生按钮样式，支持亮色/暗色主题
- **条件**:
  - 仅在 `marketplace_enabled_categories` 中的分类帖子显示
  - 仅对 trust_level >= `marketplace_contact_trust_level` 的用户显示按钮

#### 3. 已解决徽章 (marketplace-resolved-badge.gjs)

- **功能**: 在帖子标题旁显示绿色勾选图标
- **样式**: 参考 discourse-solved 插件，使用 `d-icon-check-circle` 图标
- **位置**: 帖子标题下方或标题栏

#### 4. 后端服务 (mark_resolved.rb)

- **功能**:
  1. 检查用户权限
  2. 查找帖子中的 `[contact]...[/contact]` BBCode
  3. 移除 BBCode 及内容
  4. 在帖子末尾添加提示信息
  5. 创建 Post Revision 记录
- **数据流**:
  ```
  帖子 raw 内容:
  "正文内容 [contact]13800138000[/contact] 其他内容"

  处理后:
  "正文内容

  > 此贴已标记为已解决，联系方式已隐藏

  其他内容"
  ```

## 数据流

### 标记已解决流程

```
1. 用户点击"标记已解决"按钮
2. 前端发送 POST /marketplace/mark_resolved
3. 后端 MarkResolved 服务:
   a. 验证用户权限 (can_mark_topic_resolved)
   b. 获取帖子第一篇 post (raw 内容)
   c. 使用正则匹配 [contact](.*?)[/contact]
   d. 替换为空字符串
   e. 追加提示信息块
   f. 更新 post.raw
   g. 创建 revision (自动记录 last_editor_id)
4. 前端收到成功响应
5. 刷新帖子显示
6. 标题显示已解决徽章
```

### 联系方式显示流程

```
1. 帖子渲染时，markdown-it 扩展处理 [contact] BBCode
2. 生成 <span class="contact-placeholder" data-contact="..."></span>
3. decorateCookedElement 触发
4. 检查用户 trust_level
5. 如果达到要求:
   - 渲染"查看联系方式"按钮
   - 点击后解密并显示内容
6. 如果未达到要求:
   - 不显示按钮，或显示"权限不足"
```

## 错误处理

| 场景 | 处理 |
|------|------|
| 帖子无 BBCode | 正常标记已解决，只添加提示信息 |
| 帖子有多处 BBCode | 全部移除 |
| 用户无权限 | 返回 403 错误 |
| 帖子不存在 | 返回 404 错误 |
| 更新失败 | 回滚事务，返回错误 |

## 测试策略

### 后端测试

1. `MarkResolved` 服务测试
   - 正确移除 BBCode
   - 添加提示信息
   - 创建 revision 记录
   - 权限检查

2. 设置项测试
   - 启用/禁用插件
   - trust_level 配置生效

### 前端测试

1. 按钮渲染测试
   - trust_level 达标时显示
   - trust_level 不达标时隐藏

2. 交互测试
   - 点击按钮显示联系方式
   - 暗色主题样式正确

## 国际化

### 新增本地化键

```yaml
zh_CN:
  js:
    marketplace:
      contact_button: "查看联系方式"
      contact_hidden: "此贴已标记为已解决，联系方式已隐藏"

en:
  js:
    marketplace:
      contact_button: "View Contact"
      contact_hidden: "This topic is marked as resolved, contact info has been hidden."
```

## 兼容性

- **Discourse 版本**: 3.0+
- **Ember 版本**: 兼容当前 Ember 6.x
- **浏览器**: 支持现代浏览器

## 参考文献

- [Discourse Markdown 扩展文档](https://github.com/discourse/discourse/blob/main/docs/developer-guides/docs/04-plugins/10-markdown-it-extension.md)
- [discourse-solved 插件](https://github.com/discourse/discourse-solved)
- [markdown-it 插件开发](https://github.com/markdown-it/markdown-it)
