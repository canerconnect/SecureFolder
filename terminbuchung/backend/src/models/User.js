import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../lib/db.js';
import { Provider } from './Provider.js';

export class User extends Model {}

User.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    username: { type: DataTypes.STRING, allowNull: false, unique: true },
    passwordHash: { type: DataTypes.STRING, allowNull: false },
  },
  { sequelize, modelName: 'User', tableName: 'users' }
);

User.belongsTo(Provider, { foreignKey: { name: 'providerId', allowNull: false }, onDelete: 'CASCADE' });
Provider.hasMany(User, { foreignKey: { name: 'providerId', allowNull: false } });