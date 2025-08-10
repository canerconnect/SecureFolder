import React, { useEffect, useState } from 'react';
import { View, Text, Switch, StyleSheet, TouchableOpacity } from 'react-native';
import { signOutUser } from '@/services/auth';
import { getSyncEnabled, setSyncEnabled, syncNow } from '@/services/sync';

export default function SettingsScreen() {
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    getSyncEnabled().then(setEnabled);
  }, []);

  const onToggle = async (v: boolean) => {
    setEnabled(v);
    await setSyncEnabled(v);
    if (v) await syncNow();
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Einstellungen</Text>

      <View style={styles.row}>
        <Text style={styles.label}>Cloud-Synchronisation</Text>
        <Switch value={enabled} onValueChange={onToggle} />
      </View>

      <TouchableOpacity style={styles.logout} onPress={signOutUser}>
        <Text style={styles.logoutText}>Abmelden</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', padding: 16 },
  title: { fontSize: 24, fontWeight: '700', marginVertical: 12 },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 16 },
  label: { fontSize: 16 },
  logout: { marginTop: 24, backgroundColor: '#F3F4F6', padding: 14, borderRadius: 12, alignItems: 'center' },
  logoutText: { color: '#EF4444', fontWeight: '700' }
});