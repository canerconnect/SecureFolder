import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { Audio } from 'expo-av';
import { saveMediaToSecureStore } from '@/services/localStore';

export default function AudioScreen() {
  const [recording, setRecording] = useState<Audio.Recording | null>(null);

  const startRecording = async () => {
    const { status } = await Audio.requestPermissionsAsync();
    if (status !== 'granted') return;
    await Audio.setAudioModeAsync({ allowsRecordingIOS: true, playsInSilentModeIOS: true });
    const rec = new Audio.Recording();
    await rec.prepareToRecordAsync(Audio.RecordingOptionsPresets.HIGH_QUALITY);
    await rec.startAsync();
    setRecording(rec);
  };

  const stopRecording = async () => {
    if (!recording) return;
    await recording.stopAndUnloadAsync();
    const uri = recording.getURI();
    setRecording(null);
    if (uri) {
      await saveMediaToSecureStore(uri, 'audio');
      Alert.alert('Gespeichert', 'Sprachmemo gesichert.');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Sprachmemo</Text>
      <TouchableOpacity style={[styles.button, { backgroundColor: recording ? '#EF4444' : '#1D4ED8' }]} onPress={recording ? stopRecording : startRecording}>
        <Text style={styles.buttonText}>{recording ? 'Stopp' : 'Aufnehmen'}</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', padding: 16 },
  title: { fontSize: 24, fontWeight: '700', marginVertical: 12 },
  button: { padding: 16, borderRadius: 14, alignItems: 'center' },
  buttonText: { color: '#fff', fontWeight: '700' }
});