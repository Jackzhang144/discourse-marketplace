import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import TextField from "discourse/components/text-field";
import { i18n } from "discourse-i18n";

export default class MarketplaceContactField extends Component {
  @service siteSettings;

  get shouldShow() {
    // 只在二手专区显示联系方式输入框
    const categoryId = this.args.model.categoryId;
    if (!categoryId) {
      return false;
    }
    // 这里可以扩展为检查是否是特定的分类
    return this.siteSettings.marketplace_enable_contact_info;
  }

  @action
  updateContactInfo(event) {
    this.args.model.setProperty(
      "marketplace_contact_info",
      event.target.value
    );
  }

  <template>
    {{#if this.shouldShow}}
      <div class="marketplace-contact-field">
        <label for="marketplace-contact-info">
          {{i18n "marketplace.contact_info"}}
        </label>
        <TextField
          @id="marketplace-contact-info"
          @value={{@model.marketplace_contact_info}}
          @placeholderKey="marketplace.contact_info_placeholder"
          @input={{this.updateContactInfo}}
        />
      </div>
    {{/if}}
  </template>
}
