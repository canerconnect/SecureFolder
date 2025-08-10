import * as FileSystem from 'expo-file-system';
import { LocalIndex, SecureItemMeta, SecureItemType } from './types';
import { encryptString, decryptString, ensureEncryptionKey } from './encryption';
import { v4 as uuidv4 } from 'uuid';

const INDEX_FILE = FileSystem.documentDirectory + 'secure_index.json';
const DATA_DIR = FileSystem.documentDirectory + 'secure_data/';

const ensureDirs = async () => {
  const dirInfo = await FileSystem.getInfoAsync(DATA_DIR);
  if (!dirInfo.exists) {
    await FileSystem.makeDirectoryAsync(DATA_DIR, { intermediates: true });
  }
};

export const getLocalIndex = async (): Promise<LocalIndex> => {
  await ensureDirs();
  const exists = await FileSystem.getInfoAsync(INDEX_FILE);
  if (!exists.exists) {
    const empty: LocalIndex = { items: [], version: 1 };
    await FileSystem.writeAsStringAsync(INDEX_FILE, JSON.stringify(empty));
    return empty;
  }
  const content = await FileSystem.readAsStringAsync(INDEX_FILE);
  try {
    return JSON.parse(content) as LocalIndex;
  } catch {
    const reset: LocalIndex = { items: [], version: 1 };
    await FileSystem.writeAsStringAsync(INDEX_FILE, JSON.stringify(reset));
    return reset;
  }
};

const saveIndex = async (idx: LocalIndex) => {
  await FileSystem.writeAsStringAsync(INDEX_FILE, JSON.stringify(idx));
};

export const saveMediaToSecureStore = async (uri: string, type: SecureItemType) => {
  await ensureEncryptionKey();
  await ensureDirs();
  const id = uuidv4();
  const fileNamePlain = uri.split('/').pop() || id;
  const fileNameCipher = await encryptString(fileNamePlain);
  const dest = DATA_DIR + id + '.enc';

  // Read original file as base64 string, encrypt the base64 to ciphertext
  const base64 = await FileSystem.readAsStringAsync(uri, { encoding: FileSystem.EncodingType.Base64 });
  const cipher = await encryptString(base64);
  await FileSystem.writeAsStringAsync(dest, cipher);

  const idx = await getLocalIndex();
  const meta: SecureItemMeta = {
    id,
    type,
    createdAt: Date.now(),
    sizeBytes: cipher.length,
    fileNameCipher,
    storageUri: dest
  };
  idx.items.push(meta);
  await saveIndex(idx);
  return meta;
};

export const saveNote = async (text: string) => {
  await ensureEncryptionKey();
  const id = uuidv4();
  const cipher = await encryptString(text);
  const dest = DATA_DIR + id + '.note';
  await FileSystem.writeAsStringAsync(dest, cipher);
  const idx = await getLocalIndex();
  idx.items.push({ id, type: 'note', createdAt: Date.now(), sizeBytes: cipher.length, fileNameCipher: await encryptString('note.txt'), storageUri: dest, noteTextCipher: cipher });
  await saveIndex(idx);
};

export const decryptFileToTemp = async (meta: SecureItemMeta): Promise<string> => {
  // Decrypt ciphertext to a temp file for viewing/playback
  const cipher = await FileSystem.readAsStringAsync(meta.storageUri);
  const base64 = await decryptString(cipher);
  const tempPath = FileSystem.cacheDirectory + meta.id + '.tmp';
  await FileSystem.writeAsStringAsync(tempPath, base64, { encoding: FileSystem.EncodingType.Base64 });
  return tempPath;
};