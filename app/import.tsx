import { router } from 'expo-router';
import * as React from 'react';
import {
   KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import {
  ImportResult,
  importFromFiles,
  importFromPaste,
  importFromZip,
} from '../src/io/importers';
import { useProjectStore } from '../src/store/projectStore';
import { Button } from '../src/ui/Button';
import { colors, radius, space } from '../src/ui/theme';

const STARTER = `import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function App() {
  return (
    <View style={styles.c}>
      <Text style={styles.t}>Hello DO Flow 👋</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  c: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#0f172a' },
  t: { color: '#fff', fontSize: 24, fontWeight: '700' },
});`;

export default function ImportScreen() {
  const createProject = useProjectStore((s) => s.createProject);
  const [code, setCode] = React.useState(STARTER);
  const [busy, setBusy] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  const commit = (result: ImportResult) => {
    createProject(result.suggestedName, result.files, result.entry);
    router.replace('/editor');
  };

  const handlePaste = () => {
    if (!code.trim()) {
      setError('請先貼上程式碼');
      return;
    }
    commit(importFromPaste(code));
  };

  const pick = async (fn: () => Promise<ImportResult | null>) => {
    setError(null);
    setBusy(true);
    try {
      const result = await fn();
      if (result) commit(result);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.label}>方法一 · 貼上單一檔案</Text>
        <TextInput
          style={styles.editor}
          value={code}
          onChangeText={setCode}
          multiline
          autoCapitalize="none"
          autoCorrect={false}
          spellCheck={false}
          placeholder="在此貼上 App.tsx 內容…"
          placeholderTextColor={colors.textDim}
        />
        <Button label="用這段程式碼建立專案" onPress={handlePaste} />

        <View style={styles.divider} />

        <Text style={styles.label}>方法二 · 從裝置選檔</Text>
        <Button
          label="選擇程式碼檔（可多選）"
          variant="ghost"
          disabled={busy}
          onPress={() => pick(importFromFiles)}
        />
        <Button
          label="匯入 .zip 專案"
          variant="ghost"
          disabled={busy}
          onPress={() => pick(importFromZip)}
        />

        {error ? <Text style={styles.error}>⚠️ {error}</Text> : null}
        <Text style={styles.hint}>
          支援 .ts / .tsx / .js / .jsx。可用套件：react、react-native、react-native-safe-area-context。
        </Text>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: colors.bg },
  content: { padding: space.lg, gap: space.md },
  label: { color: colors.text, fontWeight: '700', fontSize: 14 },
  editor: {
    minHeight: 220,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    padding: space.md,
    color: colors.mono,
    fontFamily: 'monospace',
    fontSize: 13,
    textAlignVertical: 'top',
  },
  divider: { height: 1, backgroundColor: colors.border, marginVertical: space.sm },
  error: { color: colors.danger, fontSize: 13 },
  hint: { color: colors.textDim, fontSize: 12, lineHeight: 18, marginTop: space.sm },
});
