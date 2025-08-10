import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Alert, Platform } from 'react-native';
import * as LocalAuthentication from 'expo-local-authentication';
import { ensureEncryptionKey } from '@/services/encryption';
import { getLocalIndex } from '@/services/localStore';

const categories = [
  { key: 'photos', title: 'Fotos', countKey: 'photosCount' },
  { key: 'documents', title: 'Dokumente', countKey: 'documentsCount' },
  { key: 'videos', title: 'Videos', countKey: 'videosCount' },
  { key: 'audio', title: 'Sprachmemos', countKey: 'audioCount' }
];

export default function SecureFolderScreen({ navigation }: any) {
  const [unlocked, setUnlocked] = useState(false);
  const [counts, setCounts] = useState<any>({});

  useEffect(() => {
    (async () => {
      if (Platform.OS === 'web') {
        setUnlocked(true);
      } else {
        const res = await LocalAuthentication.authenticateAsync({
          promptMessage: 'Sicherer Ordner entsperren',
          fallbackLabel: 'PIN eingeben'
        });
        if (!res.success) {
          Alert.alert('Authentifizierung fehlgeschlagen');
          return;
        }
        setUnlocked(true);
      }
      await ensureEncryptionKey();
      const idx = await getLocalIndex();
      setCounts({
        photosCount: idx.items.filter(i => i.type === 'image').length,
        videosCount: idx.items.filter(i => i.type === 'video').length,
        audioCount: idx.items.filter(i => i.type === 'audio').length,
        documentsCount: idx.items.filter(i => i.type === 'note').length
      });
    })();
  }, []);

  if (!unlocked) {
    return <View style={styles.container} />;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Sicherer Ordner</Text>
      <View style={{ height: 16 }} />
      <FlatList
        data={categories}
        numColumns={2}
        columnWrapperStyle={{ gap: 16 }}
        contentContainerStyle={{ gap: 16 }}
        keyExtractor={(item) => item.key}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.card} onPress={() => navigation.navigate('Gallery', { filter: item.key })}>
            <Text style={styles.cardTitle}>{item.title}</Text>
            <Text style={styles.cardSubtitle}>{counts[item.countKey] ?? 0} Elemente</Text>
          </TouchableOpacity>
        )}
      />
      <TouchableOpacity style={styles.addButton} onPress={() => navigation.navigate('Upload')}>
        <Text style={styles.addButtonText}>+ Hinzufügen</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', padding: 16 },
  title: { fontSize: 28, fontWeight: '700', marginTop: 8 },
  card: { flex: 1, backgroundColor: '#f6f7fb', padding: 20, borderRadius: 20, minHeight: 140 },
  cardTitle: { fontSize: 18, fontWeight: '600' },
  cardSubtitle: { marginTop: 6, color: '#6b7280' },
  addButton: { position: 'absolute', bottom: 24, left: 16, right: 16, backgroundColor: '#2563EB', padding: 18, borderRadius: 22, alignItems: 'center' },
  addButtonText: { color: '#fff', fontWeight: '700', fontSize: 16 }
});