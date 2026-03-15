import { escape } from "pretty-text/sanitizer";

export function setup(helper) {
  if (!helper.markdownIt) {
    return;
  }

  helper.registerOptions((opts, siteSettings) => {
    opts.features["contact"] = !!siteSettings.marketplace_enabled;
  });

  // 白名单化 span.contact-placeholder 和 data-contact 属性
  helper.allowList([
    "span.contact-placeholder",
    "span.contact-placeholder[data-contact]",
  ]);

  // 使用 Discourse 推荐的 inline.bbcode.ruler
  helper.registerPlugin((md) => {
    md.inline.bbcode.ruler.push("contact", {
      tag: "contact",
      wrap: {
        tag: "span",
        class: "contact-placeholder",
      },
      transform: (node, attrs) => {
        // 保存联系方式内容到 data 属性，用于前端显示
        node.attrs.push(["data-contact", escape(attrs._default || "")]);
      },
    });
  });
}
