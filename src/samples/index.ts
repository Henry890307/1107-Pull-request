import type { FileMap } from '../engine/types';

export interface SampleDefinition {
  id: string;
  name: string;
  entry: string;
  files: FileMap;
}

const counterApp = `import React, { useState } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';

export default function App() {
  const [count, setCount] = useState(0);
  return (
    <View style={styles.container}>
      <Text style={styles.title}>DO Flow 計數器</Text>
      <Text style={styles.count}>{count}</Text>
      <View style={styles.row}>
        <Pressable style={styles.btn} onPress={() => setCount(c => c - 1)}>
          <Text style={styles.btnText}>－</Text>
        </Pressable>
        <Pressable style={styles.btn} onPress={() => setCount(c => c + 1)}>
          <Text style={styles.btnText}>＋</Text>
        </Pressable>
      </View>
      <Pressable onPress={() => setCount(0)}>
        <Text style={styles.reset}>重設</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#0f172a', gap: 16 },
  title: { color: '#94a3b8', fontSize: 16 },
  count: { color: '#f8fafc', fontSize: 72, fontWeight: '800' },
  row: { flexDirection: 'row', gap: 16 },
  btn: { width: 72, height: 72, borderRadius: 36, backgroundColor: '#6366f1', alignItems: 'center', justifyContent: 'center' },
  btnText: { color: '#fff', fontSize: 32, fontWeight: '700' },
  reset: { color: '#64748b', marginTop: 8 },
});
`;

const todoApp = `import React, { useState } from 'react';
import { SafeAreaView, View, Text, TextInput, Pressable, FlatList, StyleSheet } from 'react-native';
import { TodoItem } from './TodoItem';

export default function App() {
  const [text, setText] = useState('');
  const [todos, setTodos] = useState([
    { id: '1', label: '試試 DO Flow', done: true },
    { id: '2', label: '丟一份 React Native 程式碼', done: false },
  ]);

  const add = () => {
    if (!text.trim()) return;
    setTodos(t => [...t, { id: String(Date.now()), label: text.trim(), done: false }]);
    setText('');
  };
  const toggle = (id) => setTodos(t => t.map(x => x.id === id ? { ...x, done: !x.done } : x));

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.header}>待辦清單</Text>
      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          placeholder="新增待辦…"
          placeholderTextColor="#94a3b8"
          value={text}
          onChangeText={setText}
          onSubmitEditing={add}
        />
        <Pressable style={styles.addBtn} onPress={add}>
          <Text style={styles.addText}>新增</Text>
        </Pressable>
      </View>
      <FlatList
        data={todos}
        keyExtractor={item => item.id}
        renderItem={({ item }) => <TodoItem item={item} onToggle={toggle} />}
        ListEmptyComponent={<Text style={styles.empty}>還沒有待辦</Text>}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8fafc', padding: 16 },
  header: { fontSize: 28, fontWeight: '800', color: '#0f172a', marginBottom: 16 },
  inputRow: { flexDirection: 'row', gap: 8, marginBottom: 16 },
  input: { flex: 1, backgroundColor: '#fff', borderRadius: 10, paddingHorizontal: 14, height: 44, borderWidth: 1, borderColor: '#e2e8f0', color: '#0f172a' },
  addBtn: { backgroundColor: '#6366f1', borderRadius: 10, paddingHorizontal: 18, alignItems: 'center', justifyContent: 'center' },
  addText: { color: '#fff', fontWeight: '700' },
  empty: { color: '#94a3b8', textAlign: 'center', marginTop: 24 },
});
`;

const todoItem = `import React from 'react';
import { Pressable, View, Text, StyleSheet } from 'react-native';

export function TodoItem({ item, onToggle }) {
  return (
    <Pressable style={styles.row} onPress={() => onToggle(item.id)}>
      <View style={[styles.box, item.done && styles.boxDone]}>
        {item.done ? <Text style={styles.check}>✓</Text> : null}
      </View>
      <Text style={[styles.label, item.done && styles.labelDone]}>{item.label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, gap: 12 },
  box: { width: 24, height: 24, borderRadius: 6, borderWidth: 2, borderColor: '#cbd5e1', alignItems: 'center', justifyContent: 'center' },
  boxDone: { backgroundColor: '#6366f1', borderColor: '#6366f1' },
  check: { color: '#fff', fontSize: 14, fontWeight: '800' },
  label: { fontSize: 16, color: '#0f172a' },
  labelDone: { textDecorationLine: 'line-through', color: '#94a3b8' },
});
`;

export const SAMPLES: SampleDefinition[] = [
  {
    id: 'sample-counter',
    name: '範例：計數器 (單檔)',
    entry: 'App.tsx',
    files: { 'App.tsx': counterApp },
  },
  {
    id: 'sample-todo',
    name: '範例：待辦清單 (多檔)',
    entry: 'App.tsx',
    files: { 'App.tsx': todoApp, 'TodoItem.tsx': todoItem },
  },
];
