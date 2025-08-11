import { Sequelize } from 'sequelize';

const {
  DB_HOST = 'localhost',
  DB_PORT = '5432',
  DB_USER = 'postgres',
  DB_PASSWORD = 'postgres',
  DB_NAME = 'termine',
  DATABASE_URL,
  NODE_ENV,
  SQLITE_FILE,
} = process.env;

let sequelizeInstance;

if (SQLITE_FILE) {
  sequelizeInstance = new Sequelize({
    dialect: 'sqlite',
    storage: SQLITE_FILE,
    logging: NODE_ENV === 'development' ? console.log : false,
  });
} else if (DATABASE_URL) {
  sequelizeInstance = new Sequelize(DATABASE_URL, {
    dialect: 'postgres',
    logging: NODE_ENV === 'development' ? console.log : false,
  });
} else {
  sequelizeInstance = new Sequelize(DB_NAME, DB_USER, DB_PASSWORD, {
    host: DB_HOST,
    port: Number(DB_PORT),
    dialect: 'postgres',
    logging: NODE_ENV === 'development' ? console.log : false,
  });
}

export const sequelize = sequelizeInstance;