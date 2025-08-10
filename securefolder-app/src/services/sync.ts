import * as FileSystem from 'expo-file-system';
import * as SecureStore from 'expo-secure-store';
import { getLocalIndex, decryptFileToTemp } from './localStore';
import { api } from './api';

const SYNC_KEY = 'securefolder_sync_enabled';

export const getSyncEnabled = async () => (await SecureStore.getItemAsync(SYNC_KEY)) === '1';
export const setSyncEnabled = async (v: boolean) => SecureStore.setItemAsync(SYNC_KEY, v ? '1' : '0');

export const syncNow = async () => {
  const enabled = await getSyncEnabled();
  if (!enabled) return;
  const idx = await getLocalIndex();
  for (const item of idx.items) {
    if (item.cloud?.uploaded) continue;

    const form = new FormData();
    form.append('type', item.type as any);
    if (item.type === 'note') {
      // For notes we already store ciphertext locally; send decrypted text
      const cipher = await FileSystem.readAsStringAsync(item.storageUri);
      // Don't send plaintext title or name; backend will encrypt
      form.append('text', cipher);
    } else {
      const tempPath = await decryptFileToTemp(item);
      const mime = item.type === 'image' ? 'image/jpeg' : item.type === 'video' ? 'video/mp4' : 'audio/m4a';
      form.append('file', {
        // @ts-ignore React Native file object
        uri: tempPath,
        name: `${item.id}`,
        type: mime
      });
    }

    await api.post('/upload', form, { headers: { 'Content-Type': 'multipart/form-data' } });
    item.cloud = { uploaded: true };
  }
};