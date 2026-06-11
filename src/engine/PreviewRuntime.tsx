import * as React from 'react';
import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from 'react-native';
import { evaluateProject } from './moduleSystem';
import type { ConsoleEntry, FileMap } from './types';

interface PreviewRuntimeProps {
  files: FileMap;
  entry: string;
  /** bump to force a re-evaluation (the "Run" action) */
  runKey: number;
  onConsole?: (entry: ConsoleEntry) => void;
  onError?: (message: string) => void;
}

interface BoundaryProps {
  children: React.ReactNode;
  onError?: (message: string) => void;
}

/** Catches render-time errors thrown by previewed components. */
class RenderErrorBoundary extends React.Component<BoundaryProps, { error: string | null }> {
  state = { error: null as string | null };

  static getDerivedStateFromError(error: Error) {
    return { error: error?.message ?? String(error) };
  }

  componentDidCatch(error: Error) {
    this.props.onError?.(error?.message ?? String(error));
  }

  componentDidUpdate(prev: BoundaryProps) {
    if (prev.children !== this.props.children && this.state.error) {
      this.setState({ error: null });
    }
  }

  render() {
    if (this.state.error) {
      return <ErrorView title="渲染錯誤 (render error)" message={this.state.error} />;
    }
    return this.props.children;
  }
}

function ErrorView({ title, message }: { title: string; message: string }) {
  return (
    <ScrollView style={styles.errorWrap} contentContainerStyle={styles.errorContent}>
      <Text style={styles.errorTitle}>⚠️ {title}</Text>
      <Text style={styles.errorMessage}>{message}</Text>
    </ScrollView>
  );
}

/**
 * Evaluates the project and renders the resulting component. Re-evaluates
 * whenever `runKey` changes. Build/eval errors render inline; render errors are
 * caught by the boundary.
 */
export function PreviewRuntime({ files, entry, runKey, onConsole, onError }: PreviewRuntimeProps) {
  const result = React.useMemo(() => {
    try {
      const Component = evaluateProject(files, entry, { onConsole });
      return { Component, error: null as string | null };
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      return { Component: null, error: message };
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runKey]);

  React.useEffect(() => {
    if (result.error) onError?.(result.error);
  }, [result, onError]);

  if (result.error) {
    return <ErrorView title="建置錯誤 (build error)" message={result.error} />;
  }
  const { Component } = result;
  if (!Component) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator />
      </View>
    );
  }
  return (
    <RenderErrorBoundary key={runKey} onError={onError}>
      <Component />
    </RenderErrorBoundary>
  );
}

const styles = StyleSheet.create({
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  errorWrap: { flex: 1, backgroundColor: '#2b0d0d' },
  errorContent: { padding: 16 },
  errorTitle: { color: '#ff8a8a', fontWeight: '700', fontSize: 15, marginBottom: 8 },
  errorMessage: { color: '#ffd5d5', fontFamily: 'monospace', fontSize: 13, lineHeight: 18 },
});
