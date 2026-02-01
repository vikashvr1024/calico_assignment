const { Pool } = require('pg');

// User provided password: Vv098@vikash (encoded as Vv098%40vikash)
const connectionString = 'postgres://postgres:Vv098%40vikash@localhost:5432/calico';

const pool = new Pool({
    connectionString,
});

module.exports = {
    query: (text, params) => pool.query(text, params),
};
