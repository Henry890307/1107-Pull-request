import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { colors } from '../src/ui/theme';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: colors.surface },
          headerTintColor: colors.text,
          headerTitleStyle: { fontWeight: '700' },
          contentStyle: { backgroundColor: colors.bg },
        }}
      >
        <Stack.Screen name="index" options={{ title: 'DO Flow' }} />
        <Stack.Screen name="import" options={{ title: '匯入程式碼', presentation: 'modal' }} />
        <Stack.Screen name="editor" options={{ title: '專案' }} />
        <Stack.Screen name="preview" options={{ title: '即時預覽' }} />
        <Stack.Screen name="settings" options={{ title: '設定' }} />
      </Stack>
    </SafeAreaProvider>
  );
}
