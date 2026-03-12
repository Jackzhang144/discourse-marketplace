import { withPluginApi } from "discourse/lib/plugin-api";

function initializeWithApi(api) {
  addDecorators(api);
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
          // 使用 textContent 安全地显示联系方式
          el.innerHTML = "";
          const span = document.createElement("span");
          span.className = "contact-revealed";
          span.textContent = contactInfo;
          el.appendChild(span);
        });
        el.appendChild(button);
      } else {
        // 显示权限不足
        el.innerHTML = "";
        const span = document.createElement("span");
        span.className = "contact-hidden";
        span.textContent = I18n.t("marketplace.contact_permission_denied");
        el.appendChild(span);
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
