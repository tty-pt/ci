#!/usr/bin/env node
// verify-node-addon.mjs - prove that an installed npm package really loads its native addon.
//
// Run from an EMPTY project into which the packed tarball was installed:
//   node verify-node-addon.mjs <platform-key>        (e.g. linux-x64, darwin-arm64, win32-x64)
//
// For every @tty-pt package that ships prebuilds/<key>/<name>.node it asks @tty-pt/stele's
// loadNativeAddon (the loader consumers use) for that addon, from the installed dist/index.js,
// and fails unless a real addon with exports comes back. A silent fall-back to WebAssembly is
// therefore a CI failure, not a pass.
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const key = process.argv[2];
if (!key) {
  console.error("usage: verify-node-addon.mjs <platform-key>");
  process.exit(2);
}

const here = process.platform === "win32" ? "win32" : process.platform;
const expectedKey = `${here}-${process.arch}`;
if (!key.startsWith(expectedKey)) {
  console.error(`this runner is ${expectedKey} but was asked to verify ${key}`);
  process.exit(2);
}

const scope = join(process.cwd(), "node_modules", "@tty-pt");
const steleIndex = join(scope, "stele", "dist", "index.js");
if (!existsSync(steleIndex)) {
  console.error("@tty-pt/stele is not installed: the package must declare it as a peer dependency");
  process.exit(1);
}
const { loadNativeAddon } = await import(pathToFileURL(steleIndex).href);

let checked = 0;
let failed = 0;
for (const pkg of readdirSync(scope)) {
  const dir = join(scope, pkg, "prebuilds", key);
  if (!existsSync(dir)) continue;
  for (const file of readdirSync(dir)) {
    if (!file.endsWith(".node")) continue;
    const name = file.slice(0, -".node".length);
    const entry = join(scope, pkg, "dist", "index.js");
    const addon = loadNativeAddon(pathToFileURL(entry).href, name);
    checked++;
    const names = addon ? Object.getOwnPropertyNames(addon) : [];
    if (names.length === 0) {
      console.error(`FAIL  @tty-pt/${pkg}: loadNativeAddon("${name}") did not return a working addon`);
      failed++;
    } else {
      console.log(`ok    @tty-pt/${pkg}: ${name}.node loaded (${names.join(", ")})`);
    }
  }
}

if (checked === 0) {
  console.error(`FAIL  no prebuilds/${key}/*.node found in any installed @tty-pt package`);
  process.exit(1);
}
process.exit(failed === 0 ? 0 : 1);
