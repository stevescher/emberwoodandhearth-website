# Disaster Recovery — Emberwood & Hearth Storefront

What to do when the live site is broken. Written after the 2026-09-20 outage,
where a restore from GitHub was attempted, failed, and the site had to be
rebuilt from scratch.

## Read this first: why the GitHub restore failed

It was not a missing backup. The repo had every file. It failed because **a
Shopify theme is not just files**, and pushing an old file tree over a live
theme does not reliably recreate a working site:

- **Theme version mismatch.** The repo was at Tinker `3.5.1`. Pushing those
  files onto a theme running `4.2.0` produces schema mismatches: settings the
  new sections do not recognise, blocks referencing section types that changed
  shape. The site renders broken rather than erroring cleanly.
- **`config/settings_data.json` carries the whole customizer state** and is
  version-coupled to `settings_schema.json`. A stale one silently misconfigures
  every section. The old file was 28,285 bytes against today's 7,653, so the
  shapes were not close.
- **Pushing into the broken theme keeps the breakage.** Each failed attempt
  made the live theme worse and there was nothing clean to compare against.

**The lesson: never restore by pushing files over the live theme.** Always
restore into a *new unpublished theme* and publish it once verified. That gives
a working site in one step, is instantly reversible, and leaves the broken
theme intact for diagnosis.

## Before you touch anything

1. **Do not push. Do not delete the broken theme.** It is evidence, and while
   it is still live the store is at least serving something.
2. **Take a backup of the broken theme.** You will want to diff against it.

```bash
cd ~/claude/emberwood/emberwoodandhearth-website
./scripts/backup-theme.sh 192720699671
```

3. **Work out what is actually broken.** A blank page, a single broken section
   and a checkout failure need different responses. Load the site, open the
   browser console, and look.

## Recovery path A — one file or section is broken

Most incidents. Do not do a full restore.

```bash
mkdir -p /tmp/restore && cd /tmp/restore
unzip ~/claude/emberwood/backups/theme/theme_192720699671_<good-stamp>.zip
diff -rq /tmp/restore ~/claude/emberwood/emberwoodandhearth-website
```

Copy the specific files back into the repo, commit, then deploy with one
`--only` per file (see `/push`). Verify in the browser.

## Recovery path B — the theme is badly broken

**Restore into a new theme. Do not push over the live one.**

```bash
mkdir -p /tmp/restore && cd /tmp/restore
unzip ~/claude/emberwood/backups/theme/theme_192720699671_<good-stamp>.zip

shopify theme push --store emberwoodandhearth.myshopify.com \
  --unpublished --theme "Tinker (restore $(date +%Y%m%d-%H%M))"
```

The command prints the new theme id. **Verify before publishing:**

```
https://emberwoodandhearth.com?preview_theme_id=<new-id>
```

Check the home page, a product page, **both custom picker pages**, and add
something to the cart. Then publish from the Shopify admin (Online Store →
Themes → Actions → Publish).

Publishing is reversible: the previously live theme stays in the theme list
and can be republished in seconds.

## Recovery path C — no usable backup

Only if every archive is missing or broken.

1. Check for other copies before rebuilding: `Tinker (staging)`
   (`192728236311`) and `Tinker (old)` (`187310801175`) are both unpublished
   themes on the store, and either may be closer to working than a rebuild.
2. Check the repo, but **check the theme version first**:

```bash
python3 -c "import json;d=json.load(open('config/settings_schema.json'));print([x.get('theme_version') for x in d if 'theme_version' in x])"
```

If that does not match the theme version you are restoring onto, expect schema
mismatches. Restore the Liquid files but take `config/settings_data.json` from
the live theme, not the repo.

3. Only then consider a rebuild.

## Verification checklist

A restore is not done until all of these pass on the live domain:

- [ ] Home page renders
- [ ] A normal product page renders and adds to cart
- [ ] `/products/candle-flight` shows the scent picker, and a 2-scent selection
      adds tray + 2 candles at **$105.00**
- [ ] `/products/sampler-pack` gates until 5 scents, then adds at **$15.00**
      with all 5 recorded as line item properties
- [ ] `/pages/ember-returns` renders
- [ ] Cart drawer opens and shows correct totals
- [ ] Checkout button reaches Shopify checkout

## What backups exist

| What | Where | Cadence |
|---|---|---|
| Theme zips + manifests | `~/claude/emberwood/backups/theme/` | daily 06:30 via cron, last 30 kept |
| Theme source | GitHub `stevescher/emberwoodandhearth-website` | every push |
| Pre-rebuild source | branch `pre-rebuild-source` | frozen |
| Staging theme | Shopify theme `192728236311` | manual |

Run `./scripts/backup-theme.sh` by hand before any risky change.

## What backups do NOT cover

Restoring the theme does **not** restore these. They live in Shopify and are
configured in the admin:

- Products, variants, inventory, images
- **Automatic discounts** (the Candle Flight pricing depends entirely on these)
- Orders, customers, navigation menus, payment and shipping settings
- Apps and their embedded blocks

If discounts are ever lost, the flights silently sell at full price with no
visible error. See `candle-flight-and-sampler-flows` in memory for the rules
and expected totals.

## Drill

Test this twice a year, because an untested DR plan is a hope, not a plan:

1. Push a recent backup as a new unpublished theme.
2. Preview it and run the verification checklist.
3. Delete the test theme. Do not publish it.

Last drill: **2026-09-20** (restore verified from archive, byte-identical to
repo; not published).
