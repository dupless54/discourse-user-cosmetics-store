import Component from "@glimmer/component";
import { service } from "@ember/service";

const SUPPORT_URL = "https://buymeacoffee.com/erespawn";
const BANNER_URL =
  "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png";

export default class CosmeticsStoreAdminSupportBanner extends Component {
  @service router;

  get showBanner() {
    return this.router.currentRouteName?.endsWith(
      "adminPlugins.show.settings"
    );
  }

  <template>
    {{#if this.showBanner}}
      <a
        class="cstore-admin-support-banner"
        href={{SUPPORT_URL}}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Support this project on Buy Me a Coffee"
      >
        <img
          src={{BANNER_URL}}
          width="174"
          height="49"
          alt="Buy Me a Coffee"
          loading="eager"
        />
      </a>
    {{/if}}
  </template>
}
