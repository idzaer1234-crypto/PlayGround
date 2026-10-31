#!/usr/bin/env bash
# Build the static preview into PROJECT_DIR/dist and serve it in the foreground.
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$PROJECT_DIR"

PORT="${PORT:-3000}"
DIST_DIR="$PROJECT_DIR/dist"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || printf 'unknown')"

# Every meaningful step is timed on stderr, which the controller captures in app.log.
t() { /usr/bin/time -p "$@"; }

t mkdir -p "$DIST_DIR"

# Install and build only when this really is a package project.
HAS_PACKAGE_BUILD=0
if [ -f package.json ]; then
  if [ -f package-lock.json ]; then
    t npm ci --no-audit --no-fund
  else
    t npm install --no-audit --no-fund
  fi
  if t node -e 'const p=require("./package.json");process.exit(p.scripts&&p.scripts.build?0:1)'; then
    t npm run build
    HAS_PACKAGE_BUILD=1
  fi
fi

if [ "$HAS_PACKAGE_BUILD" -eq 0 ]; then
  # This repository has no application source yet, so the build step emits a
  # self-contained workspace page. It has no external requests or dependencies.
  t cat > "$DIST_DIR/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#080b16">
<title>PlayGround — static preview</title>
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%237c5cff'/%3E%3Cpath d='M18 42 32 18l14 24Z' fill='%23fff'/%3E%3C/svg%3E">
<style>
  :root {
    color-scheme: dark;
    --bg: #080b16;
    --panel: rgba(20, 26, 48, .72);
    --line: rgba(151, 164, 214, .18);
    --text: #eef1ff;
    --muted: #a7afce;
    --accent: #8b7bff;
    --accent-2: #3dd6c4;
    --warm: #ffb86b;
  }
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; }
  body {
    margin: 0;
    min-height: 100dvh;
    background: var(--bg);
    color: var(--text);
    font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.55;
    overflow-x: hidden;
    padding-bottom: max(24px, env(safe-area-inset-bottom));
  }
  .aurora {
    position: fixed;
    inset: -20vmax;
    z-index: -2;
    background:
      radial-gradient(42vmax 42vmax at 18% 8%, rgba(124, 92, 255, .32), transparent 62%),
      radial-gradient(38vmax 38vmax at 86% 22%, rgba(61, 214, 196, .20), transparent 64%),
      radial-gradient(34vmax 34vmax at 58% 96%, rgba(255, 184, 107, .14), transparent 66%);
    filter: blur(12px);
    animation: drift 22s ease-in-out infinite alternate;
  }
  .aurora::after {
    content: "";
    position: absolute;
    inset: 0;
    background-image: linear-gradient(rgba(255,255,255,.035) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.035) 1px, transparent 1px);
    background-size: 64px 64px;
    mask-image: radial-gradient(60% 55% at 50% 42%, #000 30%, transparent 100%);
  }
  @keyframes drift { from { transform: translate3d(-2%, -1%, 0) scale(1); } to { transform: translate3d(2%, 2%, 0) scale(1.06); } }
  .wrap { width: min(1080px, calc(100% - 40px)); margin-inline: auto; }
  .topbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding-top: max(22px, env(safe-area-inset-top));
    padding-bottom: 22px;
  }
  .brand {
    display: inline-flex;
    align-items: center;
    gap: 11px;
    color: var(--text);
    text-decoration: none;
    font-weight: 700;
    letter-spacing: -.01em;
  }
  .mark {
    width: 34px; height: 34px;
    display: grid; place-items: center;
    border-radius: 11px;
    background: linear-gradient(140deg, var(--accent), #5a44d8 60%, #2f8d8a);
    box-shadow: 0 8px 24px rgba(124, 92, 255, .35);
  }
  .mark svg { width: 18px; height: 18px; }
  .pill {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 7px 12px;
    border: 1px solid var(--line);
    border-radius: 999px;
    background: rgba(13, 18, 36, .66);
    color: var(--muted);
    font-size: 12px;
    font-weight: 600;
    letter-spacing: .08em;
    text-transform: uppercase;
    white-space: nowrap;
  }
  .dot {
    width: 7px; height: 7px; border-radius: 50%;
    background: var(--accent-2);
    box-shadow: 0 0 0 4px rgba(61, 214, 196, .14);
  }
  .hero { padding: clamp(28px, 6vw, 64px) 0 clamp(26px, 4vw, 40px); }
  .eyebrow {
    margin: 0 0 14px;
    color: var(--accent-2);
    font-size: 12px;
    font-weight: 700;
    letter-spacing: .18em;
    text-transform: uppercase;
  }
  h1 {
    margin: 0;
    max-width: 15ch;
    font-size: clamp(42px, 8.6vw, 84px);
    line-height: .98;
    letter-spacing: -.045em;
    font-weight: 800;
  }
  h1 span {
    background: linear-gradient(100deg, #c5bcff 4%, #8b7bff 38%, #3dd6c4 92%);
    -webkit-background-clip: text;
    background-clip: text;
    color: transparent;
  }
  .lede {
    max-width: 62ch;
    margin: 22px 0 0;
    color: var(--muted);
    font-size: clamp(15px, 2.2vw, 18px);
  }
  code {
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    font-size: .92em;
    color: #d7d2ff;
    background: rgba(124, 92, 255, .12);
    border: 1px solid rgba(124, 92, 255, .18);
    border-radius: 6px;
    padding: 1px 6px;
  }
  .statusrow {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px 18px;
    margin-top: 24px;
    font-size: 13px;
    color: var(--muted);
  }
  .status {
    display: inline-flex;
    align-items: center;
    gap: 9px;
    padding: 7px 12px;
    border-radius: 999px;
    border: 1px solid var(--line);
    background: rgba(13, 18, 36, .6);
    color: #d7dcf5;
    font-weight: 600;
  }
  .status .dot { background: var(--warm); box-shadow: 0 0 0 4px rgba(255, 184, 107, .12); }
  .status.ready .dot { background: var(--accent-2); box-shadow: 0 0 0 4px rgba(61, 214, 196, .14); }
  .actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 30px; }
  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-height: 46px;
    padding: 0 19px;
    border-radius: 12px;
    border: 1px solid var(--line);
    background: rgba(18, 24, 45, .72);
    color: var(--text);
    text-decoration: none;
    font-weight: 650;
    font-size: 14px;
    transition: transform .18s ease, border-color .18s ease, background .18s ease;
  }
  .btn:hover { transform: translateY(-2px); border-color: rgba(139, 123, 255, .55); }
  .btn.primary {
    background: linear-gradient(120deg, #8b7bff, #6f5ae8);
    border-color: transparent;
    color: #fff;
    box-shadow: 0 12px 30px rgba(111, 90, 232, .32);
  }
  .stage {
    position: relative;
    margin: 10px 0 28px;
    height: clamp(220px, 30vw, 340px);
    border: 1px solid var(--line);
    border-radius: 22px;
    overflow: hidden;
    background:
      radial-gradient(70% 120% at 50% 0%, rgba(124, 92, 255, .16), transparent 60%),
      rgba(11, 15, 30, .7);
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, .05), 0 30px 80px rgba(0, 0, 0, .35);
  }
  .stage canvas { display: block; width: 100%; height: 100%; }
  .stage-label {
    position: absolute;
    right: 14px;
    bottom: 12px;
    display: inline-flex;
    gap: 8px;
    align-items: center;
    padding: 6px 10px;
    border-radius: 8px;
    background: rgba(8, 11, 22, .7);
    border: 1px solid var(--line);
    color: var(--muted);
    font: 600 11px/1 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    letter-spacing: .04em;
    text-transform: uppercase;
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
    margin-top: 14px;
  }
  .card {
    position: relative;
    padding: 20px;
    border-radius: 18px;
    border: 1px solid var(--line);
    background: linear-gradient(180deg, rgba(24, 31, 56, .78), rgba(13, 18, 34, .72));
    overflow: hidden;
  }
  .card::before {
    content: "";
    position: absolute;
    inset: 0 auto auto 0;
    width: 100%; height: 1px;
    background: linear-gradient(90deg, transparent, rgba(139, 123, 255, .55), transparent);
  }
  .card h2 {
    margin: 0 0 8px;
    font-size: 13px;
    font-weight: 700;
    color: var(--accent-2);
    letter-spacing: .12em;
    text-transform: uppercase;
  }
  .card p { margin: 0; color: var(--muted); font-size: 14px; }
  .card strong { color: var(--text); font-weight: 650; }
  .skills { margin: 34px 0 10px; }
  .skills h3 {
    margin: 0 0 14px;
    font-size: 12px;
    letter-spacing: .16em;
    text-transform: uppercase;
    color: var(--muted);
    font-weight: 700;
  }
  .chips { display: flex; flex-wrap: wrap; gap: 9px; }
  .chip {
    padding: 8px 12px;
    border-radius: 999px;
    border: 1px solid var(--line);
    background: rgba(16, 22, 42, .68);
    color: #d9def4;
    font-size: 13px;
    font-weight: 550;
  }
  footer {
    display: flex;
    flex-wrap: wrap;
    gap: 8px 20px;
    justify-content: space-between;
    margin-top: 42px;
    padding-top: 20px;
    border-top: 1px solid var(--line);
    color: #7f88a8;
    font-size: 12px;
  }
  footer code { border: 0; background: none; padding: 0; color: #a9b1cf; }
  @media (max-width: 760px) {
    .wrap { width: min(100% - 28px, 620px); }
    .grid { grid-template-columns: 1fr; }
    .stage { height: 240px; border-radius: 18px; }
    h1 { max-width: 12ch; }
    .topbar { padding-top: max(16px, env(safe-area-inset-top)); }
    .actions .btn { flex: 1 1 160px; }
    footer { margin-top: 30px; }
  }
  @media (prefers-reduced-motion: reduce) {
    .aurora { animation: none; }
    html { scroll-behavior: auto; }
    .btn { transition: none; }
  }
</style>
</head>
<body>
<div class="aurora" aria-hidden="true"></div>

<header class="wrap topbar">
  <a class="brand" href="#top" aria-label="PlayGround home">
    <span class="mark" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none"><path d="M5 18 12 5l7 13H5Z" stroke="white" stroke-width="2.2" stroke-linejoin="round"/></svg>
    </span>
    PlayGround
  </a>
  <span class="pill"><span class="dot"></span> static preview</span>
</header>

<main id="top" class="wrap">
  <section class="hero">
    <p class="eyebrow">OMGithub workspace</p>
    <h1>Built, served,<br><span>and captured.</span></h1>
    <p class="lede">
      This preview is generated by <code>start.sh</code>, served from <code>dist/</code> on port
      <strong>__PORT__</strong>, and verified at desktop and mobile sizes by <code>capture.sh</code>.
      No external assets, fonts, or network calls are required.
    </p>
    <div class="statusrow">
      <span class="status" id="render-status"><span class="dot"></span> renderer pending</span>
      <span>commit <code>__COMMIT__</code></span>
      <span id="viewport">viewport —</span>
    </div>
    <div class="actions">
      <a class="btn primary" href="https://omgithub.com/idzaer1234-crypto/PlayGround">Open project</a>
      <a class="btn" href="https://github.com/idzaer1234-crypto/PlayGround">View source</a>
    </div>
  </section>

  <section class="stage" aria-label="Animated canvas renderer check">
    <canvas id="orbit"></canvas>
    <div class="stage-label">canvas <span id="fps">—</span></div>
  </section>

  <section class="grid">
    <article class="card">
      <h2>Build</h2>
      <p>A dependency-free static page is written to <strong>dist/index.html</strong> on every start. Package projects run their own install and build first.</p>
    </article>
    <article class="card">
      <h2>Serve</h2>
      <p>A foreground HTTP server binds <strong>0.0.0.0:__PORT__</strong> and serves only the built directory, so source files never leak into the preview.</p>
    </article>
    <article class="card">
      <h2>Capture</h2>
      <p>Screenshots are written outside the source tree as <strong>final-desktop.png</strong> and <strong>final-mobile.png</strong> for visual verification.</p>
    </article>
  </section>

  <section class="skills">
    <h3>Skills available in this workspace</h3>
    <div class="chips">
      <span class="chip">gauntlet-loop</span>
      <span class="chip">image-search</span>
      <span class="chip">load-sketchfab-threejs</span>
      <span class="chip">mcp-duckgo</span>
      <span class="chip">opencode-zen-completions</span>
    </div>
  </section>
</main>

<footer class="wrap">
  <span>Built <code>__STAMP__</code></span>
  <span>Static build · <code>dist/</code> · port <code>__PORT__</code></span>
</footer>

<script>
(() => {
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const status = document.getElementById('render-status');
  const viewport = document.getElementById('viewport');
  const fpsLabel = document.getElementById('fps');
  const canvas = document.getElementById('orbit');
  const ctx = canvas.getContext('2d', { alpha: true });

  function showViewport() {
    viewport.textContent = `viewport ${innerWidth} × ${innerHeight}`;
  }
  showViewport();
  addEventListener('resize', showViewport);

  let width = 0, height = 0, dpr = 1;
  function resize() {
    const rect = canvas.getBoundingClientRect();
    dpr = Math.min(devicePixelRatio || 1, 2);
    width = rect.width;
    height = rect.height;
    canvas.width = Math.max(1, Math.round(width * dpr));
    canvas.height = Math.max(1, Math.round(height * dpr));
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  new ResizeObserver(resize).observe(canvas);
  resize();

  const palette = ['#8b7bff', '#3dd6c4', '#ffb86b', '#c5bcff', '#5a8dff'];
  const nodes = Array.from({ length: 26 }, (_, i) => ({
    angle: (i / 26) * Math.PI * 2,
    radius: 0.12 + ((i * 37) % 30) / 100,
    speed: 0.00006 + ((i * 13) % 7) * 0.00001,
    size: 1.6 + ((i * 17) % 5) * 0.7,
    color: palette[i % palette.length]
  }));

  const started = performance.now();
  let frames = 0;
  let fpsWindow = started;

  function frame(now) {
    const t = now - started;
    ctx.clearRect(0, 0, width, height);

    const cx = width * 0.5;
    const cy = height * 0.52;
    const base = Math.min(width, height);

    // Concentric guide rings.
    for (let i = 1; i <= 3; i++) {
      ctx.beginPath();
      ctx.arc(cx, cy, base * (0.14 * i), 0, Math.PI * 2);
      ctx.strokeStyle = `rgba(151, 164, 214, ${0.16 - i * 0.03})`;
      ctx.lineWidth = 1;
      ctx.stroke();
    }

    // Soft core.
    const core = ctx.createRadialGradient(cx, cy, 0, cx, cy, base * 0.24);
    core.addColorStop(0, 'rgba(139, 123, 255, .42)');
    core.addColorStop(0.55, 'rgba(90, 70, 210, .12)');
    core.addColorStop(1, 'rgba(8, 11, 22, 0)');
    ctx.fillStyle = core;
    ctx.beginPath();
    ctx.arc(cx, cy, base * 0.24, 0, Math.PI * 2);
    ctx.fill();

    for (const node of nodes) {
      const a = node.angle + (reduceMotion ? 0 : t * node.speed);
      const r = base * node.radius;
      const x = cx + Math.cos(a) * r;
      const y = cy + Math.sin(a) * r * 0.62;

      ctx.beginPath();
      ctx.arc(x, y, node.size, 0, Math.PI * 2);
      ctx.fillStyle = node.color;
      ctx.globalAlpha = 0.85;
      ctx.fill();
      ctx.globalAlpha = 1;

      if (node.size > 2.6) {
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(x, y);
        ctx.strokeStyle = `${node.color}22`;
        ctx.lineWidth = 1;
        ctx.stroke();
      }
    }

    // Sweeping orbit.
    const sweep = (reduceMotion ? 0.7 : (t * 0.00035) % (Math.PI * 2));
    const sx = cx + Math.cos(sweep) * base * 0.36;
    const sy = cy + Math.sin(sweep) * base * 0.36 * 0.62;
    ctx.beginPath();
    ctx.arc(sx, sy, 4.5, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(sx, sy, 11, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255, 255, 255, .22)';
    ctx.stroke();

    frames++;
    if (now - fpsWindow > 500) {
      fpsLabel.textContent = `${Math.round(frames * 1000 / (now - fpsWindow))} fps`;
      frames = 0;
      fpsWindow = now;
    }

    if (!status.classList.contains('ready')) {
      status.classList.add('ready');
      status.lastChild.textContent = ' renderer active';
    }

    if (!reduceMotion) requestAnimationFrame(frame);
  }

  requestAnimationFrame(frame);
  if (reduceMotion) setTimeout(() => frame(performance.now()), 50);
})();
</script>
</body>
</html>
HTML

  t sed -i \
    -e "s|__STAMP__|$STAMP|g" \
    -e "s|__COMMIT__|$COMMIT|g" \
    -e "s|__PORT__|$PORT|g" \
    "$DIST_DIR/index.html"
fi

[ -f "$DIST_DIR/index.html" ] || { echo "Build did not produce dist/index.html." >&2; exit 1; }

# Record the absolute build output for the controller. Metadata lives in OPENCODE_WEB_DIR.
if [ -n "${OPENCODE_WEB_DIR:-}" ]; then
  t env PROJECT_DIR="$PROJECT_DIR" DIST_DIR="$DIST_DIR" OPENCODE_WEB_DIR="$OPENCODE_WEB_DIR" node -e '
    const fs = require("fs"), path = require("path")
    const output = path.join(process.env.OPENCODE_WEB_DIR, "deployment-output.json")
    fs.mkdirSync(path.dirname(output), { recursive: true })
    const temporary = output + ".tmp"
    fs.writeFileSync(temporary, JSON.stringify({
      project: process.env.PROJECT_DIR,
      directory: process.env.DIST_DIR
    }, null, 2) + "\n")
    fs.renameSync(temporary, output)
  '
fi

echo "Serving $DIST_DIR on 0.0.0.0:$PORT"
t python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$DIST_DIR"
