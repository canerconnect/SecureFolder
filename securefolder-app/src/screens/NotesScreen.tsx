import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { saveNote } from '@/services/localStore';

export default function NotesScreen() {
  const [text, setText] = useState('');

  const onSave = async () => {
    await saveNote(text);
    setText('');
    Alert.alert('Gespeichert', 'Notiz wurde gesichert.');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Notiz</Text>
      <TextInput
        style={styles.area}
        multiline
        placeholder="Deine Notiz..."
        value={text}
        onChangeText={setText}
      />
      <TouchableOpacity style={styles.button} onPress={onSave}><Text style={styles.buttonText}>Speichern</Text></TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', padding: 16 },
  title: { fontSize: 24, fontWeight: '700', marginBottom: 12 },
  area: { backgroundColor: '#f3f4f6', minHeight: 160, padding: 12, borderRadius: 12, textAlignVertical: 'top' },
  button: { backgroundColor: '#10B981', padding: 14, borderRadius: 14, alignItems: 'center', marginTop: 12 },
  buttonText: { color: 'white', fontWeight: '600' }
});