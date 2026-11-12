import crypto from "node:crypto";

const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
const keyBase64 = process.env.APP_STORE_CONNECT_API_KEY_P8_BASE64;
const appId = "6833441469";

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
const internalGroups = (groups.data ?? []).filter(
  (group) => group.attributes?.isInternalGroup,
);
if (internalGroups.length === 0) {
  throw new Error("No internal TestFlight group was found.");
}

for (const group of internalGroups) {
  const groupBuilds = await api(
    `/v1/betaGroups/${group.id}/builds?limit=50`,
  );
  console.log(JSON.stringify({
    groupId: group.id,
    name: group.attributes?.name,
    hasAccessToAllBuilds: group.attributes?.hasAccessToAllBuilds,
    buildVersions: (groupBuilds.data ?? [])
      .map((item) => item.attributes?.version),
  }));
}

let build5 = null;

for (const version of ["4", "5"]) {
  const builds = await api(
    `/v1/builds?filter[app]=${appId}&filter[version]=${version}&limit=10`,
  );
  if (builds.data?.length !== 1) {
    throw new Error(
      `Expected exactly one build ${version}, found ${builds.data?.length ?? 0}.`,
    );
  }

  const build = builds.data[0];
  if (version === "5") {
    build5 = build;
  }
  const detail = await api(`/v1/builds/${build.id}/buildBetaDetail`);
  const localizations = await api(
    `/v1/builds/${build.id}/betaBuildLocalizations`,
  );
  const reviewSubmission = await api(
    `/v1/builds/${build.id}/betaAppReviewSubmission`,
  );
  console.log(JSON.stringify({
    buildId: build.id,
    version: build.attributes?.version,
    processingState: build.attributes?.processingState,
    internalBuildState: detail.data?.attributes?.internalBuildState,
    externalBuildState: detail.data?.attributes?.externalBuildState,
    autoNotifyEnabled: detail.data?.attributes?.autoNotifyEnabled,
    didNotify: detail.data?.attributes?.didNotify,
    localizations: (localizations.data ?? []).map((item) => ({
      locale: item.attributes?.locale,
      whatsNew: item.attributes?.whatsNew,
    })),
    reviewSubmission: reviewSubmission.data?.attributes ?? null,
  }));
}

if (!build5) {
  throw new Error("Build 5 was not found.");
}

const debugGroup = internalGroups.find(
  (group) => group.attributes?.name === "Debug",
);
if (!debugGroup) {
  throw new Error("Internal Debug group was not found.");
}

await api(
  `/v1/betaGroups/${debugGroup.id}/relationships/builds`,
  {
    method: "POST",
    body: JSON.stringify({
      data: [
        {
          type: "builds",
          id: build5.id,
        },
      ],
    }),
  },
);

const updatedGroups = await api(
  `/v1/betaGroups?filter[app]=${appId}&limit=200`,
);
const updatedDebugGroup = (updatedGroups.data ?? []).find(
  (group) => group.id === debugGroup.id,
);
const updatedGroupBuilds = await api(
  `/v1/betaGroups/${debugGroup.id}/builds?limit=50`,
);
const updatedDetail = await api(
  `/v1/builds/${build5.id}/buildBetaDetail`,
);

console.log(JSON.stringify({
  updatedDebugGroup: {
    id: updatedDebugGroup?.id,
    name: updatedDebugGroup?.attributes?.name,
    hasAccessToAllBuilds:
      updatedDebugGroup?.attributes?.hasAccessToAllBuilds,
  },
  buildVersions: (updatedGroupBuilds.data ?? [])
    .map((item) => item.attributes?.version),
  build5State:
    updatedDetail.data?.attributes?.internalBuildState,
}));
