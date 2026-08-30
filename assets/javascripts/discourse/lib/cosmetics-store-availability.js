import { i18n } from "discourse-i18n";

const HEX_COLOR = /^#[0-9a-f]{3}(?:[0-9a-f]{3}(?:[0-9a-f]{2})?)?$/i;
const I18N_PREFIX = "discourse_cosmetics_store.availability";

export function availabilityBadge(product) {
  if (product?.sale_state === "upcoming") {
    return i18n(`${I18N_PREFIX}.badge.upcoming`);
  }
  if (product?.availability_type === "seasonal") {
    return i18n(`${I18N_PREFIX}.badge.seasonal`);
  }
  if (product?.availability_type === "limited") {
    return i18n(`${I18N_PREFIX}.badge.limited`);
  }
  return null;
}

export function availabilityDetail(product, now = Date.now()) {
  if (product?.sale_state === "upcoming" && product.available_from) {
    const remaining = formatRemaining(Date.parse(product.available_from) - now);
    return remaining
      ? i18n(`${I18N_PREFIX}.detail.opens_in`, { remaining })
      : i18n(`${I18N_PREFIX}.detail.upcoming`);
  }

  if (product?.sale_state === "active" && product.available_until) {
    const remaining = formatRemaining(Date.parse(product.available_until) - now);
    return remaining
      ? i18n(`${I18N_PREFIX}.detail.remaining`, { remaining })
      : i18n(`${I18N_PREFIX}.detail.ending_soon`);
  }

  return null;
}

export function availabilityMatches(product, value) {
  if (!value) {
    return true;
  }
  if (value === "upcoming") {
    return product?.sale_state === "upcoming";
  }
  return product?.availability_type === value;
}

export function rarityStyle(color) {
  const value = String(color || "").trim();
  return HEX_COLOR.test(value) ? `--cstore-rarity: ${value};` : null;
}

function formatRemaining(milliseconds) {
  if (!Number.isFinite(milliseconds) || milliseconds <= 0) {
    return null;
  }

  const totalMinutes = Math.max(1, Math.ceil(milliseconds / 60_000));
  const days = Math.floor(totalMinutes / 1440);
  const hours = Math.floor((totalMinutes % 1440) / 60);
  const minutes = totalMinutes % 60;

  if (days > 0) {
    return hours > 0
      ? i18n(`${I18N_PREFIX}.duration.days_hours`, { days, hours })
      : i18n(`${I18N_PREFIX}.duration.days`, { days });
  }
  if (hours > 0) {
    return minutes > 0
      ? i18n(`${I18N_PREFIX}.duration.hours_minutes`, { hours, minutes })
      : i18n(`${I18N_PREFIX}.duration.hours`, { hours });
  }
  return i18n(`${I18N_PREFIX}.duration.minutes`, { minutes });
}
