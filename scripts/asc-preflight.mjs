import crypto from "node:crypto";

const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
const teamId = process.env.APPLE_TEAM_ID;
const keyBase64 = process.env.APP_STORE_CONNECT_API_KEY_P8_BASE64;
const bundleIdentifier = "com.acanxp.trellis";

if (!keyId || !issuerId || !teamId || !keyBase64) {
  throw new Error("Missing App Store Connect environment variables.");
}

const privateKey = Buffer.from(keyBase64, "base64").toString("utf8");

function base64url(value) {
  return Buffer.from(value)
    .toString("base64")
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function makeToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({
    alg: "ES256",
    kid: keyId,
    typ: "JWT",
  }));
  const payload = base64url(JSON.stringify({
    iss: issuerId,
    iat: now,
    exp: now + 15 * 60,
    aud: "appstoreconnect-v1",
  }));
  const signingInput = `${header}.${payload}`;
  const signature = crypto.sign("sha256", Buffer.from(signingInput), {
    key: privateKey,
    dsaEncoding: "ieee-p1363",
  });
  return `${signingInput}.${base64url(signature)}`;
}

const token = makeToken();

async function api(path) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    headers: {
      authorization: `Bearer ${token}`,
      accept: "application/json",
    },
  });
  const text = await response.text();
  let body = null;
  try {
    body = JSON.parse(text);
  } catch {
    body = { raw: text };
  }
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${text}`);
  }
  return body;
}

const encodedBundle = encodeURIComponent(bundleIdentifier);
const bundleResponse = await api(
  `/v1/bundleIds?filter[identifier]=${encodedBundle}&limit=10`,
);
const appResponse = await api(
  `/v1/apps?filter[bundleId]=${encodedBundle}&limit=10`,
);
const allAppsResponse = await api("/v1/apps?limit=200");
const certificateResponse = await api(
  "/v1/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=200",
);
const allCertificateResponse = await api("/v1/certificates?limit=200");

const bundleId = bundleResponse.data?.[0] ?? null;
let profiles = [];
if (bundleId) {
  const profileResponse = await api(`/v1/bundleIds/${bundleId.id}/profiles`);
  profiles = profileResponse.data ?? [];
}

console.log(JSON.stringify({
  teamId,
  bundleIdentifier,
  bundleId: bundleId && {
    id: bundleId.id,
    name: bundleId.attributes?.name,
    platform: bundleId.attributes?.platform,
    seedId: bundleId.attributes?.seedId,
  },
  apps: (appResponse.data ?? []).map((app) => ({
    id: app.id,
    name: app.attributes?.name,
    bundleId: app.attributes?.bundleId,
    sku: app.attributes?.sku,
    primaryLocale: app.attributes?.primaryLocale,
  })),
  allApps: (allAppsResponse.data ?? []).map((app) => ({
    id: app.id,
    name: app.attributes?.name,
    bundleId: app.attributes?.bundleId,
    sku: app.attributes?.sku,
    primaryLocale: app.attributes?.primaryLocale,
  })),
  certificates: (certificateResponse.data ?? []).map((certificate) => ({
    id: certificate.id,
    name: certificate.attributes?.name,
    serialNumber: certificate.attributes?.serialNumber,
    expirationDate: certificate.attributes?.expirationDate,
  })),
  allCertificates: (allCertificateResponse.data ?? []).map((certificate) => ({
    id: certificate.id,
    name: certificate.attributes?.name,
    certificateType: certificate.attributes?.certificateType,
    serialNumber: certificate.attributes?.serialNumber,
    expirationDate: certificate.attributes?.expirationDate,
  })),
  profiles: profiles.map((profile) => ({
    id: profile.id,
    name: profile.attributes?.name,
    type: profile.attributes?.profileType,
    state: profile.attributes?.profileState,
    uuid: profile.attributes?.uuid,
    expirationDate: profile.attributes?.expirationDate,
  })),
}, null, 2));

