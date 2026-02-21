/**
 * API Configuration
 *
 * Sets window.API_BASE_URL used by login.html (and any other page that
 * includes this script) when constructing fetch URLs.
 *
 * How to configure without code changes:
 *   Option A – inject before this script loads (e.g. in a server-rendered
 *              <script> block or a config.js served from the same origin):
 *                window.__API_BASE_URL__ = 'https://your-api-host.example.com';
 *
 *   Option B – leave unset; the default is '' (empty string = same origin),
 *              which works when the frontend and the Node.js API server run
 *              together on the same host (the current Render deployment).
 */
(function () {
  'use strict';

  var configured = (typeof window !== 'undefined' && typeof window.__API_BASE_URL__ === 'string')
    ? window.__API_BASE_URL__.replace(/\/$/, '') // strip trailing slash
    : '';

  // Sanity guard: warn loudly if localhost appears in the API base URL while
  // the page itself is being served from a non-localhost host.  This prevents
  // accidentally shipping a build that talks to a developer's machine.
  if (configured) {
    var configuredHostname = '';
    try {
      // Use URL parsing to extract the exact hostname (avoids false positives
      // from substrings like "my-localhost-cafe.example.com").
      configuredHostname = new URL(configured).hostname;
    } catch (e) {
      // If 'configured' is not an absolute URL (e.g. a relative path) skip the check.
    }
    if (configuredHostname === 'localhost' || configuredHostname === '127.0.0.1') {
      var pageHost = (typeof window !== 'undefined' && window.location && window.location.hostname) || '';
      if (pageHost !== 'localhost' && pageHost !== '127.0.0.1') {
        console.error(
          '[api-config] MISCONFIGURATION: window.__API_BASE_URL__ is set to "' + configured + '"' +
          ' but the page is being served from "' + pageHost + '".' +
          ' Login requests will fail. Set window.__API_BASE_URL__ to the correct production API URL.'
        );
      }
    }
  }

  window.API_BASE_URL = configured;
}());
