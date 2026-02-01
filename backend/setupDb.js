const { Client } = require('pg');

const connectionString = 'postgres://postgres:Vv098%40vikash@localhost:5432/postgres';

const client = new Client({
    connectionString,
});

async function setup() {
    try {
        await client.connect();

        // Check if database 'calico' exists
        const res = await client.query("SELECT 1 FROM pg_database WHERE datname='calico'");
        if (res.rowCount === 0) {
            console.log("Creating database 'calico'...");
            await client.query('CREATE DATABASE calico');
        } else {
            console.log("Database 'calico' already exists.");
        }

        await client.end();

        // Now connect to 'calico' db to create tables
        const { Pool } = require('pg');
        const calicoPool = new Pool({
            connectionString: 'postgres://postgres:Vv098%40vikash@localhost:5432/calico'
        });

        console.log("Creating tables...");
        await calicoPool.query(`
            CREATE TABLE IF NOT EXISTS pets (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                breed VARCHAR(100),
                age INTEGER
            );
        `);

        // Seed pets if empty
        const petCount = await calicoPool.query('SELECT COUNT(*) FROM pets');
        if (parseInt(petCount.rows[0].count) <= 5) { // Check if we need to add Tyson or init
            // Simple logic: insert ignore or just insert if empty. Let's do Insert if empty for now to be safe against dupes in simple setup
            if (parseInt(petCount.rows[0].count) === 0) {
                console.log("Seeding pets...");
                await calicoPool.query(`
                    INSERT INTO pets (name, breed, age) VALUES 
                    ('Max', 'Golden Retriever', 3),
                    ('Bella', 'Labrador', 2),
                    ('Sneezy', 'Cat', 5),
                    ('Charlie', 'Beagle', 4),
                    ('Luna', 'Pug', 1),
                    ('Tyson', 'Boxer', 3),
                    ('Shasha', 'Dog', 2);
                `);
            } else {
                // If pets exist but Tyson might be missing, try adding him? 
                // User wants Tyson NOW. The run_command earlier failed because of 'list.ng' error (powershell escaping issue?).
                // I will try to run a safe insert command separately.
                console.log("Pets table already exists.");
            }
        }

        await calicoPool.query(`
      CREATE TABLE IF NOT EXISTS vaccines (
        id SERIAL PRIMARY KEY,
        pet_id INTEGER NOT NULL,
        vaccine_name VARCHAR(255) NOT NULL,
        date_issued DATE,
        next_due_date DATE,
        type VARCHAR(50) DEFAULT 'Vaccination',
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_pet
          FOREIGN KEY(pet_id) 
          REFERENCES pets(id)
      );
    `);

        console.log("Tables created successfully.");
        await calicoPool.end();

    } catch (err) {
        console.error("Error setting up database:", err);
        process.exit(1);
    }
}

setup();
