import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    // Workspace libs are consumed from source, so edits show up without rebuilding them.
    conditions: ['source'],
  },
  server: {
    port: Number(process.env['ADMIN_PORT'] ?? 5173),
    strictPort: true,
    proxy: {
      '/api': {
        // Override when the API runs on another port (e.g. API_PROXY_TARGET=http://localhost:3001).
        target: process.env['API_PROXY_TARGET'] ?? 'http://localhost:3000',
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
});
