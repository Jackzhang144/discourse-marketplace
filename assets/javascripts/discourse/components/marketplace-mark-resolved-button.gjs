import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class MarketplaceMarkResolvedButton extends Component {
  @service appEvents;
  @tracked saving = false;

  @action
  async markResolved() {
    this.saving = true;
    try {
      await ajax("/marketplace/mark_resolved", {
        type: "POST",
        data: { topic_id: this.args.topic.id },
      });

      this.appEvents.trigger("marketplace:topic-resolved", this.args.topic);
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DButton
      class="marketplace-mark-resolved"
      @action={{this.markResolved}}
      @disabled={{this.saving}}
      @icon="check"
      @label="marketplace.mark_resolved"
      @title="marketplace.mark_resolved_title"
    />
  </template>
}
