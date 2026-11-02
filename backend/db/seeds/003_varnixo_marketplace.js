const argon2 = require('argon2');
const { v4: uuid } = require('uuid');
const { assertDemoDatabase, demoPassword, photo } = require('../demo');

/**
 * Varnixo client-demo marketplace: extra vendors with their own
 * catalogues and warehouses, pending applications, customers, orders across
 * every lifecycle state (spread over recent weeks for charts), reviews,
 * coupons, banners and help content.
 *
 * All records are clearly demo data (emails end in @demo.varnixo.com).
 * Idempotent: skips when the demo marketplace already exists.
 */

const DAY = 86400000;
const daysAgo = (d, hour = 11) => new Date(Date.now() - d * DAY + hour * 3600000 - 12 * 3600000);

// Product options are [name, value, stock, price?, mrp?, grams?]; price/mrp
// default to the product's, so single-price packs stay terse.
const VENDORS = [
  {
    store: 'Kisan Harvest Farms', slug: 'kisan-harvest-farms', owner: 'Subhash Mondal', email: 'kisan@demo.varnixo.com',
    city: 'Barasat', state: 'West Bengal', pin: '700124', gstin: '19AAKCK1234M1Z2', commission: null,
    description: 'A farmer collective delivering vegetables harvested the evening before.',
    products: [
      { title: 'Orange Carrots', cat: 'daily-vegetables', img: 'photo-1598170845058-32b9d6a5da37', mrp: 4000, price: 3200, tax: 0,
        options: [['Weight', '500 g', 140], ['Weight', '1 kg', 3, 5900, 7500, 1000]], rating: 4.5, sold: 412,
        description: 'Sweet, crunchy carrots for halwa, salads and stir-fries. Washed and trimmed.',
        highlights: ['Washed & trimmed', 'Sweet and crunchy', 'Harvested yesterday'] },
      { title: 'Fresh Spinach (Palak)', cat: 'leafy-greens', img: 'photo-1576045057995-568f588f82fb', mrp: 3000, price: 2500, tax: 0,
        options: [['Pack', '1 bunch (250 g)', 60], ['Pack', '2 bunches (500 g)', 25, 4500, 6000, 500]], rating: 4.3, sold: 286,
        description: 'Tender green spinach leaves for palak paneer, dal and smoothies.',
        highlights: ['Tender leaves', 'Pesticide-residue tested', 'Cleaned at the farm'] },
      { title: 'Green Cucumbers', cat: 'daily-vegetables', img: 'photo-1449300079323-02e209d9d3a6', mrp: 3500, price: 2800, tax: 0,
        options: [['Weight', '500 g', 90], ['Weight', '1 kg', 0, 5200, 6800, 1000]], rating: 4.2, sold: 198,
        description: 'Cool, crisp cucumbers for salads, raita and sandwiches.',
        highlights: ['Crisp & hydrating', 'Thin skin', 'Locally grown'] },
      { title: 'Green Cabbage', cat: 'daily-vegetables', img: 'photo-1594282486552-05b4d80fbb9f', mrp: 4000, price: 3000, tax: 0,
        options: [['Size', '1 pc (approx. 700 g)', 45]], rating: 4.1, sold: 133,
        description: 'Tightly packed cabbage heads for sabzi, coleslaw and momos.',
        highlights: ['Tight, fresh heads', 'Approx. 600–800 g each', 'Locally grown'] },
      { title: 'Bell Peppers Trio', cat: 'exotic-vegetables', img: 'photo-1563565375-f3fdfdbefa83', mrp: 12000, price: 8900, tax: 0,
        options: [['Pack', 'Red, yellow & green (3 pcs)', 30]], rating: 4.6, sold: 154,
        description: 'One red, one yellow and one green capsicum — glossy, thick-walled and sweet.',
        highlights: ['3 colours', 'Thick, sweet flesh', 'Polyhouse grown'] },
      { title: 'Iceberg Lettuce', cat: 'exotic-vegetables', img: 'photo-1622205313162-be1d5712a43f', mrp: 7000, price: 5500, tax: 0,
        options: [['Size', '1 pc (approx. 300 g)', 4]], rating: 4.0, sold: 77,
        description: 'Crunchy lettuce for burgers, wraps and salad bowls.',
        highlights: ['Crunchy leaves', 'Hydroponically grown', 'Rinse and serve'] },
    ],
  },
  {
    store: 'Orchard Basket', slug: 'orchard-basket', owner: 'Farida Khan', email: 'orchard@demo.varnixo.com',
    city: 'Kolkata', state: 'West Bengal', pin: '700019', gstin: '19AAFCO5678K1Z9', commission: 800,
    description: 'Seasonal and exotic fruit sourced directly from orchards across India.',
    products: [
      { title: 'Alphonso Mangoes', cat: 'seasonal-fruits', img: 'photo-1553279768-865429fa0078', mrp: 79900, price: 59900, tax: 0,
        options: [['Pack', '6 pcs', 20], ['Pack', '12 pcs', 2, 109900, 149900, 3000]], rating: 4.8, sold: 521,
        description: 'Naturally ripened Ratnagiri Alphonso — rich, fibre-free and fragrant.',
        highlights: ['Ratnagiri origin', 'Naturally ripened', 'Packed in hay'] },
      { title: 'Bhagwa Pomegranate', cat: 'seasonal-fruits', img: 'photo-1541344999736-83eca272f6fc', mrp: 22000, price: 16900, tax: 0,
        options: [['Weight', '500 g', 55], ['Weight', '1 kg', 30, 31900, 42000, 1000]], rating: 4.5, sold: 344,
        description: 'Deep red, sweet arils with soft seeds. Great for juice and fruit chaat.',
        highlights: ['Deep red arils', 'Soft seeds', 'Rich in antioxidants'] },
      { title: 'Nagpur Oranges', cat: 'seasonal-fruits', img: 'photo-1547514701-42782101795e', mrp: 12000, price: 9500, tax: 0,
        options: [['Weight', '1 kg', 70]], rating: 4.4, sold: 402,
        description: 'Easy-peel Nagpur santra — juicy, tangy-sweet and full of vitamin C.',
        highlights: ['Easy to peel', 'Juicy segments', 'Vitamin C rich'] },
      { title: 'Black Seedless Grapes', cat: 'seasonal-fruits', img: 'photo-1537640538966-79f369143f8f', mrp: 15000, price: 11900, tax: 0,
        options: [['Weight', '500 g', 40]], rating: 4.2, sold: 236,
        description: 'Plump, seedless black grapes from Nashik vineyards.',
        highlights: ['Seedless', 'Nashik vineyards', 'Washed before packing'] },
      { title: 'Green Kiwi', cat: 'exotic-fruits', img: 'photo-1585059895524-72359e06133a', mrp: 18000, price: 12900, tax: 0,
        options: [['Pack', '3 pcs', 35], ['Pack', '6 pcs', 12, 23900, 34000, 600]], rating: 4.3, sold: 189,
        description: 'Tangy-sweet kiwi fruit, ready to eat in 1–2 days.',
        highlights: ['Imported', 'Vitamin C rich', 'Ripens at home'] },
      { title: 'Queen Pineapple', cat: 'exotic-fruits', img: 'photo-1550258987-190a2d41a8ba', mrp: 9000, price: 6900, tax: 0,
        options: [['Size', '1 pc (approx. 1 kg)', 25]], rating: 4.1, sold: 120,
        description: 'Fragrant, sweet pineapple from the North-East. Peeling on request.',
        highlights: ['Tripura Queen variety', 'Sweet & aromatic', 'Approx. 1 kg'] },
      { title: 'Kiran Watermelon', cat: 'seasonal-fruits', img: 'photo-1587049352846-4a222e784d38', mrp: 9000, price: 6500, tax: 0,
        options: [['Size', '1 pc (approx. 2.5 kg)', 18]], rating: 4.0, sold: 96,
        description: 'Crisp, red watermelon with a thin rind — the best way to beat the heat.',
        highlights: ['Thin rind', 'Deep red flesh', 'Approx. 2–3 kg'] },
    ],
  },
  {
    store: 'Kashmir Dry Fruit House', slug: 'kashmir-dry-fruit-house', owner: 'Imran Bhat', email: 'kashmir@demo.varnixo.com',
    city: 'Srinagar', state: 'Jammu and Kashmir', pin: '190001', gstin: '01AAHCK9012L1Z4', commission: null,
    description: 'Family-run since 1987 — cashews, almonds and mixed nuts, freshly packed.',
    products: [
      { title: 'Whole Cashews W320', cat: 'nuts', img: 'photo-1509912760195-4f6cfd8cce2c', mrp: 39900, price: 29900, tax: 500,
        options: [['Weight', '250 g', 80], ['Weight', '500 g', 40, 57900, 78000, 500]], rating: 4.6, sold: 610,
        description: 'Large, creamy W320-grade whole cashews from Goa and Kerala processors.',
        highlights: ['W320 grade', 'Whole, unbroken', 'Nitrogen-flushed pack'] },
      { title: 'Mamra Almonds', cat: 'nuts', img: 'photo-1608797178974-15b35a64ede9', mrp: 79900, price: 64900, tax: 500,
        options: [['Weight', '250 g', 22], ['Weight', '500 g', 1, 124900, 155000, 500]], rating: 4.7, sold: 233,
        description: 'Prized Mamra almonds — high in natural oil, rich in taste, ideal for soaking.',
        highlights: ['High oil content', 'Hand-picked', 'Ideal for soaking'] },
      { title: 'Premium Mixed Nuts', cat: 'dry-fruit-mixes', img: 'photo-1600189020840-e9918c25269d', mrp: 59900, price: 44900, tax: 500,
        options: [['Weight', '400 g', 50]], rating: 4.4, sold: 288,
        description: 'Walnuts, pistachios, hazelnuts and almonds in one resealable pack.',
        highlights: ['4 premium nuts', 'Resealable pack', 'Unsalted'] },
      { title: 'Dry Fruit Gift Jar Set', cat: 'dry-fruit-mixes', img: 'photo-1542990253-a781e04c0082', mrp: 149900, price: 109900, tax: 500,
        options: [['Set', '4 jars (800 g)', 15]], rating: 4.8, sold: 140,
        description: 'Almonds, cashews, pistachios and goji berries in four glass jars — ready to gift.',
        highlights: ['4 glass jars', 'Gift-ready box', 'Festive favourite'] },
    ],
  },
];

const APPLICATIONS = [
  { store: 'Gau Seva Gaushala', slug: 'gau-seva-gaushala', owner: 'Ramesh Agarwal', email: 'gaushala@demo.varnixo.com', status: 'pending',
    city: 'Nabadwip', state: 'West Bengal', gstin: '19AAGCG3456P1Z1', description: 'Desi cow ghee, milk products and cow-dung diyas from our gaushala.', docs: ['gst_certificate', 'pan_card'] },
  { store: 'Green Leaf Organics', slug: 'green-leaf-organics', owner: 'Meera Nair', email: 'greenleaf@demo.varnixo.com', status: 'under_review',
    city: 'Siliguri', state: 'West Bengal', gstin: '19AAFCF7890Q1Z6', description: 'Certified organic vegetables and microgreens.', docs: ['gst_certificate'] },
];

const CUSTOMERS = [
  ['Aarav Sharma', 'Mumbai', 'Maharashtra', '400050'], ['Diya Patel', 'Ahmedabad', 'Gujarat', '380009'],
  ['Kabir Singh', 'Chandigarh', 'Chandigarh', '160017'], ['Ishita Banerjee', 'Kolkata', 'West Bengal', '700019'],
  ['Rahul Verma', 'Lucknow', 'Uttar Pradesh', '226010'], ['Sneha Joshi', 'Bengaluru', 'Karnataka', '560038'],
  ['Farhan Qureshi', 'Hyderabad', 'Telangana', '500034'], ['Neha Gupta', 'Jaipur', 'Rajasthan', '302017'],
];

// Status mix for the order book; spread across the last ~45 days.
const ORDER_PLAN = [
  'delivered', 'delivered', 'delivered', 'delivered', 'delivered', 'delivered', 'delivered', 'delivered', 'delivered', 'delivered',
  'delivered', 'delivered', 'delivered', 'delivered', 'shipped', 'shipped', 'out_for_delivery', 'packed', 'processing', 'confirmed',
  'confirmed', 'confirmed', 'cancelled', 'cancelled', 'return_requested', 'delivered', 'delivered', 'shipped', 'confirmed', 'delivered',
  'delivered', 'processing', 'delivered', 'refunded',
];
const SHIPMENT_STATUS = {
  confirmed: 'pending', processing: 'processing', packed: 'packed', shipped: 'shipped', out_for_delivery: 'out_for_delivery',
  delivered: 'delivered', cancelled: 'cancelled', return_requested: 'delivered', refunded: 'delivered',
};
const HISTORY_PATH = {
  confirmed: ['confirmed'], processing: ['confirmed', 'processing'], packed: ['confirmed', 'processing', 'packed'],
  shipped: ['confirmed', 'processing', 'packed', 'shipped'], out_for_delivery: ['confirmed', 'processing', 'packed', 'shipped', 'out_for_delivery'],
  delivered: ['confirmed', 'processing', 'packed', 'shipped', 'out_for_delivery', 'delivered'], cancelled: ['confirmed', 'cancelled'],
  return_requested: ['confirmed', 'processing', 'packed', 'shipped', 'delivered', 'return_requested'],
  refunded: ['confirmed', 'processing', 'packed', 'shipped', 'delivered', 'return_requested', 'refunded'],
};

// Deterministic pseudo-random so re-seeding a fresh database gives the same demo.
let state = 7;
const rand = () => { state = (state * 16807) % 2147483647; return (state - 1) / 2147483646; };
const pick = (list) => list[Math.floor(rand() * list.length)];

exports.seed = async function seed(knex) {
  assertDemoDatabase(knex);
  if (await knex('vendors').where({ store_slug: 'kisan-harvest-farms' }).first()) return;

  const roles = Object.fromEntries((await knex('roles').select('id', 'name')).map((r) => [r.name, r.id]));
  const admin = await knex('users').where({ email: process.env.DEMO_ADMIN_EMAIL || 'admin@demo.varnixo.com' }).first();
  const categories = Object.fromEntries((await knex('categories').select('id', 'slug', 'commission_rate_bp')).map((c) => [c.slug, c]));
  const vendorPasswordHash = await argon2.hash(demoPassword('DEMO_SELLER_PASSWORD'), { type: argon2.argon2id });
  const customerPasswordHash = await argon2.hash(demoPassword('DEMO_CUSTOMER_PASSWORD'), { type: argon2.argon2id });

  await knex.transaction(async (trx) => {
    const newUser = async ({ email, name, roleNames, passwordHash, createdAt }) => {
      const id = uuid();
      await trx('users').insert({
        id, email, full_name: name, password_hash: passwordHash, is_email_verified: true, status: 'active',
        referral_code: `VX${id.slice(0, 6).toUpperCase()}`, created_at: createdAt ?? trx.fn.now(),
      });
      await trx('user_roles').insert(roleNames.map((r) => ({ user_id: id, role_id: roles[r] })));
      await trx('wallets').insert({ id: uuid(), user_id: id });
      return id;
    };

    // ---- approved vendors with catalogues
    const catalog = []; // { productId, variantId, vendorId, warehouseId, title, sku, price, mrp, tax, commissionBp, image, label }
    const existingVendor = await trx('vendors').where({ store_slug: 'varnixo-official-store' }).first();
    if (existingVendor) {
      const rows = await trx('product_variants as v').join('products as p', 'p.id', 'v.product_id')
        .leftJoin('categories as c', 'c.id', 'p.category_id')
        .where('p.vendor_id', existingVendor.id).where('v.is_default', true)
        .select('p.id as productId', 'v.id as variantId', 'p.title', 'v.sku', 'v.sale_price_minor', 'v.mrp_minor', 'p.tax_rate_bp', 'c.commission_rate_bp');
      const warehouse = await trx('warehouses').where({ vendor_id: existingVendor.id }).first();
      const media = Object.fromEntries((await trx('product_media').whereIn('product_id', rows.map((r) => r.productId)).where('sort_order', 0)).map((m) => [m.product_id, m.url]));
      for (const r of rows) {
        catalog.push({ productId: r.productId, variantId: r.variantId, vendorId: existingVendor.id, warehouseId: warehouse?.id ?? null, title: r.title, sku: r.sku,
          price: Number(r.sale_price_minor), mrp: Number(r.mrp_minor), tax: r.tax_rate_bp, commissionBp: r.commission_rate_bp ?? 1000, image: media[r.productId] ?? null, label: null });
      }
    }

    for (const [vi, v] of VENDORS.entries()) {
      const ownerId = await newUser({ email: v.email, name: v.owner, roleNames: ['vendor', 'customer'], passwordHash: vendorPasswordHash, createdAt: daysAgo(80 - vi * 5) });
      const vendorId = uuid();
      await trx('vendors').insert({
        id: vendorId, owner_user_id: ownerId, store_name: v.store, store_slug: v.slug, description: v.description,
        support_email: v.email, support_phone: `+9198${String(76543210 + vi * 1111).padStart(8, '0')}`, gstin: v.gstin,
        pan: v.gstin.slice(2, 12), business_type: vi === 1 ? 'private_limited' : 'proprietorship', status: 'approved',
        commission_rate_bp: v.commission, approved_at: daysAgo(70 - vi * 5), approved_by: admin?.id ?? null,
        rating_avg: (4.1 + vi * 0.2).toFixed(2), rating_count: 60 + vi * 35, created_at: daysAgo(78 - vi * 5),
      });
      await trx('vendor_kyc_documents').insert([
        { id: uuid(), vendor_id: vendorId, doc_type: 'gst_certificate', file_url: 'https://example.com/demo-kyc/gst-certificate.pdf', status: 'approved', reviewed_by: admin?.id ?? null, reviewed_at: daysAgo(71) },
        { id: uuid(), vendor_id: vendorId, doc_type: 'pan_card', file_url: 'https://example.com/demo-kyc/pan-card.pdf', status: 'approved', reviewed_by: admin?.id ?? null, reviewed_at: daysAgo(71) },
      ]);
      const warehouseId = uuid();
      await trx('warehouses').insert({ id: warehouseId, vendor_id: vendorId, name: `${v.store} Warehouse`, line1: `${12 + vi} Market Road`, city: v.city, state: v.state, postal_code: v.pin, contact_phone: '+919800000000' });

      for (const [pi, p] of v.products.entries()) {
        const productId = uuid();
        const category = categories[p.cat];
        await trx('products').insert({
          id: productId, vendor_id: vendorId, category_id: category.id, title: p.title,
          slug: `${p.title.toLowerCase().replace(/[^a-z0-9\s-]/g, '').trim().replace(/\s+/g, '-')}-${v.slug}`,
          description: p.description, highlights: JSON.stringify(p.highlights), status: 'active', tax_rate_bp: p.tax, return_window_days: p.tax === 0 ? 1 : 7,
          rating_avg: p.rating.toFixed(2), rating_count: Math.round(p.sold / 4), review_count: Math.round(p.sold / 6), sold_count: p.sold,
          seo_title: `${p.title} | Varnixo`, published_at: daysAgo(60 - pi), created_at: daysAgo(65 - pi * 2),
        });
        await trx('product_media').insert([0, 1, 2].map((mi) => ({
          id: uuid(), product_id: productId, url: photo(p.img, 900, ['entropy', 'faces', 'edges'][mi]), thumbnail_url: photo(p.img, 240), alt_text: p.title, sort_order: mi,
        })));
        for (const [oi, [optName, optValue, stock, price = p.price, mrp = p.mrp, grams = 500]] of p.options.entries()) {
          const variantId = uuid();
          const sku = `${v.slug.split('-')[0].slice(0, 4).toUpperCase()}${pi}${oi}${optValue.replace(/[^A-Za-z0-9]/g, '').slice(0, 6).toUpperCase()}`;
          await trx('product_variants').insert({ id: variantId, product_id: productId, sku, mrp_minor: mrp, sale_price_minor: price, is_default: oi === 0, weight_grams: grams });
          await trx('variant_options').insert({ id: uuid(), variant_id: variantId, option_name: optName, option_value: optValue });
          await trx('inventory_stocks').insert({ variant_id: variantId, warehouse_id: warehouseId, quantity: stock, low_stock_threshold: 5 });
          if (stock > 0) await trx('inventory_movements').insert({ id: uuid(), variant_id: variantId, warehouse_id: warehouseId, movement_type: 'purchase', quantity_delta: stock, reference_type: 'seed', actor_id: ownerId });
          catalog.push({ productId, variantId, vendorId, warehouseId, title: p.title, sku, price, mrp, tax: p.tax,
            commissionBp: v.commission ?? category.commission_rate_bp ?? 1000, image: photo(p.img, 400), label: `${optName}: ${optValue}` });
        }
      }
    }

    // ---- pending vendor applications
    for (const [ai, a] of APPLICATIONS.entries()) {
      const ownerId = await newUser({ email: a.email, name: a.owner, roleNames: ['vendor', 'customer'], passwordHash: vendorPasswordHash, createdAt: daysAgo(3 - ai) });
      const vendorId = uuid();
      await trx('vendors').insert({
        id: vendorId, owner_user_id: ownerId, store_name: a.store, store_slug: a.slug, description: a.description, gstin: a.gstin,
        pan: a.gstin.slice(2, 12), business_type: 'proprietorship', support_email: a.email, status: a.status, created_at: daysAgo(3 - ai),
      });
      await trx('vendor_kyc_documents').insert(a.docs.map((doc) => ({ id: uuid(), vendor_id: vendorId, doc_type: doc, file_url: `https://example.com/demo-kyc/${doc}.pdf`, status: 'pending' })));
      await trx('warehouses').insert({ id: uuid(), vendor_id: vendorId, name: `${a.store} Store`, line1: '1 Demo Lane', city: a.city, state: a.state, postal_code: '500001' });
    }

    // ---- customers with addresses
    const customers = [];
    for (const [ci, [name, city, stateName, pin]] of CUSTOMERS.entries()) {
      const email = `${name.split(' ')[0].toLowerCase()}@demo.varnixo.com`;
      const id = await newUser({ email, name, roleNames: ['customer'], passwordHash: customerPasswordHash, createdAt: daysAgo(55 - ci * 6) });
      const address = { recipientName: name, recipientPhone: `+9199${String(10000000 + ci * 1234567).slice(0, 8)}`, line1: `${21 + ci}, ${['MG Road', 'Park Street', 'Linking Road', 'Sector 17', 'Hazratganj', 'Indiranagar 100ft Rd', 'Banjara Hills', 'C-Scheme'][ci]}`, city, state: stateName, postalCode: pin, country: 'IN' };
      await trx('addresses').insert({ id: uuid(), user_id: id, label: 'home', recipient_name: name, recipient_phone: address.recipientPhone, line1: address.line1, city, state: stateName, postal_code: pin, is_default: true });
      customers.push({ id, name, address });
    }

    // ---- orders across the lifecycle, split into per-vendor shipments
    const seq = async () => (await trx.raw("SELECT nextval('order_number_seq') AS n")).rows[0].n;
    const reviewable = [];
    for (const [oi, status] of ORDER_PLAN.entries()) {
      const customer = customers[oi % customers.length];
      const placed = daysAgo(Math.max(0, 44 - Math.round(oi * 1.3)), 9 + (oi % 9));
      const lines = [];
      const count = 1 + Math.floor(rand() * 3);
      while (lines.length < count) {
        const item = pick(catalog);
        if (!lines.some((l) => l.item.variantId === item.variantId)) lines.push({ item, qty: 1 + Math.floor(rand() * 2) });
      }
      const subtotal = lines.reduce((s, l) => s + l.item.price * l.qty, 0);
      const shipping = subtotal >= 49900 ? 0 : 4900;
      const discount = oi % 7 === 3 ? Math.min(20000, Math.round(subtotal * 0.1)) : 0;
      const total = subtotal + shipping - discount;
      const paymentMethod = oi % 3 === 0 ? 'cod' : 'razorpay';
      const orderId = uuid();
      await trx('orders').insert({
        id: orderId, order_number: `VX${await seq()}`, user_id: customer.id, status,
        subtotal_minor: subtotal, discount_minor: discount, coupon_code: discount ? 'WELCOME10' : null, shipping_minor: shipping,
        tax_minor: lines.reduce((s, l) => s + Math.round((l.item.price * l.qty * l.item.tax) / (10000 + l.item.tax)), 0),
        total_minor: total, payment_method: paymentMethod, shipping_address: JSON.stringify(customer.address),
        cancelled_reason: status === 'cancelled' ? 'Customer changed their mind' : null,
        placed_at: placed, created_at: placed, updated_at: placed,
      });

      const shipmentByVendor = {};
      for (const { item } of lines) {
        if (shipmentByVendor[item.vendorId]) continue;
        const shipmentId = uuid();
        const sStatus = SHIPMENT_STATUS[status];
        const shipped = ['shipped', 'out_for_delivery', 'delivered'].includes(sStatus);
        await trx('order_shipments').insert({
          id: shipmentId, order_id: orderId, vendor_id: item.vendorId, warehouse_id: item.warehouseId, status: sStatus,
          courier: shipped ? pick(['delhivery', 'bluedart', 'shiprocket']) : null,
          awb_number: shipped ? `AWB${String(Math.floor(rand() * 1e10)).padStart(10, '0')}` : null,
          shipped_at: shipped ? new Date(placed.getTime() + DAY) : null,
          delivered_at: sStatus === 'delivered' ? new Date(placed.getTime() + 3 * DAY) : null, created_at: placed,
        });
        shipmentByVendor[item.vendorId] = shipmentId;
      }

      for (const { item, qty } of lines) {
        const line = item.price * qty;
        const itemId = uuid();
        await trx('order_items').insert({
          id: itemId, order_id: orderId, shipment_id: shipmentByVendor[item.vendorId], product_id: item.productId, variant_id: item.variantId,
          vendor_id: item.vendorId, title: item.title, variant_label: item.label, sku: item.sku, image_url: item.image,
          unit_price_minor: item.price, mrp_minor: item.mrp, quantity: qty, tax_rate_bp: item.tax,
          tax_minor: Math.round((line * item.tax) / (10000 + item.tax)), commission_rate_bp: item.commissionBp,
          commission_minor: Math.round((line * item.commissionBp) / 10000), line_total_minor: line, created_at: placed,
        });
        if (status === 'delivered') reviewable.push({ productId: item.productId, userId: customer.id, itemId, at: new Date(placed.getTime() + 5 * DAY) });
        if (status === 'return_requested' || status === 'refunded') {
          await trx('return_requests').insert({
            id: uuid(), order_id: orderId, order_item_id: itemId, user_id: customer.id, request_type: 'return', reason: 'damaged',
            description: 'A few pieces arrived bruised, would like a refund.', status: status === 'refunded' ? 'refunded' : 'requested', quantity: 1,
            refund_amount_minor: item.price, created_at: new Date(placed.getTime() + 5 * DAY),
          });
        }
      }

      let at = placed.getTime();
      let previous = null;
      for (const step of HISTORY_PATH[status]) {
        await trx('order_status_history').insert({ id: uuid(), order_id: orderId, from_status: previous, to_status: step, note: step === 'confirmed' ? 'Order placed' : null, created_at: new Date(at) });
        previous = step;
        at += step === 'shipped' ? 2 * DAY : 9 * 3600000;
      }

      const captured = paymentMethod !== 'cod' ? status !== 'cancelled' || oi % 2 === 0 : ['delivered', 'return_requested', 'refunded'].includes(status);
      const paymentId = uuid();
      await trx('payments').insert({
        id: paymentId, order_id: orderId, provider: paymentMethod, amount_minor: total,
        provider_payment_id: paymentMethod === 'cod' ? null : `pay_DEMO${orderId.slice(0, 12)}`,
        status: captured ? 'captured' : paymentMethod === 'cod' ? 'pending' : 'cancelled',
        captured_at: captured ? new Date(placed.getTime() + (paymentMethod === 'cod' ? 3 * DAY : 60000)) : null, created_at: placed,
      });
      if (status === 'refunded' || (status === 'cancelled' && captured)) {
        await trx('refunds').insert({ id: uuid(), payment_id: paymentId, amount_minor: total, destination: 'source', status: 'completed', initiated_by: admin?.id ?? null, completed_at: new Date(placed.getTime() + 7 * DAY), created_at: new Date(placed.getTime() + 6 * DAY) });
      }
    }

    // ---- reviews (approved + a moderation queue)
    const seen = new Set();
    const reviewTexts = [
      [5, 'Really fresh', 'Tasted like it was picked this morning. Delivery was on time.'],
      [4, 'Good value', 'Good quality for the price. Packaging could be better.'],
      [5, 'Loved it', 'Second order from this seller. Consistently fresh.'],
      [3, 'Decent', 'Mostly good, a couple of pieces were a little overripe.'],
      [4, 'Recommended', 'Well sorted and properly weighed. Will order again.'],
    ];
    for (const [ri, r] of reviewable.entries()) {
      const key = `${r.productId}:${r.userId}`;
      if (seen.has(key)) continue;
      seen.add(key);
      const [rating, title, body] = reviewTexts[ri % reviewTexts.length];
      await trx('reviews').insert({ id: uuid(), product_id: r.productId, user_id: r.userId, order_item_id: r.itemId, rating, title, body, status: ri % 4 === 0 ? 'pending' : 'approved', created_at: r.at });
    }

    // ---- promotions, banners and help content
    await trx('coupons').insert([
      { id: uuid(), code: 'WELCOME10', title: '10% off your first order', description: 'Up to ₹100 off for new shoppers.', discount_type: 'percent', discount_value: 1000, max_discount_minor: 10000, min_order_minor: 29900, usage_limit_total: 5000, usage_limit_per_user: 1, applicable_scope: 'all', created_by: admin?.id ?? null, starts_at: daysAgo(60), ends_at: daysAgo(-90), is_active: true },
      { id: uuid(), code: 'FRESH50', title: '₹50 off fresh picks', description: 'On orders above ₹499.', discount_type: 'fixed', discount_value: 5000, min_order_minor: 49900, usage_limit_total: 1000, usage_limit_per_user: 2, applicable_scope: 'all', created_by: admin?.id ?? null, starts_at: daysAgo(10), ends_at: daysAgo(-20), is_active: true },
      { id: uuid(), code: 'WINTER20', title: 'Winter dry fruit sale — 20% off', description: 'Scheduled seasonal campaign.', discount_type: 'percent', discount_value: 2000, max_discount_minor: 30000, min_order_minor: 99900, usage_limit_per_user: 1, applicable_scope: 'all', created_by: admin?.id ?? null, starts_at: daysAgo(-14), ends_at: daysAgo(-24), is_active: true },
      { id: uuid(), code: 'MANGO15', title: 'Mango season', description: 'Ended campaign.', discount_type: 'percent', discount_value: 1500, max_discount_minor: 15000, min_order_minor: 49900, usage_limit_per_user: 1, applicable_scope: 'all', created_by: admin?.id ?? null, starts_at: daysAgo(100), ends_at: daysAgo(70), is_active: true },
    ]);
    await trx('banners').insert([
      { id: uuid(), title: 'Farm-fresh vegetables, delivered daily', image_url: photo('photo-1488459716781-31db52582fe9', 1600), placement: 'home_hero', target_type: 'category', target_value: 'vegetables', sort_order: 0, is_active: true },
      { id: uuid(), title: 'Seasonal fruit from India’s orchards', image_url: photo('photo-1610832958506-aa56368176cf', 1600), placement: 'home_hero', target_type: 'category', target_value: 'fresh-fruits', sort_order: 1, is_active: true },
      { id: uuid(), title: 'Dry fruits for the winter', image_url: photo('photo-1542990253-a781e04c0082', 1600), placement: 'home_secondary', target_type: 'category', target_value: 'dry-fruits', sort_order: 0, is_active: true },
    ]);
    await trx('pages').insert([
      { id: uuid(), slug: 'shipping-and-returns', title: 'Shipping & Returns', is_published: true, body: 'Free delivery on orders above ₹499. Fresh vegetables and fruits are delivered the same or next day; dry fruits within 2–5 business days.\n\nIf anything arrives damaged or not fresh, tell us within 24 hours of delivery from Your orders and we will refund or replace it. Packed dry fruits can be returned unopened within 7 days.' },
      { id: uuid(), slug: 'about', title: 'About Varnixo', is_published: true, body: 'Varnixo brings fresh vegetables, fruits and dry fruits from trusted farmers and sellers to your door, with secure checkout and real people in support.\n\nCall or WhatsApp us on +91 93392 44573.' },
    ]);
    await trx('faqs').insert([
      { id: uuid(), category: 'orders', question: 'How do I track my order?', answer: 'Open Your orders from your account to see live status for every shipment.', sort_order: 0 },
      { id: uuid(), category: 'payments', question: 'Is cash on delivery available?', answer: 'Yes, on all orders up to ₹50,000.', sort_order: 1 },
      { id: uuid(), category: 'returns', question: 'What if my vegetables or fruit are not fresh?', answer: 'Report it within 24 hours of delivery and we will refund or replace the item.', sort_order: 2 },
      { id: uuid(), category: 'sellers', question: 'How do I sell on Varnixo?', answer: 'Apply as a seller with your GST and bank details. Our team reviews applications within 2 business days.', sort_order: 3 },
    ]);
  });
};
