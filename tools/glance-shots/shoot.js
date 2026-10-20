// Screenshots each page given, cropped to what was drawn, at 2x for sharp text.
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1366, height: 768 }, deviceScaleFactor: 2 });
  for (const file of process.argv.slice(2)) {
    await page.goto('file://' + file);
    const clip = await page.evaluate(() => window.bounds());
    const out = file.replace(/\.html$/, '.png');
    await page.screenshot({ path: out, clip });
    console.log('saved ' + out);
  }
  await browser.close();
})();
