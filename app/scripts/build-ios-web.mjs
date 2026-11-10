import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const output = path.join(root, "ios-web");
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await writeFile(
  path.join(output, "index.html"),
  await readFile(path.join(root, "index.html"), "utf8"),
  "utf8",
);
if (await import("node:fs/promises").then(fs => fs.stat(path.join(root, "vendor")).catch(() => null))) {
  await cp(path.join(root, "vendor"), path.join(output, "vendor"), { recursive: true });
}
console.log("iOS web payload generated.");
