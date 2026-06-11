import * as Babel from '@babel/standalone';

/**
 * Transpile a single user file (JSX / TS / TSX) into CommonJS that our module
 * system can execute. Uses the classic React runtime so `React` only needs to
 * be in scope (no implicit `react/jsx-runtime` dependency).
 */
export function transpile(code: string, filename: string): string {
  const isTsx = filename.endsWith('.tsx') || filename.endsWith('.jsx');
  const isTs = filename.endsWith('.ts') || filename.endsWith('.tsx');

  const presets: unknown[] = [['react', { runtime: 'classic' }]];
  if (isTs) {
    presets.push(['typescript', { isTSX: isTsx, allExtensions: true }]);
  }

  const result = Babel.transform(code, {
    filename,
    presets: presets as never,
    plugins: ['transform-modules-commonjs'],
    sourceType: 'module',
    retainLines: true,
  });

  if (!result || typeof result.code !== 'string') {
    throw new Error(`轉譯失敗：${filename}`);
  }
  return result.code;
}
