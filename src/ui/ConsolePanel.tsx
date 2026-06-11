import * as React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import type { ConsoleEntry } from '../engine/types';
import { colors, radius, space } from './theme';

interface ConsolePanelProps {
  entries: ConsoleEntry[];
  onClear: () => void;
}

const LEVEL_COLOR: Record<ConsoleEntry['level'], string> = {
  log: colors.textDim,
  info: colors.mono,
  warn: colors.warn,
  error: colors.danger,
};

export function ConsolePanel({ entries, onClear }: ConsolePanelProps) {
  return (
    <View style={styles.wrap}>
      <View style={styles.header}>
        <Text style={styles.title}>Console ({entries.length})</Text>
        <Pressable onPress={onClear} hitSlop={8}>
          <Text style={styles.clear}>清除</Text>
        </Pressable>
      </View>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>
        {entries.length === 0 ? (
          <Text style={styles.empty}>沒有輸出。console.log / 錯誤會顯示在這裡。</Text>
        ) : (
          entries.map((e, i) => (
            <Text key={i} style={[styles.line, { color: LEVEL_COLOR[e.level] }]}>
              {e.level === 'error' ? '✕ ' : e.level === 'warn' ? '⚠ ' : '› '}
              {e.message}
            </Text>
          ))
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { backgroundColor: colors.surface, borderRadius: radius.md, borderWidth: 1, borderColor: colors.border },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: space.md,
    paddingVertical: space.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  title: { color: colors.text, fontWeight: '700', fontSize: 13 },
  clear: { color: colors.primary, fontSize: 12 },
  scroll: { maxHeight: 140 },
  scrollContent: { padding: space.md, gap: 4 },
  empty: { color: colors.textDim, fontSize: 12, fontStyle: 'italic' },
  line: { fontFamily: 'monospace', fontSize: 12, lineHeight: 17 },
});
