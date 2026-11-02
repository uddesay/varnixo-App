import type { CapacitorConfig } from '@capacitor/cli';

// Local test builds talk to the dev API over plain http (emulator: 10.0.2.2),
// which the https://localhost app origin would otherwise block as mixed content.
// Release builds must point VITE_API_BASE_URL at an https API and leave this off.
const devApi = process.env.VARNIXO_DEV_API === '1';

const config: CapacitorConfig = {
  appId: 'com.varnixo.app',
  appName: 'Varnixo',
  webDir: 'dist',
  android: {
    allowMixedContent: devApi,
    backgroundColor: '#fbf8f2',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 1200,
      backgroundColor: '#0a2012',
      showSpinner: false,
    },
  },
};

export default config;
