#!/usr/bin/env node
'use strict';
const {execFileSync} = require('node:child_process');
const spec = process.argv[2];
const names = {
  '@openai/codex@latest': '@openai/codex-linux-x64',
  '@anthropic-ai/claude-code@latest': '@anthropic-ai/claude-code-linux-x64',
};
const name = names[spec];
if (!name) throw new Error('Unsupported native package');
function view(packageSpec) {
  return JSON.parse(execFileSync('npm', ['view', packageSpec, '--json',
    '--fetch-retries=1', '--fetch-timeout=15000'], {encoding: 'utf8', timeout: 45000}));
}
const dependency = view(spec).optionalDependencies?.[name];
if (typeof dependency !== 'string') throw new Error('Missing native package metadata');
const resolved = dependency.startsWith('npm:') ? dependency.slice(4) : `${name}@${dependency}`;
const native = view(resolved);
const url = new URL(native.dist.tarball);
if (url.protocol !== 'https:' || url.username || url.password || url.href.includes('|')) {
  throw new Error('Invalid native package URL');
}
const integrity = native.dist.integrity;
if (!/^sha512-[A-Za-z0-9+/]+={0,2}$/.test(integrity)) throw new Error('SHA512 integrity required');
const hash = Buffer.from(integrity.slice(7), 'base64').toString('hex');
if (hash.length !== 128 || !/^[A-Za-z0-9._+-]+$/.test(native.version)) throw new Error('Invalid metadata');
console.log([url.href, hash, native.version, name].join('|'));
