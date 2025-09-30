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
      // Targets for broader compatibility, including older TV browsers and IE11
      targets: [
        'defaults', // Covers most modern browsers
        'not IE 11', // Explicitly exclude IE 11 from default targets if you want to be more specific, but 'ie >= 11' below will handle it
        'ie >= 11', // Support for Internet Explorer 11
        'chrome >= 49', // Chrome for Android 4.4+ (older Tizen/WebOS might use older Chromium)
        'safari >= 9', // iOS Safari 9+
        'edge >= 12', // Microsoft Edge
        'firefox >= 45', // Firefox
        'samsung >= 5', // Samsung Internet Browser (common on Tizen TVs)
        'opera >= 36', // Opera
        'android >= 4.4', // Android WebView (older smart TVs might use this)
        'last 2 versions', // Ensures recent browser versions are covered
      ],
      additionalLegacyPolyfills: [
        'regenerator-runtime/runtime', // For async/await
        'core-js/es/array', // For array methods like includes, find
        'core-js/es/promise', // For Promises
        'core-js/es/symbol', // For Symbol
        'core-js/es/object/assign', // For Object.assign
      ],
      // This option ensures that modern code is not served to legacy browsers
      // and only necessary polyfills are included.
      modernPolyfills: true,
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
    // This defines the lowest ES version that your *output* JS should be compatible with.
    // 'es5' is recommended for maximum compatibility with older TV browsers.
    target: 'es5',
    minify: true, // Ensure code is minified for production
    cssCodeSplit: true, // Split CSS into chunks
    sourcemap: false, // Disable sourcemaps for production builds to reduce size
  }
});
