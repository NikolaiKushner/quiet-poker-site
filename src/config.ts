/** The App Store listing, once the app is live there.
 *
 * Null until it is. The hero says the app is coming rather than rendering a
 * button that 404s, and every "Download" affordance on the site keys off this
 * one value — so launch day is a single line here, not a hunt through pages. */
export const appStoreUrl: string | null = null;

export const supportEmail = 'support@quietpoker.app';

/** Apple's standard EULA, which is the Terms of Use for this app. */
export const appleEulaUrl =
  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
