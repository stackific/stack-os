// @ts-check

import starlight from '@astrojs/starlight';
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  integrations: [
    starlight({
      title: 'Stack OS',
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
