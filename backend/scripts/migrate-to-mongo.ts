import { DataSource } from 'typeorm';
import { MongoClient } from 'mongodb';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(__dirname, '../.env') });

async function migrate() {
  const pgUrl = process.env.DATABASE_URL;
  // Make sure the MongoDB cluster is provisioned in the Mumbai region (ap-south-1)
  const mongoUrl = process.env.MONGO_URI || 'mongodb://localhost:27017/sitesync';

  if (!pgUrl) {
    console.error('DATABASE_URL is missing in .env');
    process.exit(1);
  }

  console.log('Connecting to PostgreSQL...');
  const pgDataSource = new DataSource({
    type: 'postgres',
    url: pgUrl,
    ssl: { rejectUnauthorized: false },
  });

  await pgDataSource.initialize();
  console.log('Connected to PostgreSQL.');

  console.log(`Connecting to MongoDB... (Ensure your Atlas cluster is in the Mumbai region for data compliance)`);
  const mongoClient = new MongoClient(mongoUrl, {
    tls: true,
    // Enable security features properly to prevent data leakage
    tlsAllowInvalidCertificates: false,
    minPoolSize: 5,
  });

  await mongoClient.connect();
  const db = mongoClient.db();
  console.log('Connected to MongoDB.');

  console.log('Fetching table names from PostgreSQL...');
  const tableResult = await pgDataSource.query(
    `SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'`
  );
  
  const tables = tableResult.map((row: any) => row.table_name);
  console.log(`Found ${tables.length} tables to migrate:`, tables.join(', '));

  for (const table of tables) {
    console.log(`Migrating table: ${table}...`);
    try {
      const records = await pgDataSource.query(`SELECT * FROM "${table}"`);
      if (records.length > 0) {
        // We will store the data in MongoDB using the same table name
        const collection = db.collection(table);
        await collection.deleteMany({});
        await collection.insertMany(records);
        console.log(`Migrated ${records.length} records to collection ${table}.`);
      } else {
        console.log(`Table ${table} is empty, skipping.`);
      }
    } catch (e: any) {
      console.error(`Error migrating table ${table}:`, e.message);
    }
  }

  console.log('Migration complete. You can now switch the backend codebase to Mongoose.');
  await pgDataSource.destroy();
  await mongoClient.close();
}

migrate().catch(console.error);
