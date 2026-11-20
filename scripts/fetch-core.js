// Build-time fetcher: pulls service binaries under neutral names into ./bin.
// No third-party deps (https + zlib only). Fail-soft: never break the build.
const https = require('https');
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

const BIN = path.join(__dirname, '..', 'bin');
const arch = process.arch === 'arm64' ? 'arm64' : 'amd64';
const xArch = arch === 'arm64' ? 'arm64-v8a' : '64';

// name -> { url, entry (name inside zip), out }
const JOBS = [
  {
    out: 'webd',
    entry: 'xray',
    url: `https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xArch}.zip`,
  },
  {
    out: 'statsd',
    entry: 'nezha-agent',
    url: `https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_${arch}.zip`,
  },
];

function get(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    if (redirects > 8) return reject(new Error('too many redirects'));
    https
      .get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          res.resume();
          return resolve(get(res.headers.location, redirects + 1));
        }
        if (res.statusCode !== 200) {
          res.resume();
          return reject(new Error('HTTP ' + res.statusCode + ' for ' + url));
        }
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => resolve(Buffer.concat(chunks)));
      })
      .on('error', reject);
  });
}

// Minimal ZIP reader via the central directory (reliable sizes/offsets).
function unzipEntry(buf, wantName) {
  // Locate End Of Central Directory record (sig 0x06054b50), scan from tail.
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0 && i > buf.length - 22 - 65536; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('no EOCD');
  const cdCount = buf.readUInt16LE(eocd + 10);
  let p = buf.readUInt32LE(eocd + 16); // central dir offset
  for (let n = 0; n < cdCount; n++) {
    if (buf.readUInt32LE(p) !== 0x02014b50) throw new Error('bad central header');
    const method = buf.readUInt16LE(p + 10);
    const compSize = buf.readUInt32LE(p + 20);
    const fnLen = buf.readUInt16LE(p + 28);
    const exLen = buf.readUInt16LE(p + 30);
    const cmLen = buf.readUInt16LE(p + 32);
    const lho = buf.readUInt32LE(p + 42);
    const name = buf.toString('utf8', p + 46, p + 46 + fnLen);
    const base = name.split('/').pop();
    if (base === wantName) {
      // read local header to find real data start
      if (buf.readUInt32LE(lho) !== 0x04034b50) throw new Error('bad local header');
      const lfn = buf.readUInt16LE(lho + 26);
      const lex = buf.readUInt16LE(lho + 28);
      const dataStart = lho + 30 + lfn + lex;
      const comp = buf.slice(dataStart, dataStart + compSize);
      if (method === 0) return comp;
      if (method === 8) return zlib.inflateRawSync(comp);
      throw new Error('unsupported zip method ' + method);
    }
    p += 46 + fnLen + exLen + cmLen;
  }
  throw new Error('entry not found: ' + wantName);
}

(async () => {
  try { fs.mkdirSync(BIN, { recursive: true }); } catch (e) {}
  for (const j of JOBS) {
    const dst = path.join(BIN, j.out);
    try {
      if (fs.existsSync(dst) && fs.statSync(dst).size > 1000000) {
        console.log('[fetch] have', j.out);
        continue;
      }
      console.log('[fetch] downloading', j.out);
      const zip = await get(j.url);
      const bin = unzipEntry(zip, j.entry);
      fs.writeFileSync(dst, bin);
      fs.chmodSync(dst, 0o755);
      console.log('[fetch] wrote', j.out, bin.length, 'bytes');
    } catch (e) {
      console.log('[fetch] skip', j.out, '-', e.message);
    }
  }
})();
