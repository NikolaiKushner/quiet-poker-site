/** The App Store listing, once the app is live there.
 *
 * Null until it is. The hero says the app is coming rather than rendering a
 * button that 404s, and every "Download" affordance on the site keys off this
 * one value — so launch day is a single line here, not a hunt through pages.
 *
 * The products themselves already exist in App Store Connect; what is missing
 * is the listing people can open. */
export const appStoreUrl: string | null = null;

/** The app's numeric Apple ID. With it set, iOS Safari shows the Smart App
 * Banner — the strip at the top of the page offering to open the App Store —
 * which is the highest-converting thing a marketing page can do on a phone. */
export const appStoreId: string | null = null;

export const supportEmail = 'support@quietpoker.app';

/** Apple's standard EULA, which is the Terms of Use for this app. */
export const appleEulaUrl =
  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/** What the site is about, in the words people search for. Kept in one place
 * so the pages, the structured data and the repository description cannot
 * drift apart. */
export const siteName = 'Quiet Poker';
export const tagline = "Texas Hold'em practice for iPhone";
