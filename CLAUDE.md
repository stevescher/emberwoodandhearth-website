# emberwoodandhearth-website — Shopify theme

> This project follows the rules in `/Users/stevescher/claude/CLAUDE.md` and `/Users/stevescher/claude/emberwood/CLAUDE.md`. Claude Code loads those files automatically for any session in this folder.

## Read the Emberwood Brain before working

**Path:** `/Users/stevescher/Library/Mobile Documents/com~apple~CloudDocs/Emberwood/Emberwood Brain/`

For anything in this repo, read **`08-shopify-and-web-ops.md`** first. It is the canonical record of how the site is built, deployed and recovered, and it carries knowledge that is not derivable from the code: the discount mechanism behind the Candle Flight price, the traps that have already cost hours, and the disaster recovery procedure.

Also read the file that matches the work: `01-products-and-pricing.md` for prices and flights, `06-voice-and-copy.md` for copy, `07-seo-and-blog.md` for SEO, `15-email-and-reviews.md` for reviews. `README.md` in that folder indexes all sixteen.

**Update the Brain in the same session** when work changes something it documents. A Brain entry describing a system that no longer exists sends the next session down a path that cannot work. Full rule in `/Users/stevescher/claude/emberwood/CLAUDE.md`.

## Theme

The live theme is **Tinker (new)** `#192720699671`. The site was rebuilt from scratch on 2026-09-20. Tinker is the only theme to reference; Dawn is gone.

| Theme | ID | Role |
|---|---|---|
| Tinker (new) | `192720699671` | **live** |
| Tinker (staging) | `192728236311` | unpublished, test here first |
| Tinker (old) | `187310801175` | unpublished, pre-rebuild reference only |

Tinker is **blocks-based**: the product page is `sections/product-information.liquid`, composing blocks from `blocks/` via `content_for 'blocks'`. There is no `sections/main-product.liquid`.

## Never run a bare `shopify theme push`

People edit this theme in the Shopify UI. The theme editor writes to `templates/*.json`, `sections/*-group.json` and `config/settings_data.json`. A full push uploads the whole local tree and **overwrites their in-progress work**.

1. Pull live to a scratch directory and `diff -rq` against the repo.
2. Any file that differs and is not yours is their editor work. Copy it in and commit it first.
3. Push only your own files, one `--only` per file, with the explicit theme id.
4. Pull once more and commit. Shopify rewrites template JSON with a generated header on push.
5. Verify by loading the page and using it, not by grepping the HTML.

## Disaster recovery

**Never restore by pushing files over the live theme.** Push the backup as a new unpublished theme, verify in preview, then publish. See `DISASTER-RECOVERY.md` in this repo.

Backups: `./scripts/backup-theme.sh`, daily cron at 06:30, archives in `~/claude/emberwood/backups/theme/`. Run it by hand before any risky change.

## Custom pickers

`blocks/scent-picker.liquid` (Candle Flight) and `blocks/sampler-picker.liquid` (Scent Sampler) are the only real custom JavaScript on the site. Before touching either, read the picker section of `08-shopify-and-web-ops.md` — it documents three traps that have already cost hours, including that a `product`-type block setting hijacks the block's product context and that the DOM does not camel-case a hyphen followed by a digit.

Flight pricing comes from **Shopify automatic discounts**, not theme code. Never rebuild discounting in Liquid.

## Verify in a browser

Testing the Cart API with hand-built payloads proves Shopify accepts the payload, not that the page can produce it. That gap shipped a Candle Flight page that could never add to cart. **Click through the real page before calling a storefront feature done.**

## Linear

No Linear project exists for this repo yet. Ask Steve before creating one.
