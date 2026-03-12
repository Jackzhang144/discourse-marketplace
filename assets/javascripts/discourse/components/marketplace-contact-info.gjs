import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";

export default class MarketplaceContactInfo extends Component {
  @service currentUser;
  @tracked revealed = false;

  get canView() {
    return this.args.canViewContactInfo;
  }

  get canShowContact() {
    return this.revealed || this.canView;
  }

  get hasContactInfo() {
    return this.args.contactInfo && this.args.contactInfo.length > 0;
  }

  get isResolved() {
    return this.args.isResolved;
  }

  @action
  revealContact() {
    this.revealed = true;
  }

  <template>
    {{#if this.hasContactInfo}}
      <div class="marketplace-contact-info">
        {{#if this.canShowContact}}
          <div class="contact-info-content">
            <span class="contact-label">{{i18n "marketplace.contact_info"}}:</span>
            <span class="contact-value">{{@contactInfo}}</span>
          </div>
        {{else}}
          <DButton
            class="reveal-contact-btn"
            @action={{this.revealContact}}
            @icon="phone"
            @label="marketplace.reveal_contact"
          />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
