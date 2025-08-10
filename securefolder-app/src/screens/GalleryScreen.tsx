import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, Image, TouchableOpacity, StyleSheet } from 'react-native';
import { getLocalIndex, decryptFileToTemp } from '@/services/localStore';

export default function GalleryScreen({ route }: any) {
  const [items, setItems] = useState<any[]>([]);
  const filterKey = route.params?.filter as string | undefined;

  useEffect(() => {
    (async () => {
      const idx = await getLocalIndex();
      let list = idx.items;
      if (filterKey === 'photos') list = list.filter(i => i.type === 'image');
      if (filterKey === 'videos') list = list.filter(i => i.type === 'video');
      if (filterKey === 'audio') list = list.filter(i => i.type === 'audio');
      if (filterKey === 'documents') list = list.filter(i => i.type === 'note');
      setItems(list.reverse());
    })();
  }, [route.params]);

  const renderItem = ({ item }: any) => (
    <View style={styles.cell}>
      {item.thumbnailUri ? (
        <Image source={{ uri: item.thumbnailUri }} style={styles.thumb} />
      ) : (
        <View style={[styles.thumb, { backgroundColor: '#e5e7eb' }]} />
      )}
      <Text style={styles.caption}>{new Date(item.createdAt).toLocaleDateString()}</Text>
    </View>
  );

  return (
    <View style={{ flex: 1, backgroundColor: '#fff', padding: 16 }}>
      <FlatList
        data={items}
        keyExtractor={(i) => i.id}
        numColumns={2}
        columnWrapperStyle={{ gap: 12 }}
        contentContainerStyle={{ gap: 12 }}
        renderItem={renderItem}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  cell: { flex: 1 },
  thumb: { width: '100%', aspectRatio: 1.2, borderRadius: 12 },
  caption: { marginTop: 6, color: '#6b7280' }
});