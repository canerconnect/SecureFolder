const crypto = require('crypto');

class Encryption {
  constructor() {
    this.algorithm = 'aes-256-gcm';
    this.keyLength = 32; // 256 bits
    this.ivLength = 16; // 128 bits
    this.tagLength = 16; // 128 bits
    this.saltLength = 64; // 512 bits
    
    // Encryption key aus Umgebungsvariablen
    this.masterKey = Buffer.from(process.env.ENCRYPTION_KEY || 'default-key-32-chars-long-here', 'utf8');
  }

  // Generiert einen sicheren Salt
  generateSalt() {
    return crypto.randomBytes(this.saltLength);
  }

  // Generiert einen sicheren IV
  generateIV() {
    return crypto.randomBytes(this.ivLength);
  }

  // Verschlüsselt Daten
  encrypt(data) {
    try {
      const iv = this.generateIV();
      const salt = this.generateSalt();
      
      // Key Derivation mit PBKDF2
      const key = crypto.pbkdf2Sync(this.masterKey, salt, 100000, this.keyLength, 'sha512');
      
      // Verschlüsselung
      const cipher = crypto.createCipher(this.algorithm, key);
      let encrypted = cipher.update(data, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // Auth Tag für GCM
      const tag = cipher.getAuthTag();
      
      return {
        encrypted: encrypted,
        iv: iv.toString('hex'),
        salt: salt.toString('hex'),
        tag: tag.toString('hex')
      };
    } catch (error) {
      throw new Error(`Verschlüsselung fehlgeschlagen: ${error.message}`);
    }
  }

  // Entschlüsselt Daten
  decrypt(encryptedData) {
    try {
      const { encrypted, iv, salt, tag } = encryptedData;
      
      // Key Derivation
      const key = crypto.pbkdf2Sync(
        this.masterKey, 
        Buffer.from(salt, 'hex'), 
        100000, 
        this.keyLength, 
        'sha512'
      );
      
      // Entschlüsselung
      const decipher = crypto.createDecipher(this.algorithm, key);
      decipher.setAuthTag(Buffer.from(tag, 'hex'));
      
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      throw new Error(`Entschlüsselung fehlgeschlagen: ${error.message}`);
    }
  }

  // Verschlüsselt einen Dateinamen
  encryptFileName(fileName) {
    const encrypted = this.encrypt(fileName);
    return {
      encryptedName: encrypted.encrypted,
      metadata: {
        iv: encrypted.iv,
        salt: encrypted.salt,
        tag: encrypted.tag
      }
    };
  }

  // Entschlüsselt einen Dateinamen
  decryptFileName(encryptedFileName, metadata) {
    return this.decrypt({
      encrypted: encryptedFileName,
      iv: metadata.iv,
      salt: metadata.salt,
      tag: metadata.tag
    });
  }

  // Generiert einen sicheren Hash für Datei-Integrität
  generateFileHash(data) {
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  // Generiert einen sicheren Token
  generateSecureToken() {
    return crypto.randomBytes(32).toString('hex');
  }
}

module.exports = new Encryption();