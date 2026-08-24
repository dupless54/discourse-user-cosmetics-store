import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

const COLOR_PATTERN = /^(?:#[0-9a-f]{3,8}|(?:rgb|hsl)a?\([0-9\s.,%+/-]+\)|[a-z]+)$/i;

function safeColor(value, fallback) {
  const color = String(value || "").trim();
  return COLOR_PATTERN.test(color) ? color : fallback;
}

export default class CosmeticsStoreUserCardPreview extends Component {
  get items() {
    return this.args.product?.items ?? [];
  }

  itemFor(kind) {
    return this.items.find((item) => item.kind === kind);
  }

  get avatarFrame() {
    return this.itemFor("avatar_frame");
  }

  get avatarFrameUrl() {
    return this.avatarFrame?.image_url;
  }

  get nameplate() {
    return this.itemFor("nameplate");
  }

  get cardDecoration() {
    return this.itemFor("card_decoration");
  }

  get cardDecorationUrl() {
    return this.cardDecoration?.image_url;
  }

  get profileEffect() {
    return this.itemFor("profile_effect");
  }

  get profileEffectLayers() {
    return this.profileEffect?.layers ?? [];
  }

  get profileEffectUrl() {
    return this.profileEffect?.image_url;
  }

  get user() {
    return this.args.user ?? {};
  }

  get displayName() {
    return this.user.name || this.user.username || "Topluluk üyesi";
  }

  get username() {
    return this.user.username || "kullanici";
  }

  get initial() {
    return this.displayName.trim().charAt(0).toLocaleUpperCase("tr-TR") || "S";
  }

  get avatarUrl() {
    return this.user.avatar_url;
  }

  get backgroundUrl() {
    return this.user.card_background_url || this.user.profile_background_url;
  }

  get bannerClass() {
    return `cstore-user-card-preview__banner${this.backgroundUrl ? "" : " is-default"}`;
  }

  get visualStyle() {
    const source = this.cardDecoration || this.nameplate || this.avatarFrame || this.profileEffect || {};
    return htmlSafe(
      `--cstore-user-card-from:${safeColor(source.gradient_from, "#5865f2")};` +
        `--cstore-user-card-to:${safeColor(source.gradient_to, "#eb459e")};` +
        `--cstore-user-card-glow:${safeColor(source.glow_color, "transparent")}`,
    );
  }

  <template>
    <article class="cstore-user-card-preview" style={{this.visualStyle}} aria-label="{{this.displayName}} için kozmetik önizlemesi">
      <div class={{this.bannerClass}}>
        {{#if this.backgroundUrl}}
          <img src={{this.backgroundUrl}} alt="" loading="eager" />
        {{/if}}
      </div>

      <div class="cstore-user-card-preview__avatar-wrap">
        <span class="cstore-user-card-preview__avatar">
          {{#if this.avatarUrl}}
            <img src={{this.avatarUrl}} alt="" loading="eager" />
          {{else}}
            <b>{{this.initial}}</b>
          {{/if}}
        </span>
        {{#if this.avatarFrameUrl}}
          <img class="cstore-user-card-preview__avatar-frame" src={{this.avatarFrameUrl}} alt="" loading="eager" />
        {{/if}}
        <i class="cstore-user-card-preview__status" title="Çevrimiçi"></i>
      </div>

      <div class="cstore-user-card-preview__body">
        <div class="cstore-user-card-preview__nameplate {{if this.nameplate 'has-nameplate'}}">
          {{#if this.nameplate.image_url}}
            <img src={{this.nameplate.image_url}} alt="" loading="eager" />
          {{/if}}
          <strong>{{this.displayName}}</strong>
        </div>
        <span class="cstore-user-card-preview__username">@{{this.username}}</span>

        <div class="cstore-user-card-preview__divider"></div>
        <small>HAKKIMDA</small>
        <p>Tarzını toplulukta her yerde göster.</p>
        <small>ÜYE OLMA TARİHİ</small>
        <p>Senin.me topluluk üyesi</p>
        <div class="cstore-user-card-preview__message">@{{this.username}} kullanıcısına mesaj gönder</div>
      </div>

      {{#if this.cardDecorationUrl}}
        <img class="cstore-user-card-preview__decoration" src={{this.cardDecorationUrl}} alt="" loading="eager" />
      {{/if}}

      {{#if this.profileEffectLayers.length}}
        {{#each this.profileEffectLayers as |layer|}}
          <img class="cstore-user-card-preview__effect cstore-user-card-preview__effect--{{layer.anchor}} cstore-user-card-preview__effect--{{layer.stack_order}}" src={{layer.image_url}} alt="" loading="eager" />
        {{/each}}
      {{else if this.profileEffectUrl}}
        <img class="cstore-user-card-preview__effect" src={{this.profileEffectUrl}} alt="" loading="eager" />
      {{/if}}
    </article>
  </template>
}
