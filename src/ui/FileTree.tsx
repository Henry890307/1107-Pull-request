import * as React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { FileMap } from '../engine/types';
import { colors, radius, space } from './theme';

interface FileTreeProps {
  files: FileMap;
  entry: string;
  selected: string | null;
  onSelect: (path: string) => void;
}

function iconFor(path: string): string {
  if (/\.tsx?$/.test(path)) return '🟦';
  if (/\.jsx?$/.test(path)) return '🟨';
  if (/\.json$/.test(path)) return '🟩';
  return '📄';
}

export function FileTree({ files, entry, selected, onSelect }: FileTreeProps) {
  const paths = React.useMemo(() => Object.keys(files).sort(), [files]);
  return (
    <View>
      {paths.map((path) => {
        const active = path === selected;
        return (
          <Pressable
            key={path}
            onPress={() => onSelect(path)}
            style={[styles.row, active && styles.rowActive]}
          >
            <Text style={styles.icon}>{iconFor(path)}</Text>
            <Text style={[styles.name, active && styles.nameActive]} numberOfLines={1}>
              {path}
            </Text>
            {path === entry ? <Text style={styles.entryTag}>entry</Text> : null}
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: space.sm,
    paddingHorizontal: space.md,
    borderRadius: radius.sm,
    gap: space.sm,
  },
  rowActive: { backgroundColor: colors.surfaceAlt },
  icon: { fontSize: 13 },
  name: { color: colors.textDim, fontSize: 13, flexShrink: 1 },
  nameActive: { color: colors.text, fontWeight: '600' },
  entryTag: {
    marginLeft: 'auto',
    color: colors.primary,
    fontSize: 10,
    fontWeight: '700',
    borderWidth: 1,
    borderColor: colors.primary,
    borderRadius: 4,
    paddingHorizontal: 5,
    paddingVertical: 1,
  },
});
