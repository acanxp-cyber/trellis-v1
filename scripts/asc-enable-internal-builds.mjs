import crypto from "node:crypto";

const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
const keyBase64 = process.env.APP_STORE_CONNECT_API_KEY_P8_BASE64;
const appId = "6833441469";
const buildVersion = process.env.TESTFLIGHT_BUILD_VERSION || "7";
const whatsNew = process.env.TESTFLIGHT_WHATS_NEW ||
  "请重点验证：1）更多 > 提醒声音默认是温柔台湾普通话女声，可试听、切换、关闭和恢复默认；2）设置一分钟后提醒，锁屏后应播报“时间到了，任务内容”；3）提前五分钟提醒应播报“还有5分钟到…”，不再出现“提醒我”；4）主页入口已统一为“训练”，检查动作图片或简化动画；5）拍照后可选择8个本地滤镜；6）请分别在静音、专注模式、蓝牙耳机和来电打断后测试提醒。";

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
    const error = new Error(
      `${response.status} ${response.statusText}: ${text}`,
    );
    error.status = response.status;
    throw error;
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

let build = null;
for (let attempt = 1; attempt <= 24; attempt += 1) {
  const builds = await api(
    `/v1/builds?filter[app]=${appId}&filter[version]=${buildVersion}&limit=10`,
  );
  for (const candidate of builds.data ?? []) {
    try {
      const detail = await api(`/v1/builds/${candidate.id}`);
      if (
        detail.data?.attributes?.processingState === "VALID"
      ) {
        build = detail.data;
        break;
      }
    } catch (error) {
      if (error.status !== 404) {
        throw error;
      }
    }
  }
  if (build) {
    break;
  }
  console.log(`Waiting for build ${buildVersion} (${attempt}/24)`);
  await new Promise((resolve) => setTimeout(resolve, 10_000));
}
if (!build) {
  throw new Error(`Build ${buildVersion} did not become VALID.`);
}

try {
  await api(`/v1/builds/${build.id}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "builds",
        id: build.id,
        attributes: {
          usesNonExemptEncryption: false,
        },
      },
    }),
  });
} catch (error) {
  if (error.status !== 409) {
    throw error;
  }
}

const localizations = await api(
  `/v1/builds/${build.id}/betaBuildLocalizations?limit=20`,
);
const localization = (localizations.data ?? []).find(
  (item) => item.attributes?.locale === "zh-Hans",
);
if (localization) {
  await api(`/v1/betaBuildLocalizations/${localization.id}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "betaBuildLocalizations",
        id: localization.id,
        attributes: { whatsNew },
      },
    }),
  });
} else {
  await api("/v1/betaBuildLocalizations", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "betaBuildLocalizations",
        attributes: {
          locale: "zh-Hans",
          whatsNew,
        },
        relationships: {
          build: {
            data: {
              type: "builds",
              id: build.id,
            },
          },
        },
      },
    }),
  });
}

try {
  await api(`/v1/builds/${build.id}/relationships/betaGroups`, {
    method: "POST",
    body: JSON.stringify({
      data: [
        {
          type: "betaGroups",
          id: debugGroup.id,
        },
      ],
    }),
  });
} catch (error) {
  if (![409, 422].includes(error.status)) {
    throw error;
  }
  console.log(`Group attach returned ${error.status}; waiting for Apple's automatic internal distribution.`);
}

let available = false;
let detail = null;
let groupBuilds = null;
for (let attempt = 1; attempt <= 24; attempt += 1) {
  [detail, groupBuilds] = await Promise.all([
    api(`/v1/builds/${build.id}/buildBetaDetail`),
    api(`/v1/betaGroups/${debugGroup.id}/builds?limit=50`),
  ]);
  const attached = (groupBuilds.data ?? []).some(
    (item) => item.id === build.id,
  );
  const state = detail.data?.attributes?.internalBuildState;
  available = attached && state === "IN_BETA_TESTING";
  console.log(
    `Availability ${attempt}/24: state=${state}, attached=${attached}`,
  );
  if (available) {
    break;
  }
  await new Promise((resolve) => setTimeout(resolve, 10_000));
}

const result = {
  buildId: build.id,
  buildVersion,
  processingState: build.attributes?.processingState,
  internalBuildState: detail?.data?.attributes?.internalBuildState,
  debugGroupId: debugGroup.id,
  debugGroupVersions: (groupBuilds?.data ?? [])
    .map((item) => item.attributes?.version),
  attached: available,
};
console.log(JSON.stringify(result, null, 2));
if (!available) {
  throw new Error(`Build ${buildVersion} did not become available in Debug.`);
}
