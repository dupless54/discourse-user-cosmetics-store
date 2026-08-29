import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import CosmeticsStorePreviewStudio from "discourse/plugins/discourse-user-cosmetics-store/discourse/components/cosmetics-store-preview-studio";

module("Component | CosmeticsStorePreviewStudio", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.viewer = {
      logged_in: true,
      username: "eviltrout",
      avatar_template: "/letter_avatar_proxy/v4/letter/e/90ced4/{size}.png",
    };
    this.selections = {
      avatar_frame: 1,
      nameplate: 2,
      card_decoration: 3,
      profile_effect: 4,
    };
    this.items = [
      {
        id: 1,
        kind: "avatar_frame",
        name: "Gold frame",
        image_url: "/images/gold-frame.png",
      },
      {
        id: 5,
        kind: "avatar_frame",
        name: "Silver frame",
        image_url: "/images/silver-frame.png",
      },
      {
        id: 2,
        kind: "nameplate",
        name: "Night plate",
        image_url: "/images/night-plate.png",
      },
      {
        id: 6,
        kind: "nameplate",
        name: "Purple gradient",
        gradient_from: "#5b21b6",
        gradient_to: "#2563eb",
      },
      {
        id: 3,
        kind: "card_decoration",
        name: "Card glow",
        image_url: "/images/card-glow.png",
      },
      {
        id: 4,
        kind: "profile_effect",
        name: "Stars",
        inner_width: 1200,
        overflow_top: 100,
        overflow_bottom: 100,
        overflow_horizontal: 80,
        layers: [
          {
            anchor: "top",
            stack_order: "back",
            image_url: "/images/stars-back.png",
          },
          {
            anchor: "bottom",
            stack_order: "front",
            image_url: "/images/stars-front.png",
          },
        ],
      },
    ];
  });

  test("previews four equipped cosmetic types without applying them", async function (assert) {
    await render(
      <template>
        <CosmeticsStorePreviewStudio
          @items={{this.items}}
          @selections={{this.selections}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    assert.dom("[data-testid='apply-preview']").isDisabled();
    assert
      .dom(".cstore-preview-studio-avatar__frame")
      .hasAttribute("src", "/images/gold-frame.png");
    assert.dom(".cstore-preview-studio-nameplate").includesText("eviltrout");
    assert.dom(".cstore-preview-studio-nameplate").doesNotIncludeText("Night plate");
    assert
      .dom(".cstore-preview-studio-nameplate")
      .hasAttribute(
        "style",
        /background-image:\s*url\(["']?\/images\/night-plate\.png["']?\)/
      );
    assert
      .dom(".cstore-preview-studio__effect-canvas")
      .hasAttribute(
        "style",
        /--cstore-preview-effect-pad-top:\s*8\.3333%.*--cstore-preview-effect-pad-bottom:\s*8\.3333%/
      );
    assert
      .dom(".cstore-preview-studio-card__decoration")
      .hasAttribute("src", "/images/card-glow.png");
    assert.dom(".cstore-profile-effect-layers--back img").exists({ count: 1 });
    assert.dom(".cstore-profile-effect-layers--front img").exists({ count: 1 });
  });

  test("updates nameplate artwork immediately inside the preview", async function (assert) {
    await render(
      <template>
        <CosmeticsStorePreviewStudio
          @items={{this.items}}
          @selections={{this.selections}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    await click("[data-slot-kind='nameplate'] [data-item-id='6']");

    assert.dom("[data-slot-kind='nameplate'] [data-item-id='6']").hasClass("is-selected");
    assert.dom(".cstore-preview-studio-nameplate").includesText("eviltrout");
    assert
      .dom(".cstore-preview-studio-nameplate")
      .hasAttribute(
        "style",
        /linear-gradient\(90deg,\s*#5b21b6,\s*#2563eb\)/
      );
    assert.dom("[data-testid='apply-preview']").isEnabled();
  });

  test("keeps changes temporary and reset restores the server selection", async function (assert) {
    await render(
      <template>
        <CosmeticsStorePreviewStudio
          @items={{this.items}}
          @selections={{this.selections}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    await click("[data-slot-kind='avatar_frame'] [data-item-id='5']");

    assert.dom("[data-item-id='5']").hasClass("is-selected");
    assert.dom("[data-testid='apply-preview']").isEnabled();
    assert
      .dom(".cstore-preview-studio-avatar__frame")
      .hasAttribute("src", "/images/silver-frame.png");

    await click("[data-testid='reset-preview']");

    assert.dom("[data-item-id='1']").hasClass("is-selected");
    assert.dom("[data-testid='apply-preview']").isDisabled();
    assert
      .dom(".cstore-preview-studio-avatar__frame")
      .hasAttribute("src", "/images/gold-frame.png");
  });

  test("allows clearing a slot only inside the preview", async function (assert) {
    await render(
      <template>
        <CosmeticsStorePreviewStudio
          @items={{this.items}}
          @selections={{this.selections}}
          @viewer={{this.viewer}}
        />
      </template>
    );

    await click("[data-testid='preview-none-nameplate']");

    assert.dom("[data-testid='preview-none-nameplate']").hasClass("is-selected");
    assert.dom(".cstore-preview-studio-nameplate").doesNotExist();
    assert.dom("[data-testid='apply-preview']").isEnabled();
  });
});