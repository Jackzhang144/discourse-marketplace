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
        // 显示权限不足
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
