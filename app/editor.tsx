import { router } from 'expo-router';
import * as React from 'react';
import { ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useProjectStore } from '../src/store/projectStore';
import { Button } from '../src/ui/Button';
import { FileTree } from '../src/ui/FileTree';
import { colors, radius, space } from '../src/ui/theme';

export default function EditorScreen() {
  const insets = useSafeAreaInsets();
  const project = useProjectStore((s) => s.current());
  const selectedFile = useProjectStore((s) => s.selectedFile);
  const setSelectedFile = useProjectStore((s) => s.setSelectedFile);
  const updateFile = useProjectStore((s) => s.updateFile);
  const run = useProjectStore((s) => s.run);

  if (!project) {
    return (
      <View style={styles.center}>
        <Text style={styles.dim}>沒有開啟的專案。</Text>
        <Button label="回到專案列表" variant="ghost" onPress={() => router.replace('/')} />
      </View>
    );
  }

  const activePath = selectedFile && project.files[selectedFile] !== undefined
    ? selectedFile
    : project.entry;
  const source = project.files[activePath] ?? '';

  const preview = () => {
    run();
    router.push('/preview');
  };

  return (
    <View style={[styles.container, { paddingBottom: insets.bottom + space.md }]}>
      <View style={styles.topBar}>
        <Text style={styles.name} numberOfLines={1}>{project.name}</Text>
        <Button label="▶ 預覽" onPress={preview} style={styles.previewBtn} />
      </View>

      <Text style={styles.sectionLabel}>檔案</Text>
      <View style={styles.treeBox}>
        <ScrollView style={styles.treeScroll}>
          <FileTree
            files={project.files}
            entry={project.entry}
            selected={activePath}
            onSelect={setSelectedFile}
          />
        </ScrollView>
      </View>

      <Text style={styles.sectionLabel}>{activePath}</Text>
      <TextInput
        style={styles.editor}
        value={source}
        onChangeText={(text) => updateFile(activePath, text)}
        multiline
        autoCapitalize="none"
        autoCorrect={false}
        spellCheck={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg, padding: space.lg, gap: space.sm },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: space.md, backgroundColor: colors.bg },
  dim: { color: colors.textDim },
  topBar: { flexDirection: 'row', alignItems: 'center', gap: space.md },
  name: { flex: 1, color: colors.text, fontSize: 18, fontWeight: '700' },
  previewBtn: { paddingVertical: space.sm },
  sectionLabel: { color: colors.textDim, fontSize: 12, fontWeight: '700', marginTop: space.sm },
  treeBox: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    padding: space.xs,
  },
  treeScroll: { maxHeight: 150 },
  editor: {
    flex: 1,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    padding: space.md,
    color: colors.mono,
    fontFamily: 'monospace',
    fontSize: 13,
    lineHeight: 19,
    textAlignVertical: 'top',
  },
});
