import React, { useEffect, useState } from 'react';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { ActivityIndicator, View } from 'react-native';
import LoginScreen from '@/screens/LoginScreen';
import RegisterScreen from '@/screens/RegisterScreen';
import SecureFolderScreen from '@/screens/SecureFolderScreen';
import GalleryScreen from '@/screens/GalleryScreen';
import UploadScreen from '@/screens/UploadScreen';
import NotesScreen from '@/screens/NotesScreen';
import AudioScreen from '@/screens/AudioScreen';
import SettingsScreen from '@/screens/SettingsScreen';
import { onAuthStateChangedListener } from '@/services/auth';

const Stack = createNativeStackNavigator();
const Tabs = createBottomTabNavigator();

const AppTabs = () => (
  <Tabs.Navigator screenOptions={{ headerShown: false }}>
    <Tabs.Screen name="Home" component={SecureFolderScreen} />
    <Tabs.Screen name="Upload" component={UploadScreen} />
    <Tabs.Screen name="Notes" component={NotesScreen} />
    <Tabs.Screen name="Audio" component={AudioScreen} />
    <Tabs.Screen name="Settings" component={SettingsScreen} />
  </Tabs.Navigator>
);

export default function App() {
  const [initializing, setInitializing] = useState(true);
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    const unsub = onAuthStateChangedListener((u) => {
      setUser(u);
      if (initializing) setInitializing(false);
    });
    return unsub;
  }, []);

  if (initializing) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <NavigationContainer theme={{ ...DefaultTheme, colors: { ...DefaultTheme.colors, background: '#FFFFFF' } }}>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {user ? (
          <>
            <Stack.Screen name="AppTabs" component={AppTabs} />
            <Stack.Screen name="Gallery" component={GalleryScreen} />
          </>
        ) : (
          <>
            <Stack.Screen name="Login" component={LoginScreen} />
            <Stack.Screen name="Register" component={RegisterScreen} />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}