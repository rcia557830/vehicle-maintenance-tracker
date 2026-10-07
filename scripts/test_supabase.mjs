// npm.cmd install --prefix build/sql-validation @electric-sql/pglite
// node scripts/test_supabase.mjs
// Run the real migration in embedded PostgreSQL with Supabase Auth stubs.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { PGlite } from '../build/sql-validation/node_modules/@electric-sql/pglite/dist/index.js';

const db = new PGlite();
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
let checks = 0;
async function check(name, run) {
  await run();
  checks++;
  console.log(`PASS ${name}`);
}
async function asUser(id) {
  await db.exec('reset role; set role authenticated;');
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [id]);
}
async function rows(table) { return (await db.query(`select * from public.${table}`)).rows; }
async function denied(sql, params = []) { await assert.rejects(() => db.query(sql, params)); }
try {
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema public, auth to authenticated, anon;
    grant execute on function auth.uid() to authenticated, anon;
    insert into auth.users values ('${a}'), ('${b}');
  `);
  await check('migration executes in PostgreSQL', async () => {
    await db.exec(await readFile(new URL('../supabase/migrations/202609300001_motorcare.sql', import.meta.url), 'utf8'));
  });
  await asUser(a);
  const payload = {
    vehicles: [{ id: 42, nickname: 'Local car', make: 'Toyota', model: 'Vios', year: 2022, plate_number: 'ABC 123', current_odometer: 16093.44, odometer_unit: 'km', notes: '' }],
    records: [{ vehicle_id: 42, maintenance_type: 'PMS', service_date: '2026-01-01', odometer: 8046.72, cost: 3500, service_provider: '', notes: '' }],
    schedules: [{ vehicle_id: 42, maintenance_type: 'Oil Change', due_date: '2027-01-01', due_odometer: 32186.88, notes: '', reminder_enabled: 1, status: 'upcoming' }],
    tires: [{ vehicle_id: 42, position: 'Front left', brand: 'Test tire', manufactured_on: '2022-01-01', replacement_years: 6, notes: '' }],
    settings: { selected_vehicle: '42', interval_42: '8000', unit: 'km' },
  };
  let vehicle, schedule;
  await check('local import remaps all IDs and preserves settings', async () => {
    const result = await db.query('select public.import_local_garage($1::jsonb, $2) as count', [JSON.stringify(payload), 'test-import']);
    assert.equal(result.rows[0].count, 1);
    vehicle = (await rows('vehicles'))[0];
    assert.notEqual(Number(vehicle.id), 42);
    for (const table of ['maintenance_records', 'maintenance_schedules', 'tires']) {
      const record = (await rows(table))[0];
      assert.equal(record.vehicle_id, vehicle.id);
      assert.equal(record.user_id, a);
    }
    schedule = (await rows('maintenance_schedules'))[0];
    const settings = Object.fromEntries((await rows('settings')).map(r => [r.key, r.value]));
    assert.equal(settings[`interval_${vehicle.id}`], '8000');
    assert.equal(settings.selected_vehicle, String(vehicle.id));
    assert.equal(settings.notifications, 'false');
  });
  await check('import retry does not duplicate records', async () => {
    const result = await db.query('select public.import_local_garage($1::jsonb, $2) as count', [JSON.stringify(payload), 'test-import']);
    assert.equal(result.rows[0].count, 0);
    assert.equal((await rows('maintenance_records')).length, 1);
    await denied('select public.import_local_garage($1::jsonb, $2)', [JSON.stringify(payload), 'different-import']);
  });
  await check('duplicate plate and tire position rejected', async () => {
    await denied("insert into public.vehicles(nickname,make,model,year,plate_number,current_odometer) values ('Duplicate','T','V',2022,'abc-123',0)");
    await denied("insert into public.tires(vehicle_id, position, manufactured_on) values ($1, 'Front left', '2022-01-01')", [vehicle.id]);
    await denied("insert into public.tires(vehicle_id, position, manufactured_on) values ($1, 'Spare', '2099-01-01')", [vehicle.id]);
  });
  await check('unit conversion is atomic and retry safe', async () => {
    await db.query("select public.change_distance_unit('mi')");
    await db.query("select public.change_distance_unit('mi')");
    assert.ok(Math.abs((await rows('vehicles'))[0].current_odometer - 10000) < 0.001);
    assert.ok(Math.abs((await rows('maintenance_records'))[0].odometer - 5000) < 0.001);
    assert.ok(Math.abs((await rows('maintenance_schedules'))[0].due_odometer - 20000) < 0.001);
    await denied("select public.change_distance_unit('invalid')");
  });
  await check('failed completion rolls back schedule and record', async () => {
    const invalid = { ...payload.records[0], vehicle_id: Number(vehicle.id), cost: -1 };
    await denied('select public.complete_maintenance($1, $2::jsonb)', [schedule.id, JSON.stringify(invalid)]);
    assert.equal((await rows('maintenance_schedules'))[0].status, 'upcoming');
    assert.equal((await rows('maintenance_records')).length, 1);
  });
  await check('completion retries create one expense', async () => {
    const record = { ...payload.records[0], vehicle_id: Number(vehicle.id) };
    await db.query('select public.complete_maintenance($1, $2::jsonb)', [schedule.id, JSON.stringify(record)]);
    await db.query('select public.complete_maintenance($1, $2::jsonb)', [schedule.id, JSON.stringify(record)]);
    assert.equal((await rows('maintenance_schedules'))[0].status, 'completed');
    assert.equal((await rows('maintenance_records')).length, 2);
  });
  await asUser(b);
  await check('second account cannot read, update or delete first account rows', async () => {
    for (const table of ['vehicles', 'maintenance_records', 'maintenance_schedules', 'tires', 'settings']) {
      assert.equal((await rows(table)).length, 0);
      assert.equal((await db.query(`delete from public.${table} returning *`)).rows.length, 0);
    }
    assert.equal((await db.query("update public.vehicles set nickname='Stolen' where id=$1 returning *", [vehicle.id])).rows.length, 0);
    await denied('select public.complete_maintenance($1, null)', [schedule.id]);
    await db.query("select public.change_distance_unit('km')");
  });
  await check('RLS and composite foreign keys reject cross-account writes', async () => {
    await denied("insert into public.tires(user_id, vehicle_id, position, manufactured_on) values ($1, $2, 'Spare', '2022-01-01')", [a, vehicle.id]);
    await denied("insert into public.tires(vehicle_id, position, manufactured_on) values ($1, 'Spare', '2022-01-01')", [vehicle.id]);
    await denied("insert into public.settings(user_id,key,value) values ($1,'attack','x')", [a]);
  });
  await check('invalid imported child rolls back the entire garage', async () => {
    const broken = structuredClone(payload);
    broken.tires[0].vehicle_id = 999;
    await denied('select public.import_local_garage($1::jsonb, $2)', [JSON.stringify(broken), 'broken']);
    assert.equal((await rows('vehicles')).length, 0);
    assert.equal((await rows('maintenance_records')).length, 0);
    await db.query('select public.import_local_garage($1::jsonb, $2)', [JSON.stringify(payload), 'test-import']);
    assert.equal((await rows('vehicles')).length, 1);
  });
  await asUser(a);
  await check('other account unit conversion did not affect the first account', async () => {
    assert.equal((await rows('vehicles'))[0].odometer_unit, 'mi');
  });
  await check('deleting a vehicle cascades only its children', async () => {
    await db.query('delete from public.vehicles where id=$1', [vehicle.id]);
    for (const table of ['maintenance_records', 'maintenance_schedules', 'tires']) {
      assert.equal((await rows(table)).length, 0);
    }
    await asUser(b);
    assert.equal((await rows('tires')).length, 1);
  });
  await check('anonymous access is denied for tables and RPCs', async () => {
    await db.exec('reset role; set role anon;');
    await denied('select * from public.vehicles');
    await denied("select public.change_distance_unit('km')");
    await denied('select public.complete_maintenance(1, null)');
  });
  console.log(`All ${checks} Supabase SQL checks passed.`);
} finally {
  await db.close();
}
