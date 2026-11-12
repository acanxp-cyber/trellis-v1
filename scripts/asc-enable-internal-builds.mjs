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

await api(`/v1/buildBetaDetails/${build5.id}`, {
  method: "PATCH",
  body: JSON.stringify({
    data: {
      type: "buildBetaDetails",
      id: build5.id,
      attributes: {
        autoNotifyEnabled: true,
      },
    },
  }),
});

const groupsAfterInspection = await api(
  `/v1/betaGroups?filter[app]=${appId}&limit=200`,
);
let voiceFixGroup = (groupsAfterInspection.data ?? []).find(
  (group) => group.attributes?.name === "Voice Fix 5",
);
if (!voiceFixGroup) {
  const createdGroup = await api("/v1/betaGroups", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "betaGroups",
        attributes: {
          name: "Voice Fix 5",
          isInternalGroup: true,
        },
        relationships: {
          app: {
            data: {
              type: "apps",
              id: appId,
            },
          },
        },
      },
    }),
  });
  voiceFixGroup = createdGroup.data;
}

const testers = await api("/v1/betaTesters?limit=200");
const tester = (testers.data ?? []).find(
  (item) => item.attributes?.email === "120720375@qq.com",
);
if (!tester) {
  throw new Error("The internal tester account was not found.");
}

await api(
  `/v1/betaGroups/${voiceFixGroup.id}/relationships/betaTesters`,
  {
    method: "POST",
    body: JSON.stringify({
      data: [
        {
          type: "betaTesters",
          id: tester.id,
        },
      ],
    }),
  },
);

await api(`/v1/builds/${build5.id}/relationships/betaGroups`, {
  method: "POST",
  body: JSON.stringify({
    data: [
      {
        type: "betaGroups",
        id: voiceFixGroup.id,
      },
    ],
  }),
});

let updatedDetail = null;
let updatedGroupBuilds = null;
let buildIsAvailable = false;

for (let attempt = 1; attempt <= 12; attempt += 1) {
  updatedDetail = await api(
    `/v1/builds/${build5.id}/buildBetaDetail`,
  );
  updatedGroupBuilds = await api(
    `/v1/betaGroups/${voiceFixGroup.id}/builds?limit=50`,
  );
  buildIsAvailable =
    updatedDetail.data?.attributes?.internalBuildState ===
      "IN_BETA_TESTING" &&
    (updatedGroupBuilds.data ?? []).some(
      (item) => item.id === build5.id,
    );
  if (buildIsAvailable) {
    break;
  }
  console.log(
    `Waiting for TestFlight availability (${attempt}/12): ${updatedDetail.data?.attributes?.internalBuildState}`,
  );
  await new Promise((resolve) => setTimeout(resolve, 10_000));
}

if (!buildIsAvailable) {
  throw new Error("Build 5 did not become available to internal testers.");
}

console.log(JSON.stringify({
  voiceFixGroup: {
    id: voiceFixGroup.id,
    name: voiceFixGroup.attributes?.name,
  },
  tester: {
    id: tester.id,
    email: tester.attributes?.email,
  },
  buildVersions: (updatedGroupBuilds.data ?? [])
    .map((item) => item.attributes?.version),
  build5State:
    updatedDetail.data?.attributes?.internalBuildState,
  didNotify: updatedDetail.data?.attributes?.didNotify,
}));
