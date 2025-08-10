import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { signInWithEmail } from '@/services/auth';

export default function LoginScreen({ navigation }: any) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const onLogin = async () => {
    try {
      await signInWithEmail(email.trim(), password);
    } catch (e: any) {
      Alert.alert('Login fehlgeschlagen', e.message);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>SecureFolder</Text>
      <Text style={styles.subtitle}>Anmelden</Text>

      <TextInput style={styles.input} placeholder="E-Mail" autoCapitalize="none" value={email} onChangeText={setEmail} />
      <TextInput style={styles.input} placeholder="Passwort" secureTextEntry value={password} onChangeText={setPassword} />

      <TouchableOpacity style={styles.primaryButton} onPress={onLogin}>
        <Text style={styles.primaryButtonText}>Login</Text>
      </TouchableOpacity>

      <TouchableOpacity onPress={() => navigation.navigate('Register')}>
        <Text style={styles.link}>Noch kein Konto? Registrieren</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: '#fff' },
  title: { fontSize: 32, fontWeight: '700', marginTop: 48 },
  subtitle: { fontSize: 18, color: '#666', marginTop: 8, marginBottom: 24 },
  input: { backgroundColor: '#f3f4f6', padding: 14, borderRadius: 12, marginBottom: 12 },
  primaryButton: { backgroundColor: '#1D4ED8', padding: 16, borderRadius: 16, alignItems: 'center', marginTop: 8 },
  primaryButtonText: { color: 'white', fontWeight: '600' },
  link: { textAlign: 'center', color: '#1D4ED8', marginTop: 16 }
});