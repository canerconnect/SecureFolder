import * as SecureStore from 'expo-secure-store';
import CryptoJS from 'crypto-js';

const KEY_ALIAS = 'securefolder_master_key_v1';

const generateRandomKey = () => {
  const array = new Uint8Array(32);
  for (let i = 0; i < array.length; i++) array[i] = Math.floor(Math.random() * 256);
  return Array.from(array).map((b) => ('0' + b.toString(16)).slice(-2)).join('');
};

export const ensureEncryptionKey = async () => {
  let key = await SecureStore.getItemAsync(KEY_ALIAS, { requireAuthentication: true });
  if (!key) {
    key = generateRandomKey();
    await SecureStore.setItemAsync(KEY_ALIAS, key, { requireAuthentication: true });
  }
  return key;
};

const getKey = async (): Promise<string> => {
  const k = await SecureStore.getItemAsync(KEY_ALIAS, { requireAuthentication: true });
  if (!k) throw new Error('Encryption key not found');
  return k;
};

export const encryptString = async (plain: string): Promise<string> => {
  const key = await getKey();
  return CryptoJS.AES.encrypt(plain, key).toString();
};

export const decryptString = async (cipher: string): Promise<string> => {
  const key = await getKey();
  const bytes = CryptoJS.AES.decrypt(cipher, key);
  return bytes.toString(CryptoJS.enc.Utf8);
};