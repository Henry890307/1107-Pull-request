import * as React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { supportedModules } from '../src/engine/hostModules';
import { DEVICES, useProjectStore } from '../src/store/projectStore';
import { colors, radius, space } from '../src/ui/theme';

export default function SettingsScreen() {
  const deviceId = useProjectStore((s) => s.deviceId);
  const setDevice = useProjectStore((s) => s.setDevice);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.section}>預設裝置</Text>
      <View style={styles.card}>
        {DEVICES.map((d) => (
          <Pressable key={d.id} style={styles.row} onPress={() => setDevice(d.id)}>
            <Text style={styles.rowLabel}>{d.label}</Text>
            <Text style={styles.rowValue}>
              {d.id === deviceId ? '✓' : `${d.width}×${d.height}`}
            </Text>
          </Pressable>
        ))}
      </View>

      <Text style={styles.section}>可用套件</Text>
      <View style={styles.card}>
        {supportedModules().map((m) => (
          <View key={m} style={styles.row}>
            <Text style={styles.mono}>{m}</Text>
          </View>
        ))}
      </View>

      <Text style={styles.section}>關於 DO Flow</Text>
      <View style={styles.card}>
        <Text style={styles.about}>
          DO Flow 把你的 React Native 程式碼即時轉譯並渲染成可互動的 app 預覽。
          {'\n\n'}
          引擎使用 Babel 在裝置上轉譯 JSX/TS，再以受控的模組系統注入真實的 React Native
          元件來執行。
          {'\n\n'}
          ⚠️ 執行需要 JS 引擎支援 eval：在 Web 與 JSC 原生建置可用；Hermes / Expo Go
          預設停用 eval，需以 jsEngine="jsc" 建置自訂 dev client。
          {'\n\n'}
          Flutter 支援與設計檔（Figma）匯入列於後續路線圖。
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg },
  content: { padding: space.lg, gap: space.sm },
  section: { color: colors.text, fontWeight: '700', fontSize: 14, marginTop: space.md },
  card: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    overflow: 'hidden',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: space.md,
    paddingHorizontal: space.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.border,
  },
  rowLabel: { color: colors.text, fontSize: 14 },
  rowValue: { color: colors.primary, fontSize: 13, fontWeight: '600' },
  mono: { color: colors.mono, fontFamily: 'monospace', fontSize: 13 },
  about: { color: colors.textDim, fontSize: 13, lineHeight: 20, padding: space.md },
});
