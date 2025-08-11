import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../lib/db.js';

export class Provider extends Model {}

Provider.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    name: { type: DataTypes.STRING, allowNull: false },
    subdomain: { type: DataTypes.STRING, allowNull: true, unique: true },
    color_primary: { type: DataTypes.STRING, allowNull: true },
    settings: {
      // JSON with workingHours, slotDurationMinutes, bufferMinutes, breaks, reminders
      type: DataTypes.JSONB,
      allowNull: false,
      defaultValue: {
        slotDurationMinutes: 30,
        bufferMinutes: 0,
        workingHours: {
          // 0=Sunday .. 6=Saturday; arrays of ranges [start,end] in HH:mm
          1: [["09:00", "12:00"], ["13:00", "17:00"]],
          2: [["09:00", "12:00"], ["13:00", "17:00"]],
          3: [["09:00", "12:00"], ["13:00", "17:00"]],
          4: [["09:00", "12:00"], ["13:00", "17:00"]],
          5: [["09:00", "12:00"]],
        },
        reminders: { enabled: true, hoursBefore: 24, via: ["email"] },
        cancellationDeadlineHours: 12,
      },
    },
  },
  { sequelize, modelName: 'Provider', tableName: 'providers' }
);