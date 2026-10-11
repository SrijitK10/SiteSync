import { Client } from 'pg';
import { MongoClient } from 'mongodb';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(__dirname, '../.env') });

interface MigrationResult {
  table: string;
  pgCount: number;
  mongoCounts: Record<string, number>;
}

async function createIndexes(db: any) {
  const indexSpecs: Array<{ collection: string; spec: any; options?: any }> = [
    // users
    { collection: 'users', spec: { id: 1 }, options: { unique: true } },
    { collection: 'users', spec: { phone: 1 }, options: { unique: true, sparse: true } },
    { collection: 'users', spec: { email: 1 }, options: { unique: true, sparse: true } },
    { collection: 'users', spec: { firebase_uid: 1 }, options: { unique: true, sparse: true } },

    // projects
    { collection: 'projects', spec: { id: 1 }, options: { unique: true } },
    { collection: 'projects', spec: { created_by: 1 } },

    // project_members
    { collection: 'project_members', spec: { id: 1 }, options: { unique: true } },
    { collection: 'project_members', spec: { project_id: 1, user_id: 1 }, options: { unique: true } },
    { collection: 'project_members', spec: { project_id: 1 } },
    { collection: 'project_members', spec: { user_id: 1 } },

    // flats
    { collection: 'flats', spec: { id: 1 }, options: { unique: true } },
    { collection: 'flats', spec: { project_id: 1, flat_number: 1 }, options: { unique: true } },
    { collection: 'flats', spec: { project_id: 1 } },

    // tasks
    { collection: 'tasks', spec: { id: 1 }, options: { unique: true } },
    { collection: 'tasks', spec: { project_id: 1, created_at: -1 } },
    { collection: 'tasks', spec: { project_id: 1, flat_id: 1 } },
    { collection: 'tasks', spec: { assigned_to: 1 } },
    { collection: 'tasks', spec: { created_by: 1 } },
    { collection: 'tasks', spec: { completed_by: 1 } },

    // contractors
    { collection: 'contractors', spec: { id: 1 }, options: { unique: true } },
    { collection: 'contractors', spec: { name: 1 }, options: { unique: true } },

    // attendance
    { collection: 'attendance', spec: { id: 1 }, options: { unique: true } },
    { collection: 'attendance', spec: { project_id: 1 } },
    { collection: 'attendance', spec: { recorded_by: 1 } },

    // project_images
    { collection: 'project_images', spec: { id: 1 }, options: { unique: true } },
    { collection: 'project_images', spec: { project_id: 1 } },
    { collection: 'project_images', spec: { uploaded_by: 1 } },

    // task_attachments
    { collection: 'task_attachments', spec: { id: 1 }, options: { unique: true } },
    { collection: 'task_attachments', spec: { task_id: 1 } },
    { collection: 'task_attachments', spec: { uploaded_by: 1 } },

    // shifts
    { collection: 'shifts', spec: { id: 1 }, options: { unique: true } },
    { collection: 'shifts', spec: { user_id: 1, start_time: -1 } },
    { collection: 'shifts', spec: { project_id: 1, start_time: -1 } },
  ];

  for (const idx of indexSpecs) {
    try {
      await db.collection(idx.collection).createIndex(idx.spec, idx.options || {});
    } catch (err: any) {
      console.warn(`Warning creating index on ${idx.collection} (${JSON.stringify(idx.spec)}): ${err.message}`);
    }
  }
}

async function migrate() {
  const pgUrl = process.env.DATABASE_URL;
  const mongoUrl = process.env.MONGO_URI;

  if (!pgUrl) {
    console.error('DATABASE_URL is missing in .env');
    process.exit(1);
  }

  if (!mongoUrl) {
    console.error('MONGO_URI is missing in .env');
    process.exit(1);
  }

  console.log('Connecting to PostgreSQL (Supabase)...');
  const pgClient = new Client({
    connectionString: pgUrl,
    ssl: { rejectUnauthorized: false },
  });

  await pgClient.connect();
  console.log('Connected to PostgreSQL successfully.');

  console.log('Connecting to MongoDB...');
  const mongoClient = new MongoClient(mongoUrl, {
    tls: true,
    tlsAllowInvalidCertificates: false,
    minPoolSize: 5,
  });

  await mongoClient.connect();
  console.log('Connected to MongoDB successfully.');

  // Target databases: include both 'test' (default fallback in app.module.ts)
  // and 'sitesync', plus MONGO_DB_NAME if explicitly specified.
  const targetDbNames = new Set<string>();
  targetDbNames.add('test');
  targetDbNames.add('sitesync');
  if (process.env.MONGO_DB_NAME) {
    targetDbNames.add(process.env.MONGO_DB_NAME);
  }

  const dbs = Array.from(targetDbNames).map(dbName => ({
    name: dbName,
    db: mongoClient.db(dbName),
  }));

  console.log(`Target MongoDB databases: ${Array.from(targetDbNames).join(', ')}`);

  console.log('Fetching table list from PostgreSQL...');
  const tableResult = await pgClient.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema='public' AND table_type='BASE TABLE'
    ORDER BY table_name;
  `);

  const tables: string[] = tableResult.rows.map((row: any) => row.table_name);
  console.log(`Found ${tables.length} tables to migrate: ${tables.join(', ')}\n`);

  const results: MigrationResult[] = [];

  for (const table of tables) {
    console.log(`--- Migrating table: "${table}" ---`);
    const recordsRes = await pgClient.query(`SELECT * FROM "${table}"`);
    const records = recordsRes.rows;
    console.log(`Found ${records.length} records in PostgreSQL table "${table}".`);

    const mongoCounts: Record<string, number> = {};

    for (const { name: dbName, db } of dbs) {
      const collection = db.collection(table);
      await collection.deleteMany({});

      if (records.length > 0) {
        // Deep copy records to avoid mutation of _id between different database insertions
        const docs = records.map(r => {
          const doc = { ...r };
          // For unique sparse fields, omit key if value is null to avoid MongoDB E11000 null duplicate errors
          if (table === 'users') {
            if (doc.phone === null) delete doc.phone;
            if (doc.email === null) delete doc.email;
            if (doc.firebase_uid === null) delete doc.firebase_uid;
            if (doc.password_hash === null) delete doc.password_hash;
          }
          return doc;
        });

        await collection.insertMany(docs);
        const count = await collection.countDocuments();
        mongoCounts[dbName] = count;
        console.log(`  -> Database "${dbName}": inserted and verified ${count} documents.`);
      } else {
        mongoCounts[dbName] = 0;
        console.log(`  -> Database "${dbName}": table was empty, collection cleared.`);
      }
    }

    results.push({
      table,
      pgCount: records.length,
      mongoCounts,
    });
  }

  console.log('\nCreating schema indexes on MongoDB collections...');
  for (const { name: dbName, db } of dbs) {
    console.log(`Creating indexes on database "${dbName}"...`);
    await createIndexes(db);
  }
  console.log('Indexes created successfully.');

  console.log('\n==========================================');
  console.log('         MIGRATION SUMMARY');
  console.log('==========================================');
  console.table(
    results.map(r => ({
      Table: r.table,
      'PostgreSQL Rows': r.pgCount,
      ...Object.fromEntries(
        Object.entries(r.mongoCounts).map(([db, count]) => [`Mongo [${db}]`, count])
      ),
      Status: Object.values(r.mongoCounts).every(c => c === r.pgCount) ? 'MATCH' : 'MISMATCH',
    }))
  );

  await pgClient.end();
  await mongoClient.close();
  console.log('Migration completed successfully!');
}

migrate().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
