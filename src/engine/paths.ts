/**
 * Minimal POSIX-style path helpers. React Native has no Node `path` module,
 * so the module system resolves relative imports with these.
 */

export function dirname(p: string): string {
  const i = p.lastIndexOf('/');
  return i <= 0 ? '' : p.slice(0, i);
}

/** Collapse "." and ".." segments. */
export function normalize(p: string): string {
  const isAbsolute = p.startsWith('/');
  const out: string[] = [];
  for (const seg of p.split('/')) {
    if (seg === '' || seg === '.') continue;
    if (seg === '..') {
      if (out.length && out[out.length - 1] !== '..') out.pop();
      else if (!isAbsolute) out.push('..');
    } else {
      out.push(seg);
    }
  }
  return (isAbsolute ? '/' : '') + out.join('/');
}

export function join(base: string, request: string): string {
  if (!base) return normalize(request);
  return normalize(base + '/' + request);
}

const EXTENSIONS = ['', '.tsx', '.ts', '.jsx', '.js', '.json'];
const INDEX_FILES = ['index.tsx', 'index.ts', 'index.jsx', 'index.js'];

/**
 * Resolve a relative `request` (e.g. "./Button") imported from `importer`
 * against the set of available file paths. Returns the matched path or null.
 */
export function resolveRelative(
  importer: string,
  request: string,
  files: Record<string, unknown>,
): string | null {
  const target = join(dirname(importer), request);
  for (const ext of EXTENSIONS) {
    if (Object.prototype.hasOwnProperty.call(files, target + ext)) return target + ext;
  }
  for (const idx of INDEX_FILES) {
    const candidate = target ? target + '/' + idx : idx;
    if (Object.prototype.hasOwnProperty.call(files, candidate)) return candidate;
  }
  return null;
}
