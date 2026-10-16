// @ts-check

import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  integrations: [
    starlight({
      title: 'Stack OS',
      customCss: ['./src/styles/custom.css'],
      head: [
        // Commit links (each entry's first line) open in a new tab; custom.css
        // draws their GitHub and external-link icons.
        {
          tag: 'script',
          content:
            "document.addEventListener('DOMContentLoaded',()=>document.querySelectorAll('a[href^=\"https://github.com/stackific/stack-os/commit/\"]').forEach(a=>{a.target='_blank';a.rel='noopener noreferrer'}))",
        },
      ],
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/stackific/stack-os',
        },
      ],
      sidebar: [
        {
          label: 'How it was made',
          items: [
            { slug: 'how-it-was-made' },
            {
              label: '1-Minimal desktop',
              items: [
                {
                  autogenerate: {
                    directory: 'how-it-was-made/001-minimal-desktop',
                  },
                },
              ],
            },
          ],
        },
      ],
    }),
  ],
});
