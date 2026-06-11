import { router } from 'expo-router';
import * as React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { PreviewRuntime } from '../src/engine/PreviewRuntime';
import { DEVICES, useProjectStore } from '../src/store/projectStore';
import { Button } from '../src/ui/Button';
import { ConsolePanel } from '../src/ui/ConsolePanel';
import { DeviceFrame } from '../src/ui/DeviceFrame';
import { colors, radius, space } from '../src/ui/theme';

export default function PreviewScreen() {
  const insets = useSafeAreaInsets();
  const { width: winW } = useWindowDimensions();

  const project = useProjectStore((s) => s.current());
  const runKey = useProjectStore((s) => s.runKey);
  const deviceId = useProjectStore((s) => s.deviceId);
  const orientation = useProjectStore((s) => s.orientation);
  const consoleEntries = useProjectStore((s) => s.consoleEntries);
  const setDevice = useProjectStore((s) => s.setDevice);
  const toggleOrientation = useProjectStore((s) => s.toggleOrientation);
  const run = useProjectStore((s) => s.run);
  const pushConsole = useProjectStore((s) => s.pushConsole);
  const clearConsole = useProjectStore((s) => s.clearConsole);

  const onError = React.useCallback(
    (message: string) => pushConsole({ level: 'error', message, ts: Date.now() }),
    [pushConsole],
  );

  if (!project) {
    return (
      <View style={styles.center}>
        <Text style={styles.dim}>沒有開啟的專案。</Text>
        <Button label="回到專案列表" variant="ghost" onPress={() => router.replace('/')} />
      </View>
    );
  }

  const device = DEVICES.find((d) => d.id === deviceId) ?? DEVICES[0];
  const frameW = (orientation === 'portrait' ? device.width : device.height) + 16;
  const scale = Math.min(1, (winW - space.lg * 2) / frameW);

  return (
    <View style={[styles.container, { paddingBottom: insets.bottom + space.md }]}>
      <View style={styles.toolbar}>
        <View style={styles.chips}>
          {DEVICES.map((d) => (
            <Pressable
              key={d.id}
              onPress={() => setDevice(d.id)}
              style={[styles.chip, d.id === deviceId && styles.chipActive]}
            >
              <Text style={[styles.chipText, d.id === deviceId && styles.chipTextActive]}>
                {d.label}
              </Text>
            </Pressable>
          ))}
        </View>
        <View style={styles.actions}>
          <Pressable onPress={toggleOrientation} style={styles.iconBtn}>
            <Text style={styles.iconText}>⟳ 旋轉</Text>
          </Pressable>
          <Pressable onPress={run} style={styles.iconBtn}>
            <Text style={styles.iconText}>↻ 重跑</Text>
          </Pressable>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.stage} maximumZoomScale={1}>
        <DeviceFrame device={device} orientation={orientation} scale={scale}>
          <PreviewRuntime
            files={project.files}
            entry={project.entry}
            runKey={runKey}
            onConsole={pushConsole}
            onError={onError}
          />
        </DeviceFrame>
      </ScrollView>

      <ConsolePanel entries={consoleEntries} onClear={clearConsole} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg, padding: space.lg, gap: space.md },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: space.md, backgroundColor: colors.bg },
  dim: { color: colors.textDim },
  toolbar: { gap: space.sm },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm },
  chip: {
    paddingVertical: 6,
    paddingHorizontal: space.md,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipText: { color: colors.textDim, fontSize: 12, fontWeight: '600' },
  chipTextActive: { color: colors.primaryText },
  actions: { flexDirection: 'row', gap: space.sm },
  iconBtn: {
    paddingVertical: 6,
    paddingHorizontal: space.md,
    borderRadius: radius.sm,
    backgroundColor: colors.surfaceAlt,
  },
  iconText: { color: colors.text, fontSize: 12, fontWeight: '600' },
  stage: { alignItems: 'center', justifyContent: 'center', paddingVertical: space.md, flexGrow: 1 },
});
