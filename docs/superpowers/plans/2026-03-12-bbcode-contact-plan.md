# BBCode 联系方式实现计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 discourse-marketplace 插件从使用 custom_fields 存储联系方式改为使用自定义 BBCode `[contact]`，并实现标记已解决时自动删除联系方式的功能。

**Architecture:** 使用 markdown-it 扩展解析 BBCode，前端通过 decorateCookedElement 处理显示逻辑，后端使用 Post Revisions 系统更新帖子内容并保留编辑记录。

**Tech Stack:** Ruby (Discourse 插件), Ember/JavaScript (前端), markdown-it

---

## 文件变更概览

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| Modify | `config/settings.yml` | 移除 resolved_category_id，添加 trust_level |
| Modify | `config/locales/server.en.yml` | 添加本地化字符串 |
| Modify | `config/locales/server.zh_CN.yml` | 添加本地化字符串 |
| Modify | `app/services/discourse_marketplace/mark_resolved.rb` | 移除分类更新，添加 BBCode 处理 |
| Create | `assets/javascripts/discourse/lib/discourse-markdown/contact.js` | markdown-it 扩展 |
| Modify | `assets/javascripts/discourse/initializers/extend-for-marketplace.gjs` | 移除旧组件，注册新逻辑 |
| Modify | `assets/javascripts/discourse/components/marketplace-mark-resolved-button.gjs` | 调整按钮逻辑 |
| Modify | `lib/discourse_marketplace/guardian_extensions.rb` | 移除/调整权限方法 |

---

## Chunk 1: 后端设置项和本地化

### Task 1: 修改 settings.yml

**Files:**
- Modify: `config/settings.yml`

- [ ] **Step 1: 读取并修改 settings.yml**

将 `marketplace_resolved_category_id` 移除（或保留但标记为 deprecated），添加 `marketplace_contact_trust_level`：

```yaml
marketplace_enabled:
  type: boolean
  default: true
  client: true

marketplace_enabled_categories:
  type: category_list
  default: ""
  client: true
  description: "启用隐藏联系方式开关功能的分类"

marketplace_contact_trust_level:
  type: integer
  default: 0
  client: true
  description: "查看联系方式的最低 trust_level"
```

- [ ] **Step 2: 提交更改**

```bash
git add config/settings.yml
git commit -m "refactor: 移除 resolved_category_id，添加 trust_level 设置"
```

---

### Task 2: 添加本地化字符串

**Files:**
- Modify: `config/locales/server.en.yml`
- Modify: `config/locales/server.zh_CN.yml`

- [ ] **Step 1: 添加英文本地化**

在 `server.en.yml` 中添加：

```yaml
en:
  site_settings:
    marketplace_contact_trust_level: "Minimum trust level to view contact info"
```

- [ ] **Step 2: 添加中文本地化**

在 `server.zh_CN.yml` 中添加：

```yaml
zh_CN:
  site_settings:
    marketplace_contact_trust_level: "查看联系方式的最低 trust_level"
```

- [ ] **Step 3: 提交更改**

```bash
git add config/locales/
git commit -m "i18n: 添加 trust_level 本地化字符串"
```

---

## Chunk 2: 后端服务逻辑

### Task 3: 修改 MarkResolved 服务

**Files:**
- Modify: `app/services/discourse_marketplace/mark_resolved.rb`

- [ ] **Step 1: 创建测试文件**

创建 `spec/services/discourse_marketplace/mark_resolved_spec.rb`：

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseMarketplace::MarkResolved do
  describe ".call" do
    fab!(:topic) { Fabricate(:topic) }
    fab!(:post) { Fabricate(:post, topic: topic, raw: "原始内容 [contact]13800138000[/contact] 更多内容") }
    fab!(:user) { topic.user }

    before do
      SiteSetting.marketplace_enabled = true
      SiteSetting.marketplace_enabled_categories = [topic.category_id]
    end

    context "当用户有权限时" do
      it "移除 BBCode 并添加提示信息" do
        result = described_class.call(
          params: { topic_id: topic.id },
          guardian: Guardian.new(user)
        )

        post.reload
        expect(post.raw).not_to include("[contact]")
        expect(post.raw).not_to include("13800138000")
        expect(post.raw).to include("已标记为已解决")
      end

      it "创建 revision 记录" do
        expect {
          described_class.call(
            params: { topic_id: topic.id },
            guardian: Guardian.new(user)
          )
        }.to change { post.revisions.count }.by(1)
      end
    end
  end
end
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /path/to/discourse && bundle exec rspec spec/services/discourse_marketplace/mark_resolved_spec.rb
# 预期: 失败 (功能未实现)
```

- [ ] **Step 3: 实现 MarkResolved 服务**

```ruby
# frozen_string_literal: true

module DiscourseMarketplace
  class MarkResolved
    include Service::Base

    params do
      attribute :topic_id, :integer
      validates :topic_id, presence: true
    end

    model :topic

    policy :can_mark_resolved

    step :remove_contact_bbcode
    step :publish_event
  end

  private

  def can_mark_resolved(topic:, guardian:)
    return false if !SiteSetting.marketplace_enabled
    return false if !topic.category_id.in?(SiteSetting.marketplace_enabled_categories.map(&:to_i))
    guardian.can_mark_topic_resolved?(topic)
  end

  def remove_contact_bbcode(topic:, guardian:)
    post = topic.ordered_posts.first
    return if post.blank?

    raw = post.raw
    # 移除 [contact]...[/contact] BBCode
    new_raw = raw.gsub(/\[contact\](.*?)\[\/contact\]/mi, "")

    # 如果有内容被移除，添加提示信息
    if new_raw != raw
      # 清理多余的空白
      new_raw = new_raw.squeeze("\n").strip
      # 添加提示块
      hint_text = I18n.t("marketplace.contact_hidden")
      new_raw = "#{new_raw}\n\n> #{hint_text}"
    end

    # 更新帖子
    post.update!(raw: new_raw, last_editor_id: guardian.user.id)
  end

  def publish_event(topic:)
    DiscourseEvent.trigger(:marketplace_topic_resolved, topic)
  end
end
```

- [ ] **Step 4: 添加本地化键**

在 `server.en.yml` 和 `server.zh_CN.yml` 中添加：

```yaml
en:
  marketplace:
    contact_hidden: "此贴已标记为已解决，联系方式已隐藏"

zh_CN:
  marketplace:
    contact_hidden: "此贴已标记为已解决，联系方式已隐藏"
```

- [ ] **Step 5: 运行测试验证通过**

```bash
cd /path/to/discourse && bundle exec rspec spec/services/discourse_marketplace/mark_resolved_spec.rb
# 预期: 通过
```

- [ ] **Step 6: 提交更改**

```bash
git add app/services/ config/locales/
git commit -m "feat: 使用 BBCode 存储联系方式，标记已解决时自动删除"
```

---

## Chunk 3: 前端 Markdown 扩展

### Task 4: 创建 markdown-it 扩展

**Files:**
- Create: `assets/javascripts/discourse/lib/discourse-markdown/contact.js`

- [ ] **Step 1: 创建 markdown-it 扩展**

```javascript
import { escape } from "pretty-text/sanitizer";

export function setup(helper) {
  helper.registerOptions((opts, siteSettings) => {
    opts.features["contact"] = !!siteSettings.marketplace_enabled;
  });

  // 注册自定义 BBCode [contact]
  helper.registerPlugin((md) => {
    md.core.ruler.push("contact_bbcode", (state) => {
      const tokens = state.tokens;
      for (let i = 0; i < tokens.length; i++) {
        if (tokens[i].type === "inline") {
          processInlineContact(tokens[i].children, state);
        }
      }
    });
  });
}

function processInlineContact(tokens, state) {
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token.type === "text") {
      const content = token.content;
      // 匹配 [contact]...[/contact]
      const regex = /\[contact\]([\s\S]*?)\[\/contact\]/gi;
      let match;
      let lastIndex = 0;
      const newTokens = [];

      while ((match = regex.exec(content)) !== null) {
        // 添加匹配前的文本
        if (match.index > lastIndex) {
          const textToken = new state.Token("text", "", 0);
          textToken.content = content.slice(lastIndex, match.index);
          newTokens.push(textToken);
        }

        // 创建占位符 token
        const contactToken = new state.Token("contact_open", "span", 1);
        contactToken.attrs = [
          ["class", "contact-placeholder"],
          ["data-contact", escape(match[1].trim())]
        ];

        const contactContentToken = new state.Token("text", "", 0);
        contactContentToken.content = match[1].trim();

        const contactCloseToken = new state.Token("contact_close", "span", -1);

        newTokens.push(contactToken, contactContentToken, contactCloseToken);

        lastIndex = regex.lastIndex;
      }

      // 添加剩余文本
      if (lastIndex < content.length) {
        const textToken = new state.Token("text", "", 0);
        textToken.content = content.slice(lastIndex);
        newTokens.push(textToken);
      }

      if (newTokens.length > 0) {
        // 替换原始 token
        tokens.splice(i, 1, ...newTokens);
        i += newTokens.length - 1;
      }
    }
  }
}
```

- [ ] **Step 2: 提交更改**

```bash
git add assets/javascripts/discourse/lib/discourse-markdown/contact.js
git commit -m "feat: 添加 contact BBCode markdown-it 扩展"
```

---

## Chunk 4: 前端组件和初始化器

### Task 5: 修改初始化器和组件

**Files:**
- Modify: `assets/javascripts/discourse/initializers/extend-for-marketplace.gjs`
- Modify: `assets/javascripts/discourse/components/marketplace-mark-resolved-button.gjs`

- [ ] **Step 1: 修改 extend-for-marketplace.gjs**

```javascript
import { withPluginApi } from "discourse/lib/plugin-api";
import MarketplaceMarkResolvedButton from "../components/marketplace-mark-resolved-button";
import { registerTopicFooterButton } from "discourse/lib/register-topic-footer-button";

function initializeWithApi(api) {
  customizeTopicFooter(api);
  addDecorators(api);
}

function customizeTopicFooter(api) {
  api.registerValueTransformer(
    "topic-footer-buttons",
    ({ value: dag, context: { topic } }) => {
      if (!topic) {
        return;
      }

      const canMarkResolved = topic.can_mark_topic_resolved;

      if (canMarkResolved) {
        dag.add(
          "marketplace-mark-resolved",
          MarketplaceMarkResolvedButton,
          { after: ["reply"] }
        );
      }
    }
  );

  api.addTrackedTopicProperties("can_mark_topic_resolved");
}

function addDecorators(api) {
  api.decorateCookedElement((element, post) => {
    const contactElements = element.querySelectorAll(".contact-placeholder");
    if (contactElements.length === 0) {
      return;
    }

    // 检查用户 trust_level
    const user = post?.topic?.currentUser;
    const requiredTrustLevel = parseInt(
      settings.marketplace_contact_trust_level || "0",
      10
    );

    const canViewContact =
      user && user.trust_level >= requiredTrustLevel;

    contactElements.forEach((el) => {
      const contactInfo = el.dataset.contact;

      if (canViewContact) {
        // 显示按钮
        el.innerHTML = "";
        const button = document.createElement("button");
        button.className = "btn btn-primary marketplace-contact-btn";
        button.textContent = I18n.t("marketplace.contact_button");
        button.addEventListener("click", () => {
          el.innerHTML = `<span class="contact-revealed">${contactInfo}</span>`;
        });
        el.appendChild(button);
      } else {
        // 不显示或显示占位
        el.innerHTML = `<span class="contact-hidden">${I18n.t("marketplace.contact_permission_denied")}</span>`;
      }
    });
  });
}

export default {
  name: "extend-for-marketplace",
  initialize() {
    withPluginApi("1.4.0", initializeWithApi);
  },
};
```

- [ ] **Step 2: 添加本地化字符串**

在 `config/locales/client.en.yml` 和 `client.zh_CN.yml` 中添加：

```yaml
en:
  js:
    marketplace:
      contact_button: "查看联系方式"
      contact_permission_denied: "无权限查看"

zh_CN:
  js:
    marketplace:
      contact_button: "查看联系方式"
      contact_permission_denied: "无权限查看"
```

- [ ] **Step 3: 提交更改**

```bash
git add assets/javascripts/discourse/initializers/ config/locales/
git commit -m "feat: 添加 contact 显示逻辑和权限检查"
```

---

## Chunk 5: 标题已解决徽章

### Task 6: 添加已解决徽章显示

**Files:**
- Modify: `assets/javascripts/discourse/initializers/extend-for-marketplace.gjs`

- [ ] **Step 1: 在初始化器中添加徽章逻辑**

在 `addDecorators` 函数中添加标题徽章处理：

```javascript
function addDecorators(api) {
  // 现有的 contact 装饰逻辑...

  // 添加已解决徽章
  api.onAppRendered(() => {
    const topic = document.querySelector(".topic-header-extra");
    if (topic && topic.dataset.resolved !== "true") {
      // 检查帖子是否已解决
      checkTopicResolved();
    }
  });

  // 或者使用 decorateTopicTitle
  api.decorateTopicTitle((topicTitleElement, topic) => {
    if (topic.can_mark_topic_resolved === false && topic.is_resolved) {
      const badge = document.createElement("span");
      badge.className = "marketplace-resolved-badge";
      badge.innerHTML = `<svg class="fa d-icon d-icon-check-circle resolved-icon">
        <use href="#check-circle"></use>
      </svg>`;
      topicTitleElement.appendChild(badge);
    }
  });
}
```

- [ ] **Step 2: 添加跟踪属性**

```javascript
api.addTrackedTopicProperties("is_resolved");
```

- [ ] **Step 3: 添加 CSS 样式**

创建或修改 `assets/stylesheets/common.scss`：

```scss
.marketplace-resolved-badge {
  margin-left: 8px;
  color: #009900;

  .d-icon-check-circle {
    font-size: 1.2em;
  }
}

.marketplace-contact-btn {
  margin: 4px 0;
}

.contact-revealed {
  font-weight: 600;
  color: var(--primary);
}

.contact-hidden {
  color: var(--primary-medium);
  font-style: italic;
}
```

- [ ] **Step 4: 提交更改**

```bash
git add assets/javascripts/ assets/stylesheets/
git commit -m "feat: 添加已解决徽章显示"
```

---

## Chunk 6: 清理旧代码

### Task 7: 移除不再需要的文件和方法

**Files:**
- Delete: `assets/javascripts/discourse/components/marketplace-contact-info.gjs`
- Delete: `assets/javascripts/discourse/connectors/composer-fields/marketplace-contact-field.gjs`
- Modify: `lib/discourse_marketplace/guardian_extensions.rb`
- Modify: `lib/discourse_marketplace/topic_view_serializer_extension.rb`

- [ ] **Step 1: 检查并移除旧组件**

```bash
rm assets/javascripts/discourse/components/marketplace-contact-info.gjs
rm assets/javascripts/discourse/connectors/composer-fields/marketplace-contact-field.gjs
```

- [ ] **Step 2: 检查 guardian_extensions**

读取并清理不再需要的权限方法。

- [ ] **Step 3: 提交清理**

```bash
git add -A
git commit -m "refactor: 移除不再需要的旧组件和逻辑"
```

---

## 验证清单

- [ ] 测试标记已解决功能
- [ ] 测试 BBCode 渲染
- [ ] 测试 trust_level 权限检查
- [ ] 测试已解决徽章显示
- [ ] 测试主题适配（亮色/暗色）

---

## 相关技能

- @superpowers:verification-before-completion - 完成前验证
- @superpowers:finishing-a-development-branch - 完成开发分支
