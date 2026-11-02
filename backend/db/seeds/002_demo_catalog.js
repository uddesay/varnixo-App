const argon2 = require('argon2');
const { v4: uuid } = require('uuid');
const { assertDemoDatabase, demoPassword, photo } = require('../demo');

/**
 * Development demo catalog: an approved vendor, warehouse, brands,
 * subcategories and a set of active products with variants + stock.
 * Idempotent: skips if the demo vendor exists.
 */
exports.seed = async function seed(knex) {
  assertDemoDatabase(knex);
  if (await knex('vendors').where({ store_slug: 'varnixo-official-store' }).first()) return;

  const rootCats = await knex('categories').whereNull('parent_id');
  const catBySlug = Object.fromEntries(rootCats.map((c) => [c.slug, c.id]));
  const vendorRole = await knex('roles').where({ name: 'vendor' }).first();
  const customerRole = await knex('roles').where({ name: 'customer' }).first();
  const admin = await knex('users').where({ email: process.env.DEMO_ADMIN_EMAIL || 'admin@demo.varnixo.com' }).first();

  await knex.transaction(async (trx) => {
    // vendor owner user
    const ownerId = uuid();
    await trx('users').insert({
      id: ownerId,
      email: process.env.DEMO_SELLER_EMAIL || 'seller@demo.varnixo.com',
      password_hash: await argon2.hash(demoPassword('DEMO_SELLER_PASSWORD'), { type: argon2.argon2id }),
      full_name: 'Rohan Mehta',
      is_email_verified: true,
      referral_code: 'SELLER01',
    });
    await trx('user_roles').insert([
      { user_id: ownerId, role_id: vendorRole.id },
      { user_id: ownerId, role_id: customerRole.id },
    ]);
    await trx('wallets').insert({ id: uuid(), user_id: ownerId });

    // vendor + warehouse
    const vendorId = uuid();
    await trx('vendors').insert({
      id: vendorId,
      owner_user_id: ownerId,
      store_name: 'Varnixo Official Store',
      store_slug: 'varnixo-official-store',
      description: 'Farm-fresh vegetables, fruits and dry fruits, sorted and packed by Varnixo every morning.',
      status: 'approved',
      approved_at: trx.fn.now(),
      approved_by: admin?.id || null,
      gstin: '19ABCDE1234F1Z5',
      support_phone: process.env.DEMO_SUPPORT_PHONE || '+919339244573',
    });
    const warehouseId = uuid();
    await trx('warehouses').insert({
      id: warehouseId,
      vendor_id: vendorId,
      name: 'Varnixo Fresh Hub',
      line1: 'Plot 42, Wholesale Market Road',
      city: 'Kolkata',
      state: 'West Bengal',
      postal_code: '700001',
      contact_phone: process.env.DEMO_SUPPORT_PHONE || '+919339244573',
    });

    // subcategories
    const subcats = [
      ['Daily Vegetables', 'daily-vegetables', 'vegetables'],
      ['Leafy Greens', 'leafy-greens', 'vegetables'],
      ['Exotic Vegetables', 'exotic-vegetables', 'vegetables'],
      ['Seasonal Fruits', 'seasonal-fruits', 'fresh-fruits'],
      ['Exotic Fruits', 'exotic-fruits', 'fresh-fruits'],
      ['Nuts', 'nuts', 'dry-fruits'],
      ['Mixes & Gift Packs', 'dry-fruit-mixes', 'dry-fruits'],
    ];
    const subcatIds = {};
    for (const [name, slug, parentSlug] of subcats) {
      const id = uuid();
      subcatIds[slug] = id;
      await trx('categories').insert({
        id, parent_id: catBySlug[parentSlug], name, slug, commission_rate_bp: 1000,
      });
    }

    // brands
    const brandNames = ['Varnixo Fresh', 'Varnixo Select'];
    const brandIds = {};
    for (const name of brandNames) {
      const id = uuid();
      const slug = name.toLowerCase().replace(/\s+/g, '-');
      brandIds[name] = id;
      await trx('brands').insert({ id, name, slug });
    }

    // products. Fresh produce is GST-exempt; packaged dry fruits carry 5%.
    // Prices are in paise per pack; `grams` is the shipping weight.
    const products = [
      {
        title: 'Desi Tomatoes', cat: 'daily-vegetables', brand: 'Varnixo Fresh', tax: 0, img: 'photo-1546094096-0df4bcaaa337',
        description: 'Firm, juicy country tomatoes picked ripe for curries, chutneys and salads.',
        highlights: ['Hand-sorted every morning', 'Ripe & ready to cook', 'Sourced from local farms'],
        specs: [['Produce', 'Origin', 'West Bengal'], ['Storage', 'Shelf life', '3–4 days at room temperature']],
        variants: [
          { sku: 'VXTOM500', mrp: 3500, price: 2900, options: { Weight: '500 g' }, grams: 500, stock: 120 },
          { sku: 'VXTOM1KG', mrp: 6500, price: 5400, options: { Weight: '1 kg' }, grams: 1000, stock: 90 },
        ],
      },
      {
        title: 'Fresh Potatoes', cat: 'daily-vegetables', brand: 'Varnixo Fresh', tax: 0, img: 'photo-1518977676601-b53f82aba655',
        description: 'Everyday potatoes with a smooth skin, good for sabzi, fries and dum aloo.',
        highlights: ['Clean & dry', 'All-purpose variety', 'Stores well'],
        specs: [['Produce', 'Origin', 'Hooghly, West Bengal'], ['Storage', 'Shelf life', 'Up to 2 weeks in a cool, dark place']],
        variants: [
          { sku: 'VXPOT1KG', mrp: 4000, price: 3200, options: { Weight: '1 kg' }, grams: 1000, stock: 200 },
          { sku: 'VXPOT3KG', mrp: 11500, price: 8900, options: { Weight: '3 kg' }, grams: 3000, stock: 60 },
        ],
      },
      {
        title: 'Red Onions', cat: 'daily-vegetables', brand: 'Varnixo Fresh', tax: 0, img: 'photo-1508747703725-719777637510',
        description: 'Medium-sized red onions with a sharp, sweet bite — the base of every Indian kitchen.',
        highlights: ['Nashik variety', 'Dry outer skin', 'Long shelf life'],
        specs: [['Produce', 'Origin', 'Nashik, Maharashtra'], ['Storage', 'Shelf life', 'Up to 3 weeks in a dry place']],
        variants: [
          { sku: 'VXONI1KG', mrp: 5000, price: 3900, options: { Weight: '1 kg' }, grams: 1000, stock: 180 },
          { sku: 'VXONI2KG', mrp: 9800, price: 7500, options: { Weight: '2 kg' }, grams: 2000, stock: 70 },
        ],
      },
      {
        title: 'Robusta Bananas', cat: 'seasonal-fruits', brand: 'Varnixo Fresh', tax: 0, img: 'photo-1571771894821-ce9b6c11b08e',
        description: 'Naturally ripened Robusta bananas — sweet, filling and great for breakfast or shakes.',
        highlights: ['Naturally ripened', 'No carbide', 'Rich in potassium'],
        specs: [['Produce', 'Origin', 'Jalgaon, Maharashtra'], ['Storage', 'Shelf life', '2–3 days']],
        variants: [
          { sku: 'VXBAN6', mrp: 4500, price: 3600, options: { Pack: '6 pcs' }, grams: 900, stock: 100 },
          { sku: 'VXBAN12', mrp: 8500, price: 6900, options: { Pack: '12 pcs' }, grams: 1800, stock: 60 },
        ],
      },
      {
        title: 'Shimla Apples', cat: 'seasonal-fruits', brand: 'Varnixo Select', tax: 0, img: 'photo-1567306226416-28f0efdc88ce',
        description: 'Crisp, sweet Himachal apples with a deep red blush, fresh from this season’s harvest.',
        highlights: ['Himachal orchards', 'Crisp & juicy', 'Hand-graded'],
        specs: [['Produce', 'Origin', 'Shimla, Himachal Pradesh'], ['Storage', 'Shelf life', '1–2 weeks refrigerated']],
        variants: [
          { sku: 'VXAPL500', mrp: 11000, price: 8900, options: { Weight: '500 g' }, grams: 500, stock: 80 },
          { sku: 'VXAPL1KG', mrp: 21000, price: 16900, options: { Weight: '1 kg' }, grams: 1000, stock: 50 },
        ],
      },
      {
        title: 'California Almonds', cat: 'nuts', brand: 'Varnixo Select', tax: 500, img: 'photo-1508061253366-f7da158b6d46',
        description: 'Whole, crunchy California almonds — a handful a day for snacking, soaking or baking.',
        highlights: ['Premium whole kernels', 'Vacuum-packed', 'No added salt'],
        specs: [['General', 'Origin', 'California, USA'], ['Storage', 'Shelf life', '6 months in an airtight container']],
        variants: [
          { sku: 'VXALM250', mrp: 32000, price: 24900, options: { Weight: '250 g' }, grams: 250, stock: 150 },
          { sku: 'VXALM500', mrp: 62000, price: 46900, options: { Weight: '500 g' }, grams: 500, stock: 90 },
          { sku: 'VXALM1KG', mrp: 120000, price: 89900, options: { Weight: '1 kg' }, grams: 1000, stock: 40 },
        ],
      },
    ];

    for (const [pi, p] of products.entries()) {
      const productId = uuid();
      const slug = `${p.title.toLowerCase().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-')}-${pi}`;
      await trx('products').insert({
        id: productId,
        vendor_id: vendorId,
        category_id: subcatIds[p.cat],
        brand_id: brandIds[p.brand],
        title: p.title,
        slug,
        description: p.description,
        highlights: JSON.stringify(p.highlights),
        status: 'active',
        tax_rate_bp: p.tax,
        return_window_days: p.tax === 0 ? 1 : 7, // fresh produce: report within a day
        rating_avg: (3.8 + (pi % 3) * 0.4).toFixed(2),
        rating_count: 40 + pi * 17,
        review_count: 25 + pi * 9,
        sold_count: 100 + pi * 55,
        published_at: trx.fn.now(),
      });

      await trx('product_media').insert([0, 1, 2].map((mi) => ({
        id: uuid(),
        product_id: productId,
        url: photo(p.img, 900, ['entropy', 'faces', 'edges'][mi]),
        thumbnail_url: photo(p.img, 240),
        alt_text: p.title,
        sort_order: mi,
      })));

      await trx('product_specifications').insert(p.specs.map(([group, key, value], si) => ({
        id: uuid(), product_id: productId, group_name: group, spec_key: key, spec_value: value, sort_order: si,
      })));

      for (const [vi, v] of p.variants.entries()) {
        const variantId = uuid();
        await trx('product_variants').insert({
          id: variantId,
          product_id: productId,
          sku: v.sku,
          mrp_minor: v.mrp,
          sale_price_minor: v.price,
          is_default: vi === 0,
          weight_grams: v.grams,
        });
        await trx('variant_options').insert(Object.entries(v.options).map(([name, value]) => ({
          id: uuid(), variant_id: variantId, option_name: name, option_value: value,
        })));
        await trx('inventory_stocks').insert({
          variant_id: variantId, warehouse_id: warehouseId, quantity: v.stock,
        });
        await trx('inventory_movements').insert({
          id: uuid(),
          variant_id: variantId,
          warehouse_id: warehouseId,
          movement_type: 'purchase',
          quantity_delta: v.stock,
          reference_type: 'seed',
          actor_id: ownerId,
        });
      }
    }
  });
};
