import { apiInitializer } from "discourse/lib/api";

const DEFAULT_FRAME_OVERHANG_PERCENT = 14;
const MAX_FRAME_OVERHANG_PERCENT = 60;

export function cosmeticsStoreAvatarFrameScale(overhangPercent) {
  const parsed = Number(overhangPercent);
  const safeOverhang = Number.isFinite(parsed)
    ? Math.min(MAX_FRAME_OVERHANG_PERCENT, Math.max(0, parsed))
    : DEFAULT_FRAME_OVERHANG_PERCENT;

  return 1 + (safeOverhang * 2) / 100;
}

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const scale = cosmeticsStoreAvatarFrameScale(
    siteSettings?.discourse_user_cosmetics_frame_overhang_percent
  );

  document.documentElement.style.setProperty(
    "--cstore-avatar-frame-scale",
    String(scale)
  );
});
