const argon2 = require('argon2');
const { v4: uuid } = require('uuid');
const { assertDemoDatabase, demoPassword } = require('../demo');
const { ensurePlatformData } = require('../platform');

exports.seed = async function seed(knex) {
  assertDemoDatabase(knex);
  // Idempotent: skip if RBAC already seeded
  const existing = await knex('roles').where({ name: 'super_admin' }).first();
  if (existing) return;

  await knex.transaction(async (trx) => {
    const roleByName = await ensurePlatformData(trx);

    // super admin user (demo password generated into the ignored backend/.env)
    const adminId = uuid();
    await trx('users').insert({
      id: adminId,
      email: process.env.DEMO_ADMIN_EMAIL || 'admin@demo.varnixo.com',
      password_hash: await argon2.hash(demoPassword('DEMO_ADMIN_PASSWORD'), { type: argon2.argon2id }),
      full_name: 'Varnixo Admin',
      is_email_verified: true,
      status: 'active',
      referral_code: 'ADMIN001',
    });
    await trx('user_roles').insert({ user_id: adminId, role_id: roleByName.super_admin });
    await trx('wallets').insert({ id: uuid(), user_id: adminId });

    // root categories. Gaushala products launch later: the category exists but
    // stays hidden until an admin activates it under Catalog → Categories.
    const cats = [
      ['Vegetables', 'vegetables', true], ['Fresh Fruits', 'fresh-fruits', true],
      ['Dry Fruits', 'dry-fruits', true], ['Gaushala Products', 'gaushala-products', false],
    ];
    await trx('categories').insert(cats.map(([name, slug, isActive], i) => ({
      id: uuid(), name, slug, sort_order: i, commission_rate_bp: 1000, is_active: isActive,
      seo_title: `Buy ${name} Online | Varnixo`,
    })));
  });
};
