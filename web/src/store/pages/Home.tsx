import { useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft, ArrowRight, BadgeCheck, Banknote, Copy, Leaf, MessageCircle, Phone, Sprout, Truck } from 'lucide-react';

import { customerEnvelope, customerRequest } from '../../pages/shop/storeApi';
import { money, photo } from '../../pages/shop/storeFormat';
import { SUPPORT_PHONE } from '../brand';
import { useStore } from '../StoreContext';
import { useDepartments, type Department } from '../StoreLayout';
import type { Product } from '../types';
import { CardSkeletons, Img, ProductCard, Reveal, useLoad } from '../ui';
import './home.css';

type Tab = 'popularity' | 'newest' | 'rating';
const tabs: { id: Tab; label: string }[] = [{ id: 'popularity', label: 'Best sellers' }, { id: 'newest', label: 'Just arrived' }, { id: 'rating', label: 'Top rated' }];
const off = (p: Product) => (Number(p.min_mrp) > Number(p.min_price) ? Math.round((1 - Number(p.min_price) / Number(p.min_mrp)) * 100) : 0);
const pick = (rows: Product[], word: string) => rows.find((p) => p.slug.includes(word) && p.image?.url);
const sized = (url: string | undefined, w: number) => url?.replace(/([?&])w=\d+/, `$1w=${w}`);
const tint: Record<string, string> = { vegetables: 'leaf', 'fresh-fruits': 'mango', 'dry-fruits': 'nut' };
const GAUSHALA_IMG = 'photo-1527153857715-3908f2bae5e8';
const SELLER_IMG = 'photo-1582515073490-39981397c445'; // freshly pulled carrots in a wooden crate

const perks = [
  { icon: Leaf, title: 'Fresh every morning', text: 'Sorted by hand on the day it ships' },
  { icon: Truck, title: 'Free delivery', text: 'On every order above ₹499' },
  { icon: Banknote, title: 'Cash on delivery', text: 'Pay when your basket arrives' },
  { icon: BadgeCheck, title: 'Freshness promise', text: 'Not fresh? Refund or replace' },
];

/** One horizontal product row per department. */
function DeptRow({ dept }: { dept: Department }) {
  const rows = useLoad(() => customerRequest<Product[]>(`/products?category=${dept.slug}&limit=10&sort=popularity`), [dept.slug]);
  const ref = useRef<HTMLDivElement>(null);
  const scroll = (dir: number) => ref.current?.scrollBy({ left: dir * ref.current.clientWidth * 0.8, behavior: 'smooth' });
  return (
    <section className={`vx-row vx-tint-${tint[dept.slug] ?? 'leaf'}`} aria-labelledby={`row-${dept.slug}`}>
      <div className="vx-row-head">
        <div>
          <h2 id={`row-${dept.slug}`}>{dept.label}</h2>
          <p>{dept.blurb}</p>
        </div>
        <div className="vx-row-actions">
          <Link className="vx-pill-link" to={`/shop?category=${dept.slug}`}>View all {dept.count} <ArrowRight size={16} /></Link>
          <div className="ms-rail-nav"><button aria-label="Scroll back" onClick={() => scroll(-1)}><ArrowLeft size={18} /></button><button aria-label="Scroll forward" onClick={() => scroll(1)}><ArrowRight size={18} /></button></div>
        </div>
      </div>
      {dept.children.length > 0 && (
        <div className="vx-chips">{dept.children.map((s) => <Link key={s.id} to={`/shop?category=${s.slug}`}>{s.name}</Link>)}</div>
      )}
      <div className="ms-rail vx-rail" ref={ref}>
        {rows.loading ? <CardSkeletons count={5} /> : (rows.data ?? []).map((p, i) => <ProductCard key={p.id} product={p} index={i % 5} />)}
      </div>
    </section>
  );
}

export function Home() {
  const { toast } = useStore();
  const depts = useDepartments();
  const stocked = depts.filter((d) => d.count > 0);
  const [tab, setTab] = useState<Tab>('popularity');

  const meta = useLoad(async () => {
    const catalog = await customerEnvelope<Product[]>('/products?limit=40&sort=popularity');
    return { total: catalog.meta?.total ?? catalog.data.length, all: catalog.data };
  }, []);
  const best = useLoad(() => customerRequest<Product[]>(`/products?limit=10&sort=${tab}`), [tab]);

  const all = meta.data?.all ?? [];
  const collage = [pick(all, 'mango'), pick(all, 'tomato'), pick(all, 'cashew')].map((p, i) => p ?? all.filter((x) => x.image?.url)[i]);
  const maxOff = all.reduce((m, p) => Math.max(m, off(p)), 0);
  const copyCode = () => { void navigator.clipboard?.writeText('FRESH50').then(() => toast('Code FRESH50 copied — apply it in your bag')).catch(() => toast('Use code FRESH50 in your bag')); };

  return (
    <div className="vx-home">
      {/* ---------------- hero */}
      <section className="ms-wrap vx-hero" aria-labelledby="hero-title">
        <div className="vx-hero-copy">
          <span className="vx-badge"><Sprout size={15} /> Delivering fresh today</span>
          <h1 id="hero-title">Fresh vegetables &amp; fruits, <span>delivered to your door.</span></h1>
          <p>Farm-fresh vegetables, seasonal fruit and premium dry fruits from farmers and sellers we know by name. Order online or on WhatsApp.</p>
          <div className="vx-hero-cta">
            <Link to="/shop" className="vx-btn vx-btn-mango">Start shopping <ArrowRight size={18} /></Link>
            <a href={SUPPORT_PHONE.whatsapp} target="_blank" rel="noreferrer" className="vx-btn vx-btn-ghost"><MessageCircle size={18} /> Order on WhatsApp</a>
          </div>
          <ul className="vx-hero-stats">
            <li><b>{meta.data ? meta.data.total : '—'}</b><span>fresh items</span></li>
            <li><b>{stocked.length || '—'}</b><span>departments</span></li>
            <li><b>₹499</b><span>free delivery above</span></li>
          </ul>
        </div>
        <div className="vx-hero-art" aria-hidden={!collage[0]}>
          {collage.map((p, i) => (p ? (
            <Link key={p.id} to={`/product/${p.slug}`} className={`vx-bubble vx-bubble-${i}`} aria-label={p.title}>
              <Img src={sized(p.image?.url, i === 0 ? 900 : 500)} alt={p.title} eager sizes="(min-width: 900px) 24vw, 40vw" />
              <span className="vx-tag"><b>{p.title}</b>{money(Number(p.min_price))}</span>
            </Link>
          ) : <div key={i} className={`vx-bubble vx-bubble-${i} ms-skel`} />))}
          {maxOff > 0 && <span className="vx-stamp">Up to<b>{maxOff}%</b>off</span>}
        </div>
      </section>

      {/* ---------------- categories */}
      <section className="ms-wrap vx-sec" aria-labelledby="cat-title">
        <div className="vx-sec-head"><h2 id="cat-title">Shop by category</h2></div>
        <div className="vx-cats">
          {stocked.length === 0 ? Array.from({ length: 4 }, (_, i) => <div key={i} className="vx-cat ms-skel" />)
            : stocked.map((d, i) => (
              <Reveal as={Link} key={d.id} index={i} className={`vx-cat vx-tint-${tint[d.slug] ?? 'leaf'}`} {...{ to: `/shop?category=${d.slug}` }}>
                <span className="vx-cat-img"><Img src={d.image} alt="" sizes="160px" /></span>
                <b>{d.label}</b>
                <small>{d.count} {d.count === 1 ? 'item' : 'items'}</small>
              </Reveal>
            ))}
          {!stocked.some((d) => d.slug === 'gaushala-products') && (
            <div className="vx-cat vx-cat-soon">
              <span className="vx-cat-img"><Img src={photo(GAUSHALA_IMG, 400)} alt="" sizes="160px" /></span>
              <b>Gaushala Products</b>
              <small>Coming soon</small>
            </div>
          )}
        </div>
      </section>

      {/* ---------------- perks */}
      <section className="ms-wrap vx-perks" aria-label="Why Varnixo">
        {perks.map(({ icon: Icon, title, text }) => (
          <div key={title}><span><Icon size={22} /></span><p><b>{title}</b>{text}</p></div>
        ))}
      </section>

      {/* ---------------- best sellers */}
      <section className="ms-wrap vx-sec" aria-labelledby="best-title">
        <div className="vx-sec-head">
          <h2 id="best-title">Popular this week</h2>
          <div className="vx-seg" role="tablist" aria-label="Collections">
            {tabs.map((t) => <button key={t.id} role="tab" aria-selected={tab === t.id} onClick={() => setTab(t.id)}>{t.label}</button>)}
          </div>
        </div>
        {best.error ? <p className="ms-alert">{best.error} <button className="ms-link" onClick={best.retry}>Try again</button></p> : (
          <div className="vx-grid" role="tabpanel" key={tab}>
            {best.loading ? <CardSkeletons count={5} /> : (best.data ?? []).slice(0, 10).map((p, i) => <ProductCard key={p.id} product={p} index={i % 5} />)}
          </div>
        )}
      </section>

      {/* ---------------- offer */}
      <section className="ms-wrap vx-sec">
        <Reveal className="vx-offer">
          <div>
            <span className="vx-badge vx-badge-dark">Limited offer</span>
            <h2>₹50 off your fresh basket</h2>
            <p>On any order above ₹499. New here? <b>WELCOME10</b> gives 10% off your first order.</p>
            <button className="vx-code" onClick={copyCode}><b>FRESH50</b><span><Copy size={15} /> Copy code</span></button>
          </div>
          <div className="vx-offer-img"><Img src={photo('photo-1610832958506-aa56368176cf', 1000)} alt="" sizes="(min-width: 900px) 40vw, 90vw" /></div>
        </Reveal>
      </section>

      {/* ---------------- department rows */}
      <div className="ms-wrap vx-rows">
        {stocked.map((d) => <DeptRow key={d.id} dept={d} />)}
      </div>

      {/* ---------------- whatsapp band */}
      <section className="ms-wrap vx-sec">
        <Reveal className="vx-wa">
          <span className="vx-wa-icon"><MessageCircle size={30} /></span>
          <div>
            <h2>Order on call or WhatsApp</h2>
            <p>Send us your list and we’ll pack it fresh. Same-day delivery on orders placed before noon.</p>
          </div>
          <div className="vx-wa-cta">
            <a className="vx-btn vx-btn-white" href={SUPPORT_PHONE.whatsapp} target="_blank" rel="noreferrer"><MessageCircle size={18} /> WhatsApp</a>
            <a className="vx-btn vx-btn-ghost" href={SUPPORT_PHONE.tel}><Phone size={18} /> {SUPPORT_PHONE.display}</a>
          </div>
        </Reveal>
      </section>

      {/* ---------------- sellers */}
      <section className="ms-wrap vx-sec vx-last">
        <Reveal className="vx-seller">
          <div className="vx-seller-img"><Img src={photo(SELLER_IMG, 900)} alt="Freshly harvested carrots in a wooden crate" sizes="(min-width: 900px) 34vw, 90vw" /></div>
          <div>
            <span className="vx-badge">For farmers &amp; sellers</span>
            <h2>Sell your harvest on Varnixo</h2>
            <p>Farmers, orchards, dry fruit traders and gaushalas — apply once, get verified in 2 business days, and reach customers across the city.</p>
            <ol>
              <li><b>Apply</b> with your business and pickup details</li>
              <li><b>Get verified</b> — we review KYC quickly</li>
              <li><b>Sell &amp; get paid</b> with transparent commission</li>
            </ol>
            <Link to="/sell" className="vx-btn vx-btn-green">Start selling <ArrowRight size={18} /></Link>
          </div>
        </Reveal>
      </section>
    </div>
  );
}
