export type SecureItemType = 'image' | 'video' | 'audio' | 'note';

export interface SecureItemMeta {
  id: string;
  type: SecureItemType;
  createdAt: number;
  sizeBytes: number;
  fileNameCipher: string; // encrypted filename
  storageUri: string; // local file path
  thumbnailUri?: string;
  noteTextCipher?: string;
  cloud?: {
    uploaded: boolean;
    storagePath?: string;
    firestoreId?: string;
  };
}

export interface LocalIndex {
  items: SecureItemMeta[];
  version: number;
}