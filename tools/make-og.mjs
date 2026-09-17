// Regenerates public/og.png, the image social platforms show for a link.
//
//   node tools/make-og.mjs
//
// Run by hand and committed, not built: it changes about as often as the
// wordmark does, and the alternative is rendering the same bytes on every CI
// run forever. PNG rather than SVG because the platforms that show it do not
// render SVG.
import { writeFileSync } from 'node:fs';
import sharp from 'sharp';

const W = 1200;
const H = 630;

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
  <rect width="${W}" height="${H}" fill="#0B0D10"/>
  <g transform="translate(96 156) scale(2.0)">
    <circle cx="32" cy="32" r="31" fill="#000000" stroke="#FFFFFF" stroke-opacity="0.28" stroke-width="1.5"/>
    <g fill="#FFFFFF">
      ${[0, 45, 90, 135, 180, 225, 270, 315]
        .map(
          (a) =>
            `<rect x="29.4" y="1.6" width="5.2" height="7.4" rx="1.6" transform="rotate(${a} 32 32)"/>`
        )
        .join('\n      ')}
    </g>
    <circle cx="32" cy="32" r="22" fill="none" stroke="#FFFFFF" stroke-width="1.6"/>
    <g fill="#FFFFFF">
      <circle cx="32" cy="27.4" r="4.6"/>
      <circle cx="27.1" cy="35.2" r="4.6"/>
      <circle cx="36.9" cy="35.2" r="4.6"/>
      <path d="M30.1 33.6 Q31.1 40.4 27.4 44.6 L36.6 44.6 Q32.9 40.4 33.9 33.6 Z"/>
    </g>
  </g>
  <text x="96" y="404" fill="#F2F4F7" font-family="Helvetica, Arial, sans-serif"
        font-size="86" font-weight="600" letter-spacing="-2">Quiet Poker</text>
  <text x="96" y="468" fill="#8B93A1" font-family="Helvetica, Arial, sans-serif"
        font-size="34">Calm Texas Hold&#8217;em practice. Play chips only.</text>
</svg>`;

const png = await sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toBuffer();
writeFileSync(new URL('../public/og.png', import.meta.url), png);
console.log(`public/og.png — ${W}x${H}, ${(png.length / 1024).toFixed(0)} kB`);
