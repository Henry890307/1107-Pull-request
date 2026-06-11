/**
 * Whitelist of packages that user code may `import`. Each maps to a REAL module
 * provided by the host app, so previewed code renders with genuine React Native
 * components. Any package import NOT in this registry surfaces a friendly
 * "unsupported module" error in the console panel instead of crashing.
 *
 * Security note (MVP): evaluated code shares the host JS context. We constrain
 * its capability surface to this registry (no fs / native bridges exposed
 * beyond what react-native itself offers). This is not a true sandbox — see the
 * design doc roadmap for QuickJS / isolated-WebView hardening.
 */
import * as React from 'react';
import * as ReactNative from 'react-native';
import * as SafeAreaContext from 'react-native-safe-area-context';

const registry: Record<string, unknown> = {
  react: React,
  'react-native': ReactNative,
  'react-native-safe-area-context': SafeAreaContext,
};

/** Returns the host module for a package name, or `undefined` if not allowed. */
export function getHostModule(request: string): unknown | undefined {
  if (Object.prototype.hasOwnProperty.call(registry, request)) {
    return registry[request];
  }
  return undefined;
}

/** Package names available to previewed code (for UI hints / docs). */
export function supportedModules(): string[] {
  return Object.keys(registry);
}
