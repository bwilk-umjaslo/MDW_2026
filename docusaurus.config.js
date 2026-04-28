// @ts-check

const config = {
  title: 'MDW 2026 - materiały do recenzji',
  tagline: 'Roboczy zestaw treści dla Międzynarodowych Dni Wina w Jaśle',

  url: 'https://bwilk-umjaslo.github.io',
  baseUrl: '/MDW_2026/',

  organizationName: 'Bartłomiej Wilk',
  projectName: 'MDW_2026',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'pl',
    locales: ['pl'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      },
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'MDW 2026',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'mdwSidebar',
          position: 'left',
          label: 'Dokumentacja',
        },
      ],
    },
    footer: {
      style: 'light',
      copyright: `MDW 2026 - materiały robocze do recenzji.`,
    },
  },
};

module.exports = config;
