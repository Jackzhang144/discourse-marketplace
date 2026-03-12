# discourse-marketplace

二手交易帖子联系方式隐私保护插件 for Discourse

## 功能

- **联系方式单独填写**: 发帖时可填写联系方式，与帖子正文分开存储
- **联系方式隐私保护**: 其他用户需点击按钮才能查看联系方式
- **一键标记已解决**: 帖子作者可点击按钮，自动将帖子移动到"已解决"分类并隐藏联系方式

## 安装

1. 将插件克隆到 Discourse 的 `plugins` 目录:

```bash
cd /path/to/discourse
git clone https://github.com/your-repo/discourse-marketplace.git plugins/discourse-marketplace
```

2. 重启 Discourse 应用

## 配置

在 Discourse 管理后台的 "插件" 设置中进行配置:

1. 启用 `marketplace_enabled`
2. 设置 `marketplace_enabled_categories` 为启用功能的分类（二手专区），支持多选
3. 设置 `marketplace_resolved_category_id` 为"已解决"分类的 ID

## 使用

1. 在配置的分类（二手专区）发帖时，会显示"联系方式"输入框
2. 其他用户查看帖子时，需要点击"查看联系方式"按钮才能看到
3. 帖子作者可以点击"标记已解决"按钮，将帖子移动到已解决分类

## 开发

### 运行测试

```bash
bundle exec rspec plugins/discourse-marketplace/spec/
```

### 目录结构

```
├── app/
│   ├── controllers/    # 控制器
│   └── services/      # 服务类
├── assets/
│   └── javascripts/   # 前端组件
├── config/
│   ├── locales/       # 国际化
│   └── settings.yml   # 设置
└── lib/              # 库文件
```

## License

MIT
