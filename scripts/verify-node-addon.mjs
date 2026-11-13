#!/usr/bin/env node
// verify-node-addon.mjs - prove that the packed npm tarball works on this platform.
//
// Run from an EMPTY project into which the tarball was installed (npm install ../pkg/*.tgz):
//   node verify-node-addon.mjs <platform-key> <native|wasm>
//
//   native  this platform has a prebuild: prebuilds/<key>/<name>.node must exist and must load
//           through @tty-pt/stele's loadNativeAddon (the loader consumers use), from the installed
//           dist/index.js. A silent fall-back to WebAssembly is a failure, not a pass.
//   wasm    no prebuild for this platform (or a WebAssembly-only package): the package must still
//           install and its entry module must import.
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const [key, mode] = process.argv.slice(2);
if (!key || !["native", "wasm"].includes(mode)) {
  console.error("usage: verify-node-addon.mjs <platform-key> <native|wasm>");
  process.exit(2);
}
if (!key.startsWith(`${process.platform}-${process.arch}`)) {
  console.error(`this runner is ${process.platform}-${process.arch} but was asked to verify ${key}`);
  process.exit(2);
}

const cwd = process.cwd();
const project = JSON.parse(readFileSync(join(cwd, "package.json"), "utf8"));
const installed = Object.entries(project.dependencies ?? {}).filter(([, spec]) => String(spec).startsWith("file:"));
if (installed.length !== 1) {
  console.error(`expected exactly one package installed from the tarball, found ${installed.length}`);
  process.exit(1);
}
const name = installed[0][0];
const dir = join(cwd, "node_modules", ...name.split("/"));
const manifest = JSON.parse(readFileSync(join(dir, "package.json"), "utf8"));

function entryOf(m) {
  const dot = m.exports?.["."] ?? m.exports;
  if (typeof dot === "string") return dot;
  if (dot && typeof dot === "object") return dot.import ?? dot.default;
  return m.main ?? "index.js";
}
const entry = join(dir, entryOf(manifest));

let failed = 0;

if (mode === "native") {
  const steleIndex = join(cwd, "node_modules", "@tty-pt", "stele", "dist", "index.js");
  if (!existsSync(steleIndex)) {
    console.error("FAIL  @tty-pt/stele is not installed: the package must declare it as a peer dependency");
    process.exit(1);
  }
  const { loadNativeAddon } = await import(pathToFileURL(steleIndex).href);
  const prebuilds = join(dir, "prebuilds", key);
  const files = existsSync(prebuilds) ? readdirSync(prebuilds).filter((f) => f.endsWith(".node")) : [];
  if (files.length === 0) {
    console.error(`FAIL  ${name} ships no prebuilds/${key}/*.node`);
    process.exit(1);
  }
  for (const file of files) {
    const addon = loadNativeAddon(pathToFileURL(entry).href, file.slice(0, -".node".length));
    const names = addon ? Object.getOwnPropertyNames(addon) : [];
    if (names.length === 0) {
      console.error(`FAIL  ${name}: ${file} did not load through loadNativeAddon`);
      failed++;
    } else {
      console.log(`ok    ${name}: ${file} loaded natively (${names.length} exports)`);
    }
  }
}

try {
  await import(pathToFileURL(entry).href);
  console.log(`ok    ${name}: entry module imports (${mode === "native" ? "native + WebAssembly" : "WebAssembly"})`);
} catch (err) {
  console.error(`FAIL  ${name}: importing ${entry} threw: ${err?.stack ?? err}`);
  failed++;
}

process.exit(failed === 0 ? 0 : 1);
