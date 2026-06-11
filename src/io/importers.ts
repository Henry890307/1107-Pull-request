import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system';
import JSZip from 'jszip';
import { Platform } from 'react-native';
import type { FileMap } from '../engine/types';

export interface ImportResult {
  files: FileMap;
  entry: string;
  suggestedName: string;
}

const CODE_EXT = /\.(tsx?|jsx?|json)$/i;
const ENTRY_PRIORITY = ['App.tsx', 'App.jsx', 'App.js', 'index.tsx', 'index.jsx', 'index.js'];

/** Pick the most likely entry file from a file map. */
export function detectEntry(files: FileMap): string {
  const paths = Object.keys(files);
  for (const candidate of ENTRY_PRIORITY) {
    const hit = paths.find((p) => p === candidate || p.endsWith('/' + candidate));
    if (hit) return hit;
  }
  const firstCode = paths.find((p) => /\.(tsx?|jsx?)$/i.test(p));
  return firstCode ?? paths[0] ?? 'App.tsx';
}

/** Read a picked asset's text content across web and native. */
async function readAssetText(asset: DocumentPicker.DocumentPickerAsset): Promise<string> {
  if (Platform.OS === 'web') {
    const res = await fetch(asset.uri);
    return res.text();
  }
  return FileSystem.readAsStringAsync(asset.uri);
}

/** Read a picked asset as a base64 string (for binary zip handling). */
async function readAssetBase64(asset: DocumentPicker.DocumentPickerAsset): Promise<string> {
  if (Platform.OS === 'web') {
    const res = await fetch(asset.uri);
    const buf = await res.arrayBuffer();
    let binary = '';
    const bytes = new Uint8Array(buf);
    for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
    return globalThis.btoa(binary);
  }
  return FileSystem.readAsStringAsync(asset.uri, { encoding: FileSystem.EncodingType.Base64 });
}

/** Single pasted file becomes an App.tsx project. */
export function importFromPaste(code: string): ImportResult {
  return { files: { 'App.tsx': code }, entry: 'App.tsx', suggestedName: '貼上的程式碼' };
}

/** Pick one or more individual source files. Returns null if cancelled. */
export async function importFromFiles(): Promise<ImportResult | null> {
  const res = await DocumentPicker.getDocumentAsync({
    multiple: true,
    copyToCacheDirectory: true,
    type: ['text/*', 'application/javascript', 'application/json', '*/*'],
  });
  if (res.canceled || !res.assets?.length) return null;

  const files: FileMap = {};
  for (const asset of res.assets) {
    if (!CODE_EXT.test(asset.name)) continue;
    files[asset.name] = await readAssetText(asset);
  }
  if (!Object.keys(files).length) {
    throw new Error('沒有可用的程式碼檔（支援 .ts/.tsx/.js/.jsx/.json）');
  }
  return { files, entry: detectEntry(files), suggestedName: res.assets[0].name.replace(CODE_EXT, '') };
}

/** Strip a common leading directory shared by every path (e.g. "my-app/"). */
function stripCommonRoot(files: FileMap): FileMap {
  const paths = Object.keys(files);
  if (paths.length < 2) return files;
  const firstSeg = paths[0].split('/')[0];
  if (!firstSeg || !paths.every((p) => p.startsWith(firstSeg + '/'))) return files;
  const out: FileMap = {};
  for (const [p, src] of Object.entries(files)) out[p.slice(firstSeg.length + 1)] = src;
  return out;
}

/** Pick a .zip project and extract its code files. Returns null if cancelled. */
export async function importFromZip(): Promise<ImportResult | null> {
  const res = await DocumentPicker.getDocumentAsync({
    multiple: false,
    copyToCacheDirectory: true,
    type: ['application/zip', 'application/x-zip-compressed', '*/*'],
  });
  if (res.canceled || !res.assets?.length) return null;
  const asset = res.assets[0];

  const base64 = await readAssetBase64(asset);
  const zip = await JSZip.loadAsync(base64, { base64: true });

  let files: FileMap = {};
  const entries = Object.values(zip.files).filter(
    (f) => !f.dir && CODE_EXT.test(f.name) && !f.name.includes('node_modules/'),
  );
  for (const file of entries) {
    files[file.name] = await file.async('string');
  }
  if (!Object.keys(files).length) {
    throw new Error('zip 內找不到程式碼檔（已忽略 node_modules）');
  }
  files = stripCommonRoot(files);
  return { files, entry: detectEntry(files), suggestedName: asset.name.replace(/\.zip$/i, '') };
}
