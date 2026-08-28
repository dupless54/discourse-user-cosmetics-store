const HEX_COLOR = /^#[0-9a-f]{3}(?:[0-9a-f]{3}(?:[0-9a-f]{2})?)?$/i;

export function availabilityBadge(product) {
  if (product?.sale_state === "upcoming") {
    return "YAKINDA";
  }
  if (product?.availability_type === "seasonal") {
    return "SEZONLUK";
  }
  if (product?.availability_type === "limited") {
    return "SINIRLI SÜRE";
  }
  return null;
}

export function availabilityDetail(product, now = Date.now()) {
  if (product?.sale_state === "upcoming" && product.available_from) {
    const remaining = formatRemaining(Date.parse(product.available_from) - now);
    return remaining ? `${remaining} sonra açılıyor` : "Yakında satışta";
  }

  if (product?.sale_state === "active" && product.available_until) {
    const remaining = formatRemaining(Date.parse(product.available_until) - now);
    return remaining ? `${remaining} kaldı` : "Süre dolmak üzere";
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
    return hours > 0 ? `${days}g ${hours}sa` : `${days}g`;
  }
  if (hours > 0) {
    return minutes > 0 ? `${hours}sa ${minutes}dk` : `${hours}sa`;
  }
  return `${minutes}dk`;
}
