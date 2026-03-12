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
