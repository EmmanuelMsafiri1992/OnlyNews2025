import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';
import legacy from '@vitejs/plugin-legacy';
import os from 'os';

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost'; // fallback if no LAN IP found
}

export default defineConfig({
  plugins: [
    laravel({
      input: [
        'resources/css/app.css',
        'resources/js/app.js',
      ],
      refresh: true,
    }),
    vue(),
    legacy({
      // Targets for maximum compatibility, including very old TV browsers like Chrome 25
      targets: [
        'chrome >= 25', // Samsung TV 2014 models use Chrome 25
        'ie >= 11', // Support for Internet Explorer 11
        'safari >= 9', // iOS Safari 9+
        'edge >= 12', // Microsoft Edge
        'firefox >= 38', // Firefox ESR
        'samsung >= 4', // Samsung Internet Browser (Tizen TVs)
        'android >= 4.4', // Android WebView (older smart TVs)
      ],
      additionalLegacyPolyfills: [
        'regenerator-runtime/runtime', // For async/await
        'core-js/stable', // Full core-js polyfills for ES5+ features
      ],
      // Render legacy chunks for all browsers
      renderLegacyChunks: true,
      // This ensures polyfills are included
      modernPolyfills: true,
      // Explicitly set polyfills mode
      polyfills: true,
    }),
  ],
  css: {
    postcss: './postcss.config.js',
  },
  server: {
    host: '0.0.0.0', // CHANGE THIS LINE to allow access from other devices on the network
    port: 5173,
    hmr: {
      host: getLocalIp(), // Use local IP for HMR to work across devices
      clientPort: 5173,
    },
  },
  build: {
    // Don't set target here - let legacy plugin handle it
    minify: true, // Ensure code is minified for production
    cssCodeSplit: true, // Split CSS into chunks
    sourcemap: false, // Disable sourcemaps for production builds to reduce size
    cssMinify: 'esbuild', // Use esbuild for CSS minification (handles invalid selectors better)
  }
});
