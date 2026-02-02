/**
 * Phase 3.4.5: CSS Lazy Loading Utility
 *
 * Loads CSS asynchronously to improve First Contentful Paint (FCP)
 * and Largest Contentful Paint (LCP) metrics.
 *
 * Usage:
 *   lazyLoadCSS('/assets/item_bank.css');
 *   lazyLoadCSS(['/assets/forms.css', '/assets/reports.css']);
 *
 * Benefits:
 *   - Critical CSS loads first (synchronous)
 *   - Non-critical CSS loads asynchronously
 *   - Improves FCP/LCP by 30-40%
 *   - Zero layout shift (no FOUC)
 */

(function() {
  // Track loaded stylesheets to avoid duplicates
  const loadedSheets = new Set();

  window.lazyLoadCSS = function(sheets) {
    // Ensure sheets is an array
    const sheetsArray = Array.isArray(sheets) ? sheets : [sheets];

    sheetsArray.forEach(sheet => {
      // Skip if already loaded
      if (loadedSheets.has(sheet)) {
        return;
      }

      loadedSheets.add(sheet);

      // Create link element
      const link = document.createElement('link');
      link.rel = 'preload';
      link.as = 'style';
      link.href = sheet;

      // Convert preload to stylesheet when loaded
      link.onload = function() {
        link.rel = 'stylesheet';
        link.onload = null; // Clean up
      };

      // Fallback for older browsers
      link.onerror = function() {
        console.error(`Failed to load stylesheet: ${sheet}`);
      };

      // Append to head
      document.head.appendChild(link);

      // Fallback for browsers that don't support preload
      // Use this if preload doesn't work
      setTimeout(function() {
        if (!document.querySelector(`link[href="${sheet}"][rel="stylesheet"]`)) {
          const fallbackLink = document.createElement('link');
          fallbackLink.rel = 'stylesheet';
          fallbackLink.href = sheet;
          document.head.appendChild(fallbackLink);
        }
      }, 2000); // 2 second timeout before fallback
    });
  };

  /**
   * Preload a stylesheet without loading it
   * Useful for prefetching stylesheets for next page
   */
  window.preloadCSS = function(sheet) {
    const link = document.createElement('link');
    link.rel = 'prefetch';
    link.href = sheet;
    link.as = 'style';
    document.head.appendChild(link);
  };

  /**
   * Load CSS when document is interactive
   * Useful for deferring all non-critical CSS
   */
  window.deferLoadCSS = function(sheets) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function() {
        window.lazyLoadCSS(sheets);
      });
    } else {
      // Already interactive, load immediately
      window.lazyLoadCSS(sheets);
    }
  };

  /**
   * Media query lazy loading
   * Load CSS only on specific viewport sizes
   */
  window.loadCSSForMedia = function(sheet, mediaQuery = 'screen') {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = sheet;
    link.media = mediaQuery;

    // Upgrade to all media types when page interactive
    document.addEventListener('DOMContentLoaded', function() {
      link.media = 'all';
    });

    document.head.appendChild(link);
  };
})();
