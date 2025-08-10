import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { saveMediaToSecureStore } from '@/services/localStore';

export default function UploadScreen() {
  const addPhoto = async () => {
    const res = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, quality: 0.8 });
    if (!res.canceled && res.assets?.length) {
      await saveMediaToSecureStore(res.assets[0].uri, 'image');
      Alert.alert('Gespeichert', 'Foto wurde gesichert.');
    }
  };

  const addVideo = async () => {
    const res = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Videos });
    if (!res.canceled && res.assets?.length) {
      await saveMediaToSecureStore(res.assets[0].uri, 'video');
      Alert.alert('Gespeichert', 'Video wurde gesichert.');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Hinzufügen</Text>
      <TouchableOpacity style={styles.button} onPress={addPhoto}><Text style={styles.buttonText}>Foto auswählen</Text></TouchableOpacity>
      <TouchableOpacity style={styles.button} onPress={addVideo}><Text style={styles.buttonText}>Video auswählen</Text></TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', padding: 16 },
  title: { fontSize: 24, fontWeight: '700', marginVertical: 12 },
  button: { backgroundColor: '#DBEAFE', padding: 16, borderRadius: 14, marginTop: 12, alignItems: 'center' },
  buttonText: { color: '#1D4ED8', fontWeight: '600' }
});