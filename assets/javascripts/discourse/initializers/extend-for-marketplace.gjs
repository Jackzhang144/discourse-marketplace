import { withPluginApi } from "discourse/lib/plugin-api";
import MarketplaceMarkResolvedButton from "../components/marketplace-mark-resolved-button";

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

  api.addTrackedTopicProperties("can_mark_topic_resolved", "is_resolved");
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
        // 显示权限不足
        el.innerHTML = `<span class="contact-hidden">${I18n.t("marketplace.contact_permission_denied")}</span>`;
      }
    });
  });

  // 添加已解决徽章
  api.decorateTopicTitle((topicTitleElement, topic) => {
    if (topic.is_resolved) {
      // 帖子已被标记为已解决
      // 检查是否已经显示了徽章，避免重复
      const existingBadge = topicTitleElement.querySelector(".marketplace-resolved-badge");
      if (!existingBadge) {
        const badge = document.createElement("span");
        badge.className = "marketplace-resolved-badge";
        badge.innerHTML = `<span class="marketplace-resolved-badge-icon"><svg class="fa d-icon d-icon-check-circle">
          <use href="#check-circle"></use>
        </svg></span>`;
        topicTitleElement.appendChild(badge);
      }
    }
  });
}

export default {
  name: "extend-for-marketplace",
  initialize() {
    withPluginApi("1.4.0", initializeWithApi);
  },
};
