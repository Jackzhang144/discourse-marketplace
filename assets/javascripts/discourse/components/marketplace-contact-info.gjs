import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";

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

  get contactLabel() {
    return i18n("marketplace.contact_info");
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
            <span class="contact-label">{{this.contactLabel}}:</span>
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
