import * as React from 'react';
import { getHostModule } from './hostModules';
import { resolveRelative } from './paths';
import { transpile } from './transpile';
import type { ConsoleEntry, ConsoleLevel, FileMap } from './types';

export interface EvaluateOptions {
  onConsole?: (entry: ConsoleEntry) => void;
}

interface ModuleRecord {
  exports: Record<string, unknown>;
}

function stringifyArg(arg: unknown): string {
  if (typeof arg === 'string') return arg;
  if (arg instanceof Error) return arg.message;
  try {
    return JSON.stringify(arg);
  } catch {
    return String(arg);
  }
}

function makeConsole(onConsole?: (entry: ConsoleEntry) => void) {
  const forward = (level: ConsoleLevel) => (...args: unknown[]) => {
    onConsole?.({ level, message: args.map(stringifyArg).join(' '), ts: Date.now() });
    // Mirror to the real console so it also shows in dev tools.
    (console[level] ?? console.log)(...args);
  };
  return { log: forward('log'), info: forward('info'), warn: forward('warn'), error: forward('error') };
}

/**
 * Evaluate a virtual project (file map) starting from `entry`, resolving
 * relative imports across files and whitelisted package imports via host
 * modules. Returns the entry module's default export — expected to be a React
 * component.
 *
 * NOTE: relies on the `Function` constructor. This works on web (react-native-web)
 * and on a JSC-engine native build. Hermes / Expo Go disable runtime eval — see
 * the design doc for the jsEngine="jsc" requirement.
 */
export function evaluateProject(
  files: FileMap,
  entry: string,
  options: EvaluateOptions = {},
): React.ComponentType<unknown> {
  const cache = new Map<string, ModuleRecord>();
  const sandboxConsole = makeConsole(options.onConsole);

  function requireModule(absPath: string): Record<string, unknown> {
    const cached = cache.get(absPath);
    if (cached) return cached.exports;

    const source = files[absPath];
    if (source === undefined) throw new Error(`找不到檔案：${absPath}`);

    const record: ModuleRecord = { exports: {} };
    cache.set(absPath, record); // set early to tolerate circular deps

    const compiled = transpile(source, absPath);

    const localRequire = (request: string): unknown => {
      const host = getHostModule(request);
      if (host !== undefined) return host;
      if (request.startsWith('.')) {
        const resolved = resolveRelative(absPath, request, files);
        if (resolved) return requireModule(resolved);
        throw new Error(`找不到模組 "${request}"（路徑無法解析，來自 ${absPath}）`);
      }
      throw new Error(`尚未支援的套件 "${request}"。目前可用：react、react-native、react-native-safe-area-context`);
    };

    const moduleObj = { exports: record.exports };
    // eslint-disable-next-line no-new-func
    const fn = new Function('require', 'module', 'exports', 'console', 'React', compiled);
    fn(localRequire, moduleObj, moduleObj.exports, sandboxConsole, React);
    record.exports = moduleObj.exports as Record<string, unknown>;
    return record.exports;
  }

  const exports = requireModule(entry);
  const Component = (exports.default ?? exports) as unknown;

  if (typeof Component !== 'function') {
    throw new Error(`進入點 "${entry}" 必須 default export 一個 React 元件（function component）。`);
  }
  return Component as React.ComponentType<unknown>;
}
