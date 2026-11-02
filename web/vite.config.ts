import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// Varnixo runs on its own ports so it never collides with other local projects.
const API = 'http://127.0.0.1:4200';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5373,
    strictPort: true,
    proxy: { '/api': { target: API, changeOrigin: true }, '/socket.io': { target: API, ws: true } },
  },
  preview: { port: 5373 },
});
