import crypto from "node:crypto";
import fs from "node:fs";

const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
const teamId = process.env.APPLE_TEAM_ID;
const keyBase64 = process.env.APP_STORE_CONNECT_API_KEY_P8_BASE64;
const certificateSerial = process.env.DISTRIBUTION_CERTIFICATE_SERIAL
  ?.replaceAll(":", "")
  .toUpperCase();
const profileOutputPath = process.env.PROFILE_OUTPUT_PATH;
const metadataOutputPath = process.env.SIGNING_METADATA_PATH;
const bundleIdentifier = process.env.BUNDLE_IDENTIFIER || "com.acanxp.trellis";
const bundleName = process.env.BUNDLE_NAME || "SOMETHING";

for (const [name, value] of Object.entries({
  APP_STORE_CONNECT_KEY_ID: keyId,
  APP_STORE_CONNECT_ISSUER_ID: issuerId,
  APPLE_TEAM_ID: teamId,
  APP_STORE_CONNECT_API_KEY_P8_BASE64: keyBase64,
  DISTRIBUTION_CERTIFICATE_SERIAL: certificateSerial,
  PROFILE_OUTPUT_PATH: profileOutputPath,
  SIGNING_METADATA_PATH: metadataOutputPath,
})) {
  if (!value) {
    throw new Error(`Missing ${name}`);
  }
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

async function api(path, options = {}) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    ...options,
    headers: {
      authorization: `Bearer ${token}`,
      accept: "application/json",
      ...(options.body ? { "content-type": "application/json" } : {}),
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  const body = text ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${text}`);
  }
  return body;
}

const encodedBundleIdentifier = encodeURIComponent(bundleIdentifier);
let bundleResponse = await api(
  `/v1/bundleIds?filter[identifier]=${encodedBundleIdentifier}&limit=10`,
);
let bundle = bundleResponse.data?.[0] ?? null;

if (!bundle) {
  const created = await api("/v1/bundleIds", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "bundleIds",
        attributes: {
          identifier: bundleIdentifier,
          name: bundleName,
          platform: "IOS",
          seedId: teamId,
        },
      },
    }),
  });
  bundle = created.data;
  console.log(`Registered Bundle ID ${bundleIdentifier}`);
} else {
  console.log(`Using existing Bundle ID ${bundleIdentifier}`);
}

const certificates = await api("/v1/certificates?limit=200");
const certificate = certificates.data?.find((item) => {
  const itemSerial = item.attributes?.serialNumber
    ?.replaceAll(":", "")
    .toUpperCase();
  return itemSerial === certificateSerial
    && item.attributes?.certificateType === "DISTRIBUTION";
});

if (!certificate) {
  throw new Error(`No distribution certificate matched serial ${certificateSerial}`);
}

const existingProfiles = await api(`/v1/bundleIds/${bundle.id}/profiles`);
let profile = existingProfiles.data?.find(
  (item) => item.attributes?.profileType === "IOS_APP_STORE"
    && item.attributes?.profileState === "ACTIVE",
) ?? null;

if (!profile) {
  const createdProfile = await api("/v1/profiles", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "profiles",
        attributes: {
          name: "SOMETHING App Store Distribution",
          profileType: "IOS_APP_STORE",
        },
        relationships: {
          bundleId: {
            data: {
              type: "bundleIds",
              id: bundle.id,
            },
          },
          certificates: {
            data: [
              {
                type: "certificates",
                id: certificate.id,
              },
            ],
          },
        },
      },
    }),
  });
  profile = createdProfile.data;
  console.log("Created App Store provisioning profile");
} else {
  console.log("Using existing App Store provisioning profile");
}

const profileContent = profile.attributes?.profileContent;
if (!profileContent) {
  throw new Error("Provisioning profile response did not include profileContent");
}

fs.writeFileSync(profileOutputPath, Buffer.from(profileContent, "base64"));
fs.writeFileSync(metadataOutputPath, JSON.stringify({
  bundleIdentifier,
  bundleIdResourceId: bundle.id,
  certificateId: certificate.id,
  certificateSerial,
  profileId: profile.id,
  profileName: profile.attributes?.name,
  profileUUID: profile.attributes?.uuid,
  profileType: profile.attributes?.profileType,
  expirationDate: profile.attributes?.expirationDate,
}, null, 2));

console.log(JSON.stringify({
  bundleIdentifier,
  bundleIdResourceId: bundle.id,
  certificateId: certificate.id,
  profileId: profile.id,
  profileName: profile.attributes?.name,
  profileUUID: profile.attributes?.uuid,
}, null, 2));

