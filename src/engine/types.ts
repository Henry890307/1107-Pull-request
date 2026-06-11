/** path -> source code */
export type FileMap = Record<string, string>;

export type ProjectKind = 'react-native' | 'flutter';

export interface Project {
  id: string;
  name: string;
  files: FileMap;
  /** entry file path, e.g. "App.tsx" */
  entry: string;
  kind: ProjectKind;
  createdAt: number;
  updatedAt: number;
}

export type ConsoleLevel = 'log' | 'info' | 'warn' | 'error';

export interface ConsoleEntry {
  level: ConsoleLevel;
  message: string;
  ts: number;
}
