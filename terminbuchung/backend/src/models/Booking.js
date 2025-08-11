import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../lib/db.js';
import { Provider } from './Provider.js';

export class Booking extends Model {}

Booking.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, allowNull: false },
    phone: { type: DataTypes.STRING, allowNull: true },
    startTime: { type: DataTypes.DATE, allowNull: false },
    endTime: { type: DataTypes.DATE, allowNull: false },
    comment: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.ENUM('pending', 'confirmed', 'canceled'), allowNull: false, defaultValue: 'pending' },
    cancellationToken: { type: DataTypes.UUID, allowNull: false, defaultValue: DataTypes.UUIDV4 },
    confirmationToken: { type: DataTypes.UUID, allowNull: false, defaultValue: DataTypes.UUIDV4 },
    confirmedAt: { type: DataTypes.DATE, allowNull: true },
    canceledAt: { type: DataTypes.DATE, allowNull: true },
    reminderSentAt: { type: DataTypes.DATE, allowNull: true },
  },
  {
    sequelize,
    modelName: 'Booking',
    tableName: 'bookings',
    indexes: [
      { unique: true, fields: ['providerId', 'startTime'] },
      { fields: ['email'] },
      { fields: ['status'] },
    ],
  }
);

Booking.belongsTo(Provider, { foreignKey: { name: 'providerId', allowNull: false }, onDelete: 'CASCADE' });
Provider.hasMany(Booking, { foreignKey: { name: 'providerId', allowNull: false } });