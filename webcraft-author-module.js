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
    supportEmail: "webcraftgoods.support@gmail.com",
    avatarUrl: "data:image/jpeg;base64,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", // Leave blank to use SVG avatar badge
    brandLogoUrl: "",
    socialLinks: [
      { name: "Etsy Shop", url: "https://www.etsy.com/shop/WebCraftGoods", icon: "shopping-bag" },
      { name: "Pinterest", url: "https://pinterest.com/webcraftgoods", icon: "star" },
      { name: "Instagram", url: "https://instagram.com/webcraftgoods", icon: "heart" },
      { name: "Support Email", url: "mailto:webcraftgoods.support@gmail.com", icon: "mail" }
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
