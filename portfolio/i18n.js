const I18N = {
  es: {
    'html.lang': 'es',
    'meta.title': 'Constant Product AMM · Token Swap — Rolando Strahm',
    'meta.description':
      'AMM x·y=k con fee 0.3%, TWAP, optimización de gas y auditoría SWC. Foundry · Solidity 0.8.24 · Next.js demo.',

    'nav.overview': 'Proyecto',
    'nav.pillars': 'Pilares',
    'nav.gas': 'Gas',
    'nav.swc': 'SWC',
    'nav.process': 'Proceso',
    'nav.attacks': 'Ataques',
    'nav.repos': 'Repos',
    'nav.close': '← Cerrar',

    'hero.tag': '// MÓDULO 06 · PORTFOLIO WEB3',
    'hero.title': 'CONSTANT PRODUCT<br>AMM · TOKEN SWAP',
    'hero.role': 'Solidity 0.8.24 · Foundry · Gas · SWC · Next.js',
    'hero.sub':
      'AMM de producto constante (x · y = k) con fee 0.3%, liquidez LP, oráculo TWAP, optimización de gas documentada y verificación defensiva SWC — más demo UI en Next.js.',
    'hero.cta1': 'Ver en GitHub',
    'hero.cta2': 'Ver en GitLab',

    'ov.eyebrow': '// 01 — CONTEXTO',
    'ov.title': 'Por qué este proyecto',
    'ov.lead':
      'Dentro de mi suite EVM, el módulo 06 reconstruye un <strong>AMM estilo Uniswap V2</strong> desde cero: Pair, Factory y Router con Foundry. No es un fork: es material de referencia con <strong>K-check</strong>, <strong>gas</strong> y <strong>auditoría SWC</strong> — las capas que más me importan en DeFi on-chain.',

    'pi.eyebrow': '// 02 — TRES PILARES',
    'pi.title': 'Qué entrega el módulo',
    'p1.num': '// PILAR_01',
    'p1.title': 'AMM x · y = k',
    'p1.desc':
      'TokenSwapPair, Factory y Router: swaps con fee 0.3%, mint/burn de LP (Math.sqrt) y acumuladores TWAP en _update().',
    'p1.l1': 'K-check post-swap (997/1000)',
    'p1.l2': 'Slippage + deadline en Router',
    'p1.l3': 'Custom errors · CEI · nonReentrant',
    'p2.num': '// PILAR_02',
    'p2.title': 'Optimización de gas',
    'p2.desc':
      'SafeTransfer propio, immutables, reservas uint112 empaquetadas, ReentrancyGuard EIP-1153 y unchecked acotado.',
    'p2.l1': 'Snapshot e2e en test/gas/',
    'p2.l2': 'Cache token0_/token1_ en hot path',
    'p2.l3': 'Tradeoffs documentados en GAS-ES.md',
    'p3.num': '// PILAR_03',
    'p3.title': 'Verificación de ataques',
    'p3.desc':
      'Matriz SWC-100–136, fuzz ≥ 1000, invariantes k y suite de reentrancy (SWC-107) donde el ataque debe fallar.',
    'p3.l1': '33 mitigados · 3 informativos · 0 vulnerables',
    'p3.l2': '60 tests verdes (unit/fuzz/invariant/attack/gas)',
    'p3.l3': 'UI Next.js: swap + liquidez + tema',

    'gas.eyebrow': '// 03 — OPTIMIZACIÓN DE GAS',
    'gas.title': 'Hot path barato, tradeoffs claros',
    'gas.lead':
      'Fase 8: baseline en <code>doc/GAS-ES.md</code> y <code>.gas-snapshot</code>. El foco es lecturas baratas en mint/swap/burn, bubble-revert en transfers y guard EIP-1153 — no micro-ahorros ciegos.',
    'gas.th1': 'Optimización',
    'gas.th2': 'Tradeoff / efecto',
    'gas.r1a': 'SafeTransfer (low-level call + bubble-revert)',
    'gas.r1b': 'SWC-104; propaga ReentrancyGuard; ligero ↑ deploy vs OZ SafeERC20',
    'gas.r2a': 'immutable factory / token0 / token1',
    'gas.r2b': 'Lecturas baratas en cada operación del Pair y Router',
    'gas.r3a': 'Reservas uint112 + uint32 empaquetadas',
    'gas.r3b': '1 slot menos vs dos uint256; patrón Uniswap V2',
    'gas.r4a': 'ReentrancyGuard EIP-1153 (tstore)',
    'gas.r4b': 'Sin SSTORE permanente en el guard de mint/swap/burn',
    'gas.r5a': 'unchecked aritmética acotada + cache token0_/token1_',
    'gas.r5b': 'Menos overhead post-checks; menos lecturas immutable repetidas',
    'gas.r6a': 'skim condicional + constante _K_DENOMINATOR',
    'gas.r6b': 'Omite transfer si no hay excedente; evita recalcular 1000²',
    'gas.r7a': 'Custom errors + path Router fijo (2 tokens)',
    'gas.r7b': 'Reverts compactos; gas e2e predecible sin loops multi-hop',

    'swc.eyebrow': '// 04 — VERIFICACIÓN SWC',
    'swc.title': 'SWC Registry · EIP-1470',
    'swc.lead':
      'Matriz completa <strong>SWC-100 → SWC-136</strong> sobre Pair, Factory y Router. Informe en <code>doc/SWC-AUDIT-ES.md</code>. Conclusión: <strong>0 vulnerabilidades explotables</strong> en el alcance del AMM v1.',
    'swc.s1': 'Mitigados / N/A',
    'swc.s2': 'Informativos (diseño)',
    'swc.s3': 'Vulnerables',
    'swc.th1': 'SWC clave',
    'swc.th2': 'Mitigación en el contrato',
    'swc.r101': 'Overflow: Solidity 0.8.24; producto k en uint256; reservas uint112',
    'swc.r103': 'Floating pragma: pragma solidity 0.8.24 fijo',
    'swc.r104': 'Unchecked call: SafeTransfer + bubble-revert en Pair/Router',
    'swc.r107': 'Reentrancy: CEI + nonReentrant; suite test/attack/',
    'swc.r116': 'Timestamp / TWAP: acumuladores con delta; wrap uint32 documentado',
    'swc.r123': 'Requirements: custom errors + unit / fuzz / invariant / attack',
    'swc.info': 'INFORMATIVO',
    'swc.i1t': 'MEV / sandwich',
    'swc.i1d':
      'Riesgo de mercado en swaps públicos. Mitigación de producto: amountOutMin + deadline en el Router; slippage conservador.',
    'swc.i2t': 'Donación al par',
    'swc.i2d':
      'Tokens enviados sin mint desalinean balances vs reservas. Mitigación: MINIMUM_LIQUIDITY, skim/sync e invariante balances ≥ reserves.',

    'pr.eyebrow': '// 05 — PROCESO',
    'pr.title': 'Fases 0–8 + UI',
    'pr.lead':
      'Entrega por gates: bootstrap, Pair core, Factory/Router, fuzz/invariantes, attack suite, gas/NatSpec y demo Next.js.',
    'ph.0': 'Bootstrap + Pair mint/swap/burn',
    'ph.12': 'TWAP + Factory + Router',
    'ph.34': 'Unit + fuzz + invariant + SWC',
    'ph.56': 'Gas · SafeTransfer · NatSpec',
    'ph.78': 'Next.js swap / LP / tema',
    'st.1': 'Fases',
    'st.2': 'Tests',
    'st.3': 'SWC críticos',
    'st.4': 'Attack paths',
    'term.label': 'rolando@strahm:~/06-token-swap',
    'term.1': 'forge test',
    'term.2': '[PASS] suite · 60 passed',
    'term.3': 'cat doc/SWC-AUDIT-ES.md | head',
    'term.4': 'Vulnerable: 0 · Informativos: 3 · Mitigados/N/A: 33',
    'term.5': 'echo status',
    'term.6': 'MODULE_06_CLOSED · AMM_UI_CLOSED',

    'at.eyebrow': '// 06 — CAMPAÑAS DE ATAQUE',
    'at.title': 'Defensivo, no ofensivo',
    'at.lead':
      'Suites Foundry donde el “ataque” solo cuenta si revierte. Sin PoCs de exploit: reentrancy en mint/swap/burn, slippage, invariante k y superficie vacía (sin ETH / selfdestruct).',
    'cA.t': 'Reentrancy',
    'cA.d': 'SWC-107: reenter mint/swap/burn durante callback de token.',
    'cB.t': 'K / fee',
    'cB.d': 'Fuzz e invariante: k no baja tras swap con fee 0.3%.',
    'cC.t': 'Slippage',
    'cC.d': 'Router revierte si amountOut < amountOutMin.',
    'cD.t': 'SafeTransfer',
    'cD.d': 'Transfer fallida o false → revert completa (SWC-104).',
    'cE.t': 'N/A',
    'cE.d': 'Sin ETH, selfdestruct, delegatecall ni flash swaps.',

    're.eyebrow': '// 07 — CÓDIGO ABIERTO',
    're.title': 'Repositorios',
    're.lead':
      'El mismo código está en GitHub y GitLab: contratos, tests, gas, SWC, deploy Anvil y frontend Next.js.',
    're.cta': 'Contactar',
    're.linkedin': 'LinkedIn',

    'ft.left': 'ROLANDO STRAHM — Constant Product AMM · Portfolio',
    'ft.right': 'FOUNDRY · SOLC 0.8.24 · ALL_SYSTEMS_OPERATIONAL',
  },

  en: {
    'html.lang': 'en',
    'meta.title': 'Constant Product AMM · Token Swap — Rolando Strahm',
    'meta.description':
      'Constant-product AMM (x·y=k) with 0.3% fee, TWAP, gas optimization, and SWC audit. Foundry · Solidity 0.8.24 · Next.js demo.',

    'nav.overview': 'Project',
    'nav.pillars': 'Pillars',
    'nav.gas': 'Gas',
    'nav.swc': 'SWC',
    'nav.process': 'Process',
    'nav.attacks': 'Attacks',
    'nav.repos': 'Repos',
    'nav.close': '← Close',

    'hero.tag': '// MODULE 06 · WEB3 PORTFOLIO',
    'hero.title': 'CONSTANT PRODUCT<br>AMM · TOKEN SWAP',
    'hero.role': 'Solidity 0.8.24 · Foundry · Gas · SWC · Next.js',
    'hero.sub':
      'Constant-product AMM (x · y = k) with 0.3% fee, LP liquidity, TWAP oracle, documented gas optimizations, and defensive SWC verification — plus a Next.js demo UI.',
    'hero.cta1': 'View on GitHub',
    'hero.cta2': 'View on GitLab',

    'ov.eyebrow': '// 01 — CONTEXT',
    'ov.title': 'Why this project',
    'ov.lead':
      'In my EVM suite, module 06 rebuilds a <strong>Uniswap V2–style AMM</strong> from scratch: Pair, Factory, and Router with Foundry. Not a fork — reference material with <strong>K-check</strong>, <strong>gas</strong>, and <strong>SWC audit</strong> — the layers I care most about in on-chain DeFi.',

    'pi.eyebrow': '// 02 — THREE PILLARS',
    'pi.title': 'What the module ships',
    'p1.num': '// PILLAR_01',
    'p1.title': 'AMM x · y = k',
    'p1.desc':
      'TokenSwapPair, Factory, and Router: 0.3% fee swaps, LP mint/burn (Math.sqrt), and TWAP accumulators in _update().',
    'p1.l1': 'Post-swap K-check (997/1000)',
    'p1.l2': 'Slippage + deadline on Router',
    'p1.l3': 'Custom errors · CEI · nonReentrant',
    'p2.num': '// PILLAR_02',
    'p2.title': 'Gas optimization',
    'p2.desc':
      'Custom SafeTransfer, immutables, packed uint112 reserves, EIP-1153 ReentrancyGuard, and bounded unchecked math.',
    'p2.l1': 'E2E snapshot in test/gas/',
    'p2.l2': 'token0_/token1_ cache on hot path',
    'p2.l3': 'Tradeoffs documented in GAS-EN.md',
    'p3.num': '// PILLAR_03',
    'p3.title': 'Attack verification',
    'p3.desc':
      'SWC-100–136 matrix, fuzz ≥ 1000, k invariants, and reentrancy suite (SWC-107) where the attack must fail.',
    'p3.l1': '33 mitigated · 3 informational · 0 vulnerable',
    'p3.l2': '60 green tests (unit/fuzz/invariant/attack/gas)',
    'p3.l3': 'Next.js UI: swap + liquidity + theme',

    'gas.eyebrow': '// 03 — GAS OPTIMIZATION',
    'gas.title': 'Cheap hot path, clear tradeoffs',
    'gas.lead':
      'Phase 8: baseline in <code>doc/GAS-EN.md</code> and <code>.gas-snapshot</code>. Focus is cheap reads on mint/swap/burn, bubble-revert transfers, and an EIP-1153 guard — not blind micro-savings.',
    'gas.th1': 'Optimization',
    'gas.th2': 'Tradeoff / effect',
    'gas.r1a': 'SafeTransfer (low-level call + bubble-revert)',
    'gas.r1b': 'SWC-104; preserves ReentrancyGuard; slight ↑ deploy vs OZ SafeERC20',
    'gas.r2a': 'immutable factory / token0 / token1',
    'gas.r2b': 'Cheap reads on every Pair and Router operation',
    'gas.r3a': 'Packed uint112 + uint32 reserves',
    'gas.r3b': 'One fewer slot vs two uint256; Uniswap V2 pattern',
    'gas.r4a': 'EIP-1153 ReentrancyGuard (tstore)',
    'gas.r4b': 'No permanent SSTORE on the mint/swap/burn guard',
    'gas.r5a': 'Bounded unchecked math + token0_/token1_ cache',
    'gas.r5b': 'Less post-check overhead; fewer repeated immutable reads',
    'gas.r6a': 'Conditional skim + _K_DENOMINATOR constant',
    'gas.r6b': 'Skips transfer when no surplus; avoids recomputing 1000²',
    'gas.r7a': 'Custom errors + fixed Router path (2 tokens)',
    'gas.r7b': 'Compact reverts; predictable e2e gas without multi-hop loops',

    'swc.eyebrow': '// 04 — SWC VERIFICATION',
    'swc.title': 'SWC Registry · EIP-1470',
    'swc.lead':
      'Full matrix <strong>SWC-100 → SWC-136</strong> against Pair, Factory, and Router. Report in <code>doc/SWC-AUDIT-EN.md</code>. Conclusion: <strong>0 exploitable vulnerabilities</strong> in AMM v1 scope.',
    'swc.s1': 'Mitigated / N/A',
    'swc.s2': 'Informational (design)',
    'swc.s3': 'Vulnerable',
    'swc.th1': 'Key SWC',
    'swc.th2': 'Mitigation in the contracts',
    'swc.r101': 'Overflow: Solidity 0.8.24; k product in uint256; uint112 reserves',
    'swc.r103': 'Floating pragma: fixed pragma solidity 0.8.24',
    'swc.r104': 'Unchecked call: SafeTransfer + bubble-revert in Pair/Router',
    'swc.r107': 'Reentrancy: CEI + nonReentrant; test/attack/ suite',
    'swc.r116': 'Timestamp / TWAP: delta accumulators; documented uint32 wrap',
    'swc.r123': 'Requirements: custom errors + unit / fuzz / invariant / attack',
    'swc.info': 'INFORMATIONAL',
    'swc.i1t': 'MEV / sandwich',
    'swc.i1d':
      'Market risk on public swaps. Product mitigation: amountOutMin + deadline on the Router; conservative slippage.',
    'swc.i2t': 'Pair donation',
    'swc.i2d':
      'Tokens sent without mint skew balances vs reserves. Mitigation: MINIMUM_LIQUIDITY, skim/sync, and balances ≥ reserves invariant.',

    'pr.eyebrow': '// 05 — PROCESS',
    'pr.title': 'Phases 0–8 + UI',
    'pr.lead':
      'Gate-based delivery: bootstrap, Pair core, Factory/Router, fuzz/invariants, attack suite, gas/NatSpec, and Next.js demo.',
    'ph.0': 'Bootstrap + Pair mint/swap/burn',
    'ph.12': 'TWAP + Factory + Router',
    'ph.34': 'Unit + fuzz + invariant + SWC',
    'ph.56': 'Gas · SafeTransfer · NatSpec',
    'ph.78': 'Next.js swap / LP / theme',
    'st.1': 'Phases',
    'st.2': 'Tests',
    'st.3': 'Critical SWC',
    'st.4': 'Attack paths',
    'term.label': 'rolando@strahm:~/06-token-swap',
    'term.1': 'forge test',
    'term.2': '[PASS] suite · 60 passed',
    'term.3': 'cat doc/SWC-AUDIT-EN.md | head',
    'term.4': 'Vulnerable: 0 · Informational: 3 · Mitigated/N/A: 33',
    'term.5': 'echo status',
    'term.6': 'MODULE_06_CLOSED · AMM_UI_CLOSED',

    'at.eyebrow': '// 06 — ATTACK CAMPAIGNS',
    'at.title': 'Defensive, not offensive',
    'at.lead':
      'Foundry suites where an “attack” only counts if it reverts. No exploit PoCs: reentrancy on mint/swap/burn, slippage, k invariant, and empty surface (no ETH / selfdestruct).',
    'cA.t': 'Reentrancy',
    'cA.d': 'SWC-107: reenter mint/swap/burn during token callback.',
    'cB.t': 'K / fee',
    'cB.d': 'Fuzz and invariant: k does not drop after a 0.3% fee swap.',
    'cC.t': 'Slippage',
    'cC.d': 'Router reverts if amountOut < amountOutMin.',
    'cD.t': 'SafeTransfer',
    'cD.d': 'Failed or false transfer → full revert (SWC-104).',
    'cE.t': 'N/A',
    'cE.d': 'No ETH, selfdestruct, delegatecall, or flash swaps.',

    're.eyebrow': '// 07 — OPEN SOURCE',
    're.title': 'Repositories',
    're.lead':
      'The same codebase is on GitHub and GitLab: contracts, tests, gas, SWC, Anvil deploy, and Next.js frontend.',
    're.cta': 'Contact',
    're.linkedin': 'LinkedIn',

    'ft.left': 'ROLANDO STRAHM — Constant Product AMM · Portfolio',
    'ft.right': 'FOUNDRY · SOLC 0.8.24 · ALL_SYSTEMS_OPERATIONAL',
  },
};

function setLanguage(lang) {
  const dict = I18N[lang] || I18N.es;
  document.documentElement.lang = dict['html.lang'];
  document.title = dict['meta.title'];

  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc && dict['meta.description']) {
    metaDesc.setAttribute('content', dict['meta.description']);
  }

  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    const val = dict[key];
    if (val == null) return;
    if (el.hasAttribute('data-i18n-html')) el.innerHTML = val;
    else el.textContent = val;
  });

  document.querySelectorAll('.lang-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.lang === lang);
  });

  localStorage.setItem('token-swap-portfolio-lang', lang);

  const url = new URL(window.location.href);
  url.searchParams.set('lang', lang);
  history.replaceState(null, '', url);
}

function initI18n() {
  const params = new URLSearchParams(window.location.search);
  const fromQuery = params.get('lang');
  const saved = localStorage.getItem('token-swap-portfolio-lang');
  const preferred =
    (fromQuery === 'en' || fromQuery === 'es' ? fromQuery : null) ||
    saved ||
    (navigator.language?.startsWith('en') ? 'en' : 'es');

  setLanguage(preferred);

  document.querySelectorAll('.lang-btn').forEach((btn) => {
    btn.addEventListener('click', () => setLanguage(btn.dataset.lang));
  });
}

document.addEventListener('DOMContentLoaded', initI18n);
