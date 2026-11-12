import crypto from "node:crypto";

const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
const keyBase64 = process.env.APP_STORE_CONNECT_API_KEY_P8_BASE64;
const appId = "6833441469";
const buildVersion = "5";

if (!keyId || !issuerId || !keyBase64) {
  throw new Error("Missing App Store Connect API credentials.");
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
  const response = await fetch(
    `https://api.appstoreconnect.apple.com${path}`,
    {
      ...options,
      headers: {
        authorization: `Bearer ${token}`,
        accept: "application/json",
        ...(options.body ? { "content-type": "application/json" } : {}),
        ...(options.headers || {}),
      },
    },
  );
  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : {};
  } catch {
    body = { raw: text };
  }
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${text}`);
  }
  return body;
}

const groups = await api(
  `/v1/betaGroups?filter[app]=${appId}&limit=200`,
);
const debugGroup = (groups.data ?? []).find(
  (group) => group.attributes?.name === "Debug",
);
if (!debugGroup) {
  throw new Error("Internal Debug group was not found.");
}

const builds = await api(
  `/v1/builds?filter[app]=${appId}&filter[version]=${buildVersion}&limit=10`,
);
if (builds.data?.length !== 1) {
  throw new Error(
    `Expected exactly one build ${buildVersion}, found ${builds.data?.length ?? 0}.`,
  );
}

const build = builds.data[0];
const [detail, groupBuilds] = await Promise.all([
  api(`/v1/builds/${build.id}/buildBetaDetail`),
  api(`/v1/betaGroups/${debugGroup.id}/builds?limit=50`),
]);
const isAttached = (groupBuilds.data ?? []).some(
  (item) => item.id === build.id,
);
const state = detail.data?.attributes?.internalBuildState;

console.log(JSON.stringify({
  buildVersion,
  buildId: build.id,
  processingState: build.attributes?.processingState,
  internalBuildState: state,
  debugGroupId: debugGroup.id,
  debugGroupVersions: (groupBuilds.data ?? [])
    .map((item) => item.attributes?.version),
  attached: isAttached,
}, null, 2));

if (
  build.attributes?.processingState !== "VALID" ||
  state !== "IN_BETA_TESTING" ||
  !isAttached
) {
  throw new Error("Build 5 is not yet available in the internal Debug group.");
}
