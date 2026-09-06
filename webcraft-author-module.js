/**
 * Webcraft Goods — Reusable "About Author" Screen & Component
 * Author: Karim | WebCraft Goods
 * Store: https://www.etsy.com/shop/WebCraftGoods
 * Support Email: karimfiverr20@gmail.com
 * 
 * Instructions:
 * 1. Include this file: <script src="webcraft-author-module.js"></script>
 * 2. Add an HTML container: <div id="view-author"></div>
 * 3. Render it: WebcraftAuthorModule.render('view-author');
 * 4. (Optional) Customize author info via window.WebcraftAuthorConfig before calling render().
 */

(function() {
  'use strict';

  // 1. Centralized Admin Configuration (Editable without touching app logic)
  window.WebcraftAuthorConfig = Object.assign({
    authorName: "Karim",
    brandName: "WebCraft Goods",
    authorRole: "Digital Product Designer & SaaS Creator",
    authorBio: "Hi, I'm Karim, the creator behind WebCraft Goods. I design premium digital planners, productivity tools, dashboards, trackers, and web-based templates that help individuals and businesses organize their work, manage their goals, and improve productivity.\n\nMy mission is to create beautiful, practical, and easy-to-use digital products with modern interfaces and powerful features.",
    etsyStoreUrl: "https://www.etsy.com/shop/WebCraftGoods",
    supportEmail: "karimfiverr20@gmail.com",
    avatarUrl: "", // Leave blank to use SVG avatar badge
    brandLogoUrl: "",
    socialLinks: [
      { name: "Etsy Shop", url: "https://www.etsy.com/shop/WebCraftGoods", icon: "shopping-bag" },
      { name: "Pinterest", url: "https://pinterest.com/webcraftgoods", icon: "star" },
      { name: "Instagram", url: "https://instagram.com/webcraftgoods", icon: "heart" },
      { name: "Support Email", url: "mailto:karimfiverr20@gmail.com", icon: "mail" }
    ]
  }, window.WebcraftAuthorConfig || {});

  // 2. Embedded Icon SVG Helpers
  const ICONS = {
    'shopping-bag': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>',
    'external-link': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>',
    'mail': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>',
    'sparkles': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l1.912 5.885L19.798 10.8 13.912 12.715 12 18.6l-1.912-5.885L4.202 10.8l5.886-1.915z"/></svg>',
    'star': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>',
    'heart': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>',
    'copy': '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>'
  };

  function renderSvgIcon(name) {
    return ICONS[name] || '';
  }

  // 3. Module Definition
  window.WebcraftAuthorModule = {
    render: function(containerId = 'view-author') {
      const container = typeof containerId === 'string' ? document.getElementById(containerId) : containerId;
      if (!container) return;

      const cfg = window.WebcraftAuthorConfig;

      container.innerHTML = `
        <div class="author-module-wrap">
          <div class="page-header" style="margin-bottom: 0;">
            <div class="page-title-group">
              <div class="author-banner-badge">
                <span class="nav-icon" data-icon="sparkles">${renderSvgIcon('sparkles')}</span>
                <span>WebCraft Goods Creator Profile</span>
              </div>
              <h1 style="margin-top: 8px;">About Author</h1>
              <p class="page-subtitle">Learn about the creator behind your productivity systems and the vision powering WebCraft Goods.</p>
            </div>
          </div>

          <!-- ABOUT AUTHOR HERO CARD -->
          <section class="author-hero-card" aria-label="Author Profile">
            <div class="author-hero-ambient" aria-hidden="true"></div>

            <div class="author-profile-col">
              <div class="author-avatar-glow">
                <div class="author-avatar-inner">
                  ${cfg.avatarUrl ? `<img src="${cfg.avatarUrl}" alt="${cfg.authorName}" class="author-avatar-img">` : `K`}
                </div>
              </div>

              <div class="author-status-pill">
                <span class="author-status-dot"></span>
                <span>Active Creator & Designer</span>
              </div>

              <h2 class="author-name-h2">${cfg.authorName}</h2>
              <div class="author-brand-title">${cfg.brandName}</div>
              <div class="author-role-sub">${cfg.authorRole}</div>

              <div class="author-cta-stack">
                <a href="${cfg.etsyStoreUrl}" target="_blank" rel="noopener noreferrer" class="btn-etsy-hero" id="author-visit-etsy-btn">
                  <span class="nav-icon" data-icon="shopping-bag">${renderSvgIcon('shopping-bag')}</span>
                  <span>Visit Etsy Store</span>
                  <span class="nav-icon" data-icon="external-link">${renderSvgIcon('external-link')}</span>
                </a>
                <a href="mailto:${cfg.supportEmail}?subject=WebCraft%20Goods%20Customer%20Support" class="btn-author-support" id="author-support-btn">
                  <span class="nav-icon" data-icon="mail">${renderSvgIcon('mail')}</span>
                  <span>Customer Support</span>
                </a>
              </div>
            </div>

            <div class="author-bio-col">
              <div class="author-story-card">
                <div class="author-story-heading">Creator Story & Vision</div>
                <p class="author-story-p">
                  ${cfg.authorBio.replace(/\n\n/g, '</p><p class="author-story-p">')}
                </p>
              </div>

              <div class="brand-pillars-grid">
                <div class="brand-pillar-card">
                  <div class="brand-pillar-icon">💎</div>
                  <h3 class="brand-pillar-title">Meticulous Design</h3>
                  <p class="brand-pillar-desc">Pixel-perfect aesthetics, modern glassmorphism, and intuitive ergonomics crafted for everyday focus.</p>
                </div>
                <div class="brand-pillar-card">
                  <div class="brand-pillar-icon">🔒</div>
                  <h3 class="brand-pillar-title">100% Offline & Private</h3>
                  <p class="brand-pillar-desc">No accounts, no trackers, and zero monthly subscriptions. Your data remains strictly on your device.</p>
                </div>
                <div class="brand-pillar-card">
                  <div class="brand-pillar-icon">🚀</div>
                  <h3 class="brand-pillar-title">Lifetime Evolution</h3>
                  <p class="brand-pillar-desc">Continuous enhancements inspired by real user feedback with seamless backup and restore support.</p>
                </div>
              </div>

              <div class="author-footer-strip">
                <div class="author-social-list">
                  <span style="font-size: 12px; font-weight: 700; color: var(--text-muted); margin-right: 4px;">Connect:</span>
                  ${cfg.socialLinks.map(s => `
                    <a href="${s.url}" target="_blank" rel="noopener noreferrer" class="author-social-pill" title="${s.name}">
                      <span class="nav-icon" data-icon="${s.icon}">${renderSvgIcon(s.icon)}</span>
                      <span>${s.name}</span>
                    </a>
                  `).join('')}
                </div>
                <button type="button" class="author-copy-store-btn" onclick="window.WebcraftAuthorModule.copyStoreUrl()">
                  <span class="nav-icon" data-icon="copy">${renderSvgIcon('copy')}</span>
                  <span>Share Store</span>
                </button>
              </div>
            </div>
          </section>
        </div>
      `;

      if (window.hydrateIcons) window.hydrateIcons(container);
    },

    copyStoreUrl: function() {
      const url = window.WebcraftAuthorConfig.etsyStoreUrl;
      navigator.clipboard.writeText(url).then(() => {
        if (window.ToastService) {
          window.ToastService.show('Etsy store link copied to clipboard!');
        } else {
          alert('Etsy store link copied: ' + url);
        }
      }).catch(() => {
        if (window.ToastService) {
          window.ToastService.show('Etsy store: ' + url);
        }
      });
    },

    init: function(options = {}) {
      if (options.config) {
        window.WebcraftAuthorConfig = Object.assign(window.WebcraftAuthorConfig, options.config);
      }
      const containerId = options.containerId || 'view-author';
      this.render(containerId);
    }
  };
})();
