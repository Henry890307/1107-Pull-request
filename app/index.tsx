import { Link, router } from 'expo-router';
import * as React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { SAMPLES } from '../src/samples';
import { useProjectStore } from '../src/store/projectStore';
import { Button } from '../src/ui/Button';
import { colors, radius, space } from '../src/ui/theme';

export default function ProjectsScreen() {
  const insets = useSafeAreaInsets();
  const projects = useProjectStore((s) => s.projects);
  const createProject = useProjectStore((s) => s.createProject);
  const openProject = useProjectStore((s) => s.openProject);
  const deleteProject = useProjectStore((s) => s.deleteProject);

  const open = (id: string) => {
    openProject(id);
    router.push('/editor');
  };

  const loadSample = (sampleId: string) => {
    const sample = SAMPLES.find((s) => s.id === sampleId);
    if (!sample) return;
    const id = createProject(sample.name, { ...sample.files }, sample.entry);
    open(id);
  };

  return (
    <View style={[styles.container, { paddingBottom: insets.bottom + space.lg }]}>
      <FlatList
        data={projects}
        keyExtractor={(p) => p.id}
        contentContainerStyle={styles.list}
        ListHeaderComponent={
          <View style={styles.header}>
            <Text style={styles.tagline}>把你的 React Native 程式碼丟進來，立刻在裝置外框裡跑起來。</Text>
            <Button label="＋ 匯入程式碼" onPress={() => router.push('/import')} />
            <Text style={styles.sectionLabel}>快速體驗範例</Text>
            <View style={styles.sampleRow}>
              {SAMPLES.map((s) => (
                <Button
                  key={s.id}
                  label={s.name}
                  variant="ghost"
                  style={styles.sampleBtn}
                  onPress={() => loadSample(s.id)}
                />
              ))}
            </View>
            <Text style={styles.sectionLabel}>我的專案</Text>
          </View>
        }
        renderItem={({ item }) => (
          <Pressable style={styles.card} onPress={() => open(item.id)}>
            <View style={styles.cardMain}>
              <Text style={styles.cardName} numberOfLines={1}>{item.name}</Text>
              <Text style={styles.cardMeta}>
                {Object.keys(item.files).length} 個檔案 · entry: {item.entry}
              </Text>
            </View>
            <Pressable hitSlop={10} onPress={() => deleteProject(item.id)}>
              <Text style={styles.delete}>刪除</Text>
            </Pressable>
          </Pressable>
        )}
        ListEmptyComponent={
          <Text style={styles.empty}>還沒有專案。匯入程式碼或載入上面的範例開始吧。</Text>
        }
      />
      <Link href="/settings" style={styles.settingsLink}>
        <Text style={styles.settingsText}>⚙︎ 設定</Text>
      </Link>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg },
  list: { padding: space.lg, gap: space.sm },
  header: { gap: space.md, marginBottom: space.sm },
  tagline: { color: colors.textDim, fontSize: 14, lineHeight: 20 },
  sectionLabel: { color: colors.text, fontWeight: '700', fontSize: 14, marginTop: space.sm },
  sampleRow: { gap: space.sm },
  sampleBtn: { alignItems: 'flex-start' },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    padding: space.md,
    gap: space.md,
  },
  cardMain: { flex: 1 },
  cardName: { color: colors.text, fontWeight: '600', fontSize: 15 },
  cardMeta: { color: colors.textDim, fontSize: 12, marginTop: 2 },
  delete: { color: colors.danger, fontSize: 13 },
  empty: { color: colors.textDim, textAlign: 'center', marginTop: space.lg, lineHeight: 20 },
  settingsLink: { position: 'absolute', top: space.md, right: space.lg },
  settingsText: { color: colors.textDim, fontSize: 13 },
});
