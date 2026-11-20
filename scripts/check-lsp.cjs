#!/usr/bin/env node
'use strict';

// Check an actual initialize/shutdown exchange, without opening user files.
const {spawn} = require('node:child_process');
const child = spawn(process.argv[2], ['--stdio'], {stdio: ['pipe', 'pipe', 'pipe']});
let buffer = Buffer.alloc(0);
let finished = false;
const timer = setTimeout(() => finish(1), 10000);
function finish(code) {
  if (finished) return;
  finished = true;
  clearTimeout(timer);
  child.kill();
  process.exitCode = code;
}
function send(message) {
  const body = Buffer.from(JSON.stringify({jsonrpc: '2.0', ...message}));
  child.stdin.write(`Content-Length: ${body.length}\r\n\r\n`);
  child.stdin.write(body);
}
child.on('error', () => finish(1));
child.stdin.on('error', () => finish(1));
child.on('exit', () => { if (!finished) finish(1); });
child.stderr.resume();
child.stdout.on('data', chunk => {
  buffer = Buffer.concat([buffer, chunk]);
  while (!finished) {
    const boundary = buffer.indexOf('\r\n\r\n');
    if (boundary < 0) return;
    const match = /Content-Length:\s*(\d+)/i.exec(buffer.subarray(0, boundary).toString());
    if (!match) return finish(1);
    const length = Number(match[1]);
    if (length > 8 * 1024 * 1024) return finish(1);
    if (buffer.length < boundary + 4 + length) return;
    let message;
    try { message = JSON.parse(buffer.subarray(boundary + 4, boundary + 4 + length)); }
    catch { return finish(1); }
    buffer = buffer.subarray(boundary + 4 + length);
    if (message.id === 1) {
      if (message.error || !message.result?.capabilities) return finish(1);
      send({method: 'initialized', params: {}});
      send({id: 2, method: 'shutdown', params: null});
    } else if (message.id === 2) {
      send({method: 'exit'});
      finish(message.error ? 1 : 0);
    }
  }
});
send({id: 1, method: 'initialize', params: {
  processId: null, rootUri: null, capabilities: {},
  clientInfo: {name: 'dotfiles-doctor'},
}});
