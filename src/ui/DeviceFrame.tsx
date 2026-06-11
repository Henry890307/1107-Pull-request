import * as React from 'react';
import { StyleSheet, View } from 'react-native';
import type { DevicePreset, Orientation } from '../store/projectStore';

interface DeviceFrameProps {
  device: DevicePreset;
  orientation: Orientation;
  /** scale factor to fit available space (1 = actual logical px) */
  scale?: number;
  children: React.ReactNode;
}

/**
 * Renders children inside a phone-shaped frame at the device's logical size,
 * optionally scaled to fit. The inner area is a real RN surface so previewed
 * `flex: 1` layouts fill it exactly like on a real screen.
 */
export function DeviceFrame({ device, orientation, scale = 1, children }: DeviceFrameProps) {
  const portrait = orientation === 'portrait';
  const w = portrait ? device.width : device.height;
  const h = portrait ? device.height : device.width;

  return (
    <View
      style={[
        styles.frame,
        { width: w + 16, height: h + 16, borderRadius: device.radius + 8, transform: [{ scale }] },
      ]}
    >
      <View style={[styles.screen, { width: w, height: h, borderRadius: device.radius }]}>
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  frame: {
    backgroundColor: '#000',
    padding: 8,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOpacity: 0.5,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 12 },
    elevation: 12,
  },
  screen: {
    overflow: 'hidden',
    backgroundColor: '#fff',
  },
});
