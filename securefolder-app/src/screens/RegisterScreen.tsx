import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { registerWithEmail } from '@/services/auth';

export default function RegisterScreen({ navigation }: any) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const onRegister = async () => {
    try {
      await registerWithEmail(email.trim(), password);
      navigation.replace('Login');
    } catch (e: any) {
      Alert.alert('Registrierung fehlgeschlagen', e.message);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Konto erstellen</Text>
      <TextInput style={styles.input} placeholder="E-Mail" autoCapitalize="none" value={email} onChangeText={setEmail} />
      <TextInput style={styles.input} placeholder="Passwort" secureTextEntry value={password} onChangeText={setPassword} />

      <TouchableOpacity style={styles.primaryButton} onPress={onRegister}>
        <Text style={styles.primaryButtonText}>Registrieren</Text>
      </TouchableOpacity>

      <TouchableOpacity onPress={() => navigation.goBack()}>
        <Text style={styles.link}>Zurück zum Login</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: '#fff' },
  title: { fontSize: 28, fontWeight: '700', marginTop: 48, marginBottom: 24 },
  input: { backgroundColor: '#f3f4f6', padding: 14, borderRadius: 12, marginBottom: 12 },
  primaryButton: { backgroundColor: '#1D4ED8', padding: 16, borderRadius: 16, alignItems: 'center', marginTop: 8 },
  primaryButtonText: { color: 'white', fontWeight: '600' },
  link: { textAlign: 'center', color: '#1D4ED8', marginTop: 16 }
});