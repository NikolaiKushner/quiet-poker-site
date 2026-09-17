// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://quietpoker.app',
  integrations: [sitemap()],
  build: {
    // Caddy's file_server serves /privacy/index.html for /privacy, but the
    // URL in the app binary and in App Store Connect is /privacy with no
    // trailing slash, and the directory form redirects to it. Flat files
    // answer the exact URL instead.
    format: 'file',
  },
});
