import { withPluginApi } from "discourse/lib/plugin-api";
import MarketplaceMarkResolvedButton from "../components/marketplace-mark-resolved-button";
import MarketplaceContactInfo from "../components/marketplace-contact-info";

function initializeWithApi(api) {
  customizeTopicFooter(api);
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

  api.addTrackedTopicProperties(
    "can_mark_topic_resolved",
    "marketplace_contact_info"
  );
}

export default {
  name: "extend-for-marketplace",
  initialize() {
    withPluginApi("1.4.0", initializeWithApi);
  },
};
