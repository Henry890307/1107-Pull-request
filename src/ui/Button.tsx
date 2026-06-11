import * as React from 'react';
import { Pressable, StyleSheet, Text, ViewStyle } from 'react-native';
import { colors, radius, space } from './theme';

interface ButtonProps {
  label: string;
  onPress: () => void;
  variant?: 'primary' | 'ghost' | 'danger';
  style?: ViewStyle;
  disabled?: boolean;
}

export function Button({ label, onPress, variant = 'primary', style, disabled }: ButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.base,
        variant === 'primary' && styles.primary,
        variant === 'ghost' && styles.ghost,
        variant === 'danger' && styles.danger,
        (pressed || disabled) && styles.dim,
        style,
      ]}
    >
      <Text
        style={[
          styles.label,
          variant === 'ghost' ? styles.ghostLabel : styles.solidLabel,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    paddingVertical: space.md,
    paddingHorizontal: space.lg,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primary: { backgroundColor: colors.primary },
  danger: { backgroundColor: colors.danger },
  ghost: { borderWidth: 1, borderColor: colors.border, backgroundColor: 'transparent' },
  dim: { opacity: 0.6 },
  label: { fontSize: 15, fontWeight: '600' },
  solidLabel: { color: colors.primaryText },
  ghostLabel: { color: colors.text },
});
