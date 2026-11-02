import { lazy, Suspense, type ComponentType, type ReactNode } from 'react';
import { BrowserRouter, Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';

import { AuthProvider, useAuth } from './auth/AuthContext';
import { RequireAuth, RequirePermission } from './auth/RequireAuth';
import { AppErrorBoundary } from './components/ui/AppErrorBoundary';
import { ConfirmProvider } from './components/ui/ConfirmDialog';
import { PageSkeleton } from './components/ui/Skeleton';
import { ToastProvider } from './components/ui/Toast';
import { ThemeProvider } from './lib/theme';
import { StoreLayout } from './store/StoreLayout';
import { Home } from './store/pages/Home';

/**
 * Lazy-load every screen except the storefront home so first paint stays small.
 * Called at module scope so every route keeps a stable component identity.
 */
const lazyPage = <K extends string>(loader: () => Promise<Record<K, unknown>>, name: K, fallback: ReactNode = <PageSkeleton />) => {
  const Component = lazy(async () => ({ default: (await loader())[name] as ComponentType }));
  return function LazyPage() {
    return <Suspense fallback={fallback}><Component /></Suspense>;
  };
};

/** Storefront pages load behind a quiet placeholder that keeps the page height stable. */
const storePage = <K extends string>(loader: () => Promise<Record<K, unknown>>, name: K) =>
  lazyPage(loader, name, <div className="ms-route-loading" aria-busy="true" aria-label="Loading" />);

const Shop = storePage(() => import('./store/pages/Shop'), 'Shop');
const ProductPage = storePage(() => import('./store/pages/ProductPage'), 'ProductPage');
const CartPage = storePage(() => import('./store/pages/CartPage'), 'CartPage');
const Checkout = storePage(() => import('./store/pages/Checkout'), 'Checkout');
const SignIn = storePage(() => import('./store/pages/SignIn'), 'SignIn');
const AccountLayout = storePage(() => import('./store/pages/Account'), 'AccountLayout');
const AccountHome = storePage(() => import('./store/pages/Account'), 'AccountHome');
const Orders = storePage(() => import('./store/pages/Account'), 'Orders');
const OrderView = storePage(() => import('./store/pages/Account'), 'OrderView');
const Wishlist = storePage(() => import('./store/pages/Misc'), 'Wishlist');
const Sell = storePage(() => import('./store/pages/Misc'), 'Sell');
const Help = storePage(() => import('./store/pages/Misc'), 'Help');

const LoginPage = lazyPage(() => import('./auth/LoginPage'), 'LoginPage', null);
const AppShell = lazyPage(() => import('./components/layout/AppShell'), 'AppShell', null);

const DashboardPage = lazyPage(() => import('./pages/dashboard/DashboardPage'), 'DashboardPage');
const AnalyticsPage = lazyPage(() => import('./pages/analytics/AnalyticsPage'), 'AnalyticsPage');
const ProductsPage = lazyPage(() => import('./pages/catalog/ProductsPage'), 'ProductsPage');
const ProductEditorPage = lazyPage(() => import('./pages/catalog/ProductEditorPage'), 'ProductEditorPage');
const CategoriesPage = lazyPage(() => import('./pages/catalog/CategoriesPage'), 'CategoriesPage');
const BrandsPage = lazyPage(() => import('./pages/catalog/BrandsPage'), 'BrandsPage');
const InventoryPage = lazyPage(() => import('./pages/catalog/InventoryPage'), 'InventoryPage');
const CouponsPage = lazyPage(() => import('./pages/catalog/CouponsPage'), 'CouponsPage');
const OrdersPage = lazyPage(() => import('./pages/orders/OrdersPage'), 'OrdersPage');
const OrderDetailPage = lazyPage(() => import('./pages/orders/OrderDetailPage'), 'OrderDetailPage');
const ReturnsPage = lazyPage(() => import('./pages/returns/ReturnsPage'), 'ReturnsPage');
const ShipmentsPage = lazyPage(() => import('./pages/shipments/ShipmentsPage'), 'ShipmentsPage');
const PayoutsPage = lazyPage(() => import('./pages/payouts/PayoutsPage'), 'PayoutsPage');
const VendorsPage = lazyPage(() => import('./pages/vendors/VendorsPage'), 'VendorsPage');
const VendorApplicationsPage = lazyPage(() => import('./pages/vendors/VendorApplicationsPage'), 'VendorApplicationsPage');
const VendorDetailPage = lazyPage(() => import('./pages/vendors/VendorDetailPage'), 'VendorDetailPage');
const CommissionsPage = lazyPage(() => import('./pages/vendors/CommissionsPage'), 'CommissionsPage');
const CustomersPage = lazyPage(() => import('./pages/users/UsersPage'), 'CustomersPage');
const UserDetailPage = lazyPage(() => import('./pages/users/UserDetailPage'), 'UserDetailPage');
const StaffPage = lazyPage(() => import('./pages/users/UsersPage'), 'StaffPage');
const ReviewsPage = lazyPage(() => import('./pages/reviews/ReviewsPage'), 'ReviewsPage');
const SupportTicketsPage = lazyPage(() => import('./pages/support/SupportTicketsPage'), 'SupportTicketsPage');
const SupportTicketDetailPage = lazyPage(() => import('./pages/support/SupportTicketDetailPage'), 'SupportTicketDetailPage');
const BannersPage = lazyPage(() => import('./pages/cms/BannersPage'), 'BannersPage');
const PagesPage = lazyPage(() => import('./pages/cms/PagesPage'), 'PagesPage');
const BlogsPage = lazyPage(() => import('./pages/cms/BlogsPage'), 'BlogsPage');
const FaqsPage = lazyPage(() => import('./pages/cms/FaqsPage'), 'FaqsPage');
const NotificationsPage = lazyPage(() => import('./pages/notifications/NotificationsPage'), 'NotificationsPage');
const SettingsPage = lazyPage(() => import('./pages/settings/SettingsPage'), 'SettingsPage');
const AuditLogsPage = lazyPage(() => import('./pages/audit/AuditLogsPage'), 'AuditLogsPage');
const NotFoundPage = lazyPage(() => import('./pages/NotFoundPage'), 'NotFoundPage');

const guard = (permission: string, element: ReactNode) => <RequirePermission permission={permission}>{element}</RequirePermission>;

/** Staff screens share theme, toasts and confirmations; the storefront does not. */
function StaffProviders() {
  return (
    <ThemeProvider>
      <ToastProvider>
        <ConfirmProvider>
          <Outlet />
        </ConfirmProvider>
      </ToastProvider>
    </ThemeProvider>
  );
}

/** Unknown URLs: staff get the admin 404, everyone else goes to the storefront. */
function CatchAll() {
  const { status } = useAuth();
  const location = useLocation();
  if (status === 'unknown') return null;
  return status === 'authenticated'
    ? <Navigate to="/not-found" replace state={{ from: location.pathname }} />
    : <Navigate to="/" replace />;
}

export default function App() {
  return (
    <AppErrorBoundary>
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route element={<StoreLayout />}>
              <Route path="/" element={<Home />} />
              <Route path="/shop" element={<Shop />} />
              <Route path="/product/:slug" element={<ProductPage />} />
              <Route path="/cart" element={<CartPage />} />
              <Route path="/checkout" element={<Checkout />} />
              <Route path="/signin" element={<SignIn />} />
              <Route path="/wishlist" element={<Wishlist />} />
              <Route path="/sell" element={<Sell />} />
              <Route path="/help/:slug" element={<Help />} />
              <Route path="/account" element={<AccountLayout />}>
                <Route index element={<AccountHome />} />
                <Route path="orders" element={<Orders />} />
                <Route path="orders/:id" element={<OrderView />} />
              </Route>
            </Route>
            <Route element={<StaffProviders />}>
              <Route path="/login" element={<LoginPage />} />
              <Route element={<RequireAuth><AppShell /></RequireAuth>}>
                <Route path="/dashboard" element={guard('analytics:read', <DashboardPage />)} />
                <Route path="/analytics" element={guard('analytics:read', <AnalyticsPage />)} />

                <Route path="/products" element={guard('products:read', <ProductsPage />)} />
                <Route path="/products/new" element={guard('products:create', <ProductEditorPage />)} />
                <Route path="/products/:id" element={guard('products:read', <ProductEditorPage />)} />
                <Route path="/categories" element={guard('categories:manage', <CategoriesPage />)} />
                <Route path="/brands" element={guard('brands:manage', <BrandsPage />)} />
                <Route path="/inventory" element={guard('inventory:manage', <InventoryPage />)} />
                <Route path="/coupons" element={guard('coupons:manage', <CouponsPage />)} />

                <Route path="/orders" element={guard('orders:read', <OrdersPage />)} />
                <Route path="/orders/:id" element={guard('orders:read', <OrderDetailPage />)} />
                <Route path="/returns" element={guard('returns:read', <ReturnsPage />)} />
                <Route path="/shipments" element={guard('orders:fulfill', <ShipmentsPage />)} />
                <Route path="/payouts" element={guard('payouts:approve', <PayoutsPage />)} />

                <Route path="/vendors" element={guard('vendors:read', <VendorsPage />)} />
                <Route path="/vendors/applications" element={guard('vendors:read', <VendorApplicationsPage />)} />
                <Route path="/vendors/:id" element={guard('vendors:read', <VendorDetailPage />)} />
                <Route path="/commissions" element={guard('categories:manage', <CommissionsPage />)} />

                <Route path="/customers" element={guard('users:read', <CustomersPage />)} />
                <Route path="/customers/:id" element={guard('users:read', <UserDetailPage />)} />
                <Route path="/staff" element={guard('users:read', <StaffPage />)} />
                <Route path="/staff/:id" element={guard('users:read', <UserDetailPage />)} />
                <Route path="/users" element={<Navigate to="/customers" replace />} />
                <Route path="/users/:id" element={<Navigate to="/customers" replace />} />
                <Route path="/reviews" element={guard('reviews:moderate', <ReviewsPage />)} />
                <Route path="/support/tickets" element={guard('support:manage', <SupportTicketsPage />)} />
                <Route path="/support/tickets/:id" element={guard('support:manage', <SupportTicketDetailPage />)} />

                <Route path="/cms/banners" element={guard('cms:manage', <BannersPage />)} />
                <Route path="/cms/pages" element={guard('cms:manage', <PagesPage />)} />
                <Route path="/cms/blogs" element={guard('cms:manage', <BlogsPage />)} />
                <Route path="/cms/faqs" element={guard('cms:manage', <FaqsPage />)} />

                <Route path="/notifications" element={<NotificationsPage />} />
                <Route path="/settings" element={guard('settings:manage', <SettingsPage />)} />
                <Route path="/platform" element={<Navigate to="/settings" replace />} />
                <Route path="/audit-logs" element={guard('audit_logs:read', <AuditLogsPage />)} />
                <Route path="/admin" element={<Navigate to="/dashboard" replace />} />
                <Route path="/not-found" element={<NotFoundPage />} />
              </Route>
            </Route>
            <Route path="*" element={<CatchAll />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </AppErrorBoundary>
  );
}
