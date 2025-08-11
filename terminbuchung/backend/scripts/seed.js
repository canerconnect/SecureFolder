import 'dotenv/config';
import bcrypt from 'bcrypt';
import { sequelize } from '../src/lib/db.js';
import '../src/models/index.js';
import { Provider } from '../src/models/Provider.js';
import { User } from '../src/models/User.js';

async function run() {
  try {
    await sequelize.authenticate();
    await sequelize.sync();

    const provider = await Provider.create({
      name: 'Demo Praxis',
      subdomain: 'demo',
      color_primary: '#2563eb',
    });

    const passwordHash = await bcrypt.hash('admin123', 10);
    const user = await User.create({ username: 'admin', passwordHash, providerId: provider.id });

    console.log('Seed complete');
    console.log('Provider ID:', provider.id);
    console.log('Admin username:', user.username);
    console.log('Admin password:', 'admin123');
  } catch (err) {
    console.error(err);
  } finally {
    await sequelize.close();
  }
}

run();