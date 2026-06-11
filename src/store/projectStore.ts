import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import type { ConsoleEntry, FileMap, Project, ProjectKind } from '../engine/types';

export type DeviceId = 'iphone15' | 'iphoneSE' | 'pixel7';
export type Orientation = 'portrait' | 'landscape';

export interface DevicePreset {
  id: DeviceId;
  label: string;
  width: number;
  height: number;
  radius: number;
}

export const DEVICES: DevicePreset[] = [
  { id: 'iphone15', label: 'iPhone 15', width: 393, height: 852, radius: 48 },
  { id: 'iphoneSE', label: 'iPhone SE', width: 375, height: 667, radius: 28 },
  { id: 'pixel7', label: 'Pixel 7', width: 412, height: 915, radius: 36 },
];

interface ProjectState {
  projects: Project[];
  currentId: string | null;
  selectedFile: string | null;
  consoleEntries: ConsoleEntry[];
  runKey: number;
  deviceId: DeviceId;
  orientation: Orientation;

  // selectors
  current: () => Project | null;

  // project actions
  createProject: (name: string, files: FileMap, entry: string, kind?: ProjectKind) => string;
  deleteProject: (id: string) => void;
  openProject: (id: string) => void;
  renameProject: (id: string, name: string) => void;
  updateFile: (path: string, content: string) => void;
  setSelectedFile: (path: string) => void;

  // preview actions
  run: () => void;
  pushConsole: (entry: ConsoleEntry) => void;
  clearConsole: () => void;
  setDevice: (id: DeviceId) => void;
  toggleOrientation: () => void;
}

function uid(prefix = 'p'): string {
  return `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;
}

export const useProjectStore = create<ProjectState>()(
  persist(
    (set, get) => ({
      projects: [],
      currentId: null,
      selectedFile: null,
      consoleEntries: [],
      runKey: 0,
      deviceId: 'iphone15',
      orientation: 'portrait',

      current: () => {
        const { projects, currentId } = get();
        return projects.find((p) => p.id === currentId) ?? null;
      },

      createProject: (name, files, entry, kind = 'react-native') => {
        const id = uid();
        const now = Date.now();
        const project: Project = { id, name, files, entry, kind, createdAt: now, updatedAt: now };
        set((s) => ({
          projects: [project, ...s.projects],
          currentId: id,
          selectedFile: entry,
          consoleEntries: [],
        }));
        return id;
      },

      deleteProject: (id) =>
        set((s) => ({
          projects: s.projects.filter((p) => p.id !== id),
          currentId: s.currentId === id ? null : s.currentId,
        })),

      openProject: (id) => {
        const project = get().projects.find((p) => p.id === id);
        set({ currentId: id, selectedFile: project?.entry ?? null, consoleEntries: [] });
      },

      renameProject: (id, name) =>
        set((s) => ({
          projects: s.projects.map((p) => (p.id === id ? { ...p, name, updatedAt: Date.now() } : p)),
        })),

      updateFile: (path, content) =>
        set((s) => ({
          projects: s.projects.map((p) =>
            p.id === s.currentId
              ? { ...p, files: { ...p.files, [path]: content }, updatedAt: Date.now() }
              : p,
          ),
        })),

      setSelectedFile: (path) => set({ selectedFile: path }),

      run: () => set((s) => ({ runKey: s.runKey + 1, consoleEntries: [] })),

      pushConsole: (entry) =>
        set((s) => ({ consoleEntries: [...s.consoleEntries.slice(-199), entry] })),

      clearConsole: () => set({ consoleEntries: [] }),

      setDevice: (id) => set({ deviceId: id }),

      toggleOrientation: () =>
        set((s) => ({ orientation: s.orientation === 'portrait' ? 'landscape' : 'portrait' })),
    }),
    {
      name: 'doflow.store.v1',
      storage: createJSONStorage(() => AsyncStorage),
      // Only persist user data, not transient preview state.
      partialize: (s) => ({
        projects: s.projects,
        deviceId: s.deviceId,
        orientation: s.orientation,
      }),
    },
  ),
);
