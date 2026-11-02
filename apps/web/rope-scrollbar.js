/**
 * Rope Scrollbar — Traveler Climber From Summit to Sea
 * Sleek, Refined Desktop Scale (Width: 36px)
 */

(function () {
  'use strict';

  // ── State ──────────────────────────────────────────────────────────────────
  let container, ropeSvg, ropeClickable, travelerEl, seaEl;
  let currentTravelerY = 8;
  let targetTravelerY = 8;
  let currentPose = 'idle'; // 'idle' | 'climbLeft' | 'climbRight'
  let accumulatedScrollDelta = 0;
  let lastScrollY = window.scrollY;
  let idleTimer = null;
  let isDragging = false;
  let dragStartY = 0;
  let dragStartScroll = 0;
  let idleTime = 0;
  let isReducedMotion = false;

  // ── Initialize Component ───────────────────────────────────────────────────
  function init() {
    if (document.getElementById('ropeScrollbarRoot')) return;

    // Check motion preference
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    isReducedMotion = mediaQuery.matches;
    mediaQuery.addEventListener('change', (e) => {
      isReducedMotion = e.matches;
    });

    createDom();
    updateRopeGeometry();

    // Event Listeners
    window.addEventListener('scroll', onScroll, { passive: true });
    document.addEventListener('scroll', onScroll, { passive: true, capture: true });
    window.addEventListener('resize', onResize, { passive: true });
    window.addEventListener('orientationchange', onResize, { passive: true });

    // Dragging
    travelerEl.addEventListener('mousedown', onDragStart);
    travelerEl.addEventListener('touchstart', onTouchStart, { passive: false });

    // Rope Track Click
    ropeClickable.addEventListener('click', onRopeClick);

    // Physics Animation Loop (60 FPS)
    requestAnimationFrame(physicsLoop);
  }

  // ── DOM Construction ───────────────────────────────────────────────────────
  function createDom() {
    container = document.createElement('div');
    container.id = 'ropeScrollbarRoot';
    container.className = 'rope-scrollbar-container';
    container.setAttribute('role', 'scrollbar');
    container.setAttribute('aria-label', 'Rope scrollbar');
    container.setAttribute('aria-valuenow', '0');

    // 1. Mountain Summit (Top)
    const mountainEl = document.createElement('div');
    mountainEl.className = 'rope-mountain-summit';
    mountainEl.innerHTML = `
      <svg viewBox="0 0 90 112" preserveAspectRatio="none" fill="none" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="mntFade" x1="0" y1="0" x2="0" y2="112" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stop-color="#334155" />
            <stop offset="70%" stop-color="#1E293B" stop-opacity="0.9" />
            <stop offset="100%" stop-color="#0A0E17" stop-opacity="0" />
          </linearGradient>
          <linearGradient id="pegWood" x1="42" y1="6" x2="48" y2="18" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stop-color="#B45309" />
            <stop offset="100%" stop-color="#78350F" />
          </linearGradient>
        </defs>
        <!-- Ridge Shapes -->
        <polygon points="22,38 2,112 48,112" fill="#1E293B" opacity="0.85" />
        <polygon points="22,38 48,112 70,112" fill="#0F172A" opacity="0.85" />
        
        <!-- Main Peak Body -->
        <polygon points="45,14 6,112 45,112" fill="#475569" />
        <polygon points="45,14 45,112 88,112" fill="url(#mntFade)" />

        <!-- Snow Cap -->
        <path d="M45 14 L28 46 L34 44 L40 50 L45 44 L52 50 L58 44 L64 48 L45 14 Z" fill="#F8FAFC" />
        <path d="M45 14 L45 44 L52 50 L58 44 L64 48 L45 14 Z" fill="#E2E8F0" />

        <!-- Wooden Summit Peg -->
        <rect x="42.5" y="8" width="5" height="12" rx="2" fill="url(#pegWood)" stroke="#451A03" stroke-width="1.2" />

        <!-- Rope Looped Twice Around Peg -->
        <ellipse cx="45" cy="12" rx="5" ry="2.2" fill="none" stroke="#D4A346" stroke-width="2.6" />
        <ellipse cx="45" cy="15" rx="5" ry="2.2" fill="none" stroke="#C29B38" stroke-width="2.6" />
        <circle cx="45" cy="17" r="2.8" fill="#B4832C" stroke="#785318" stroke-width="0.8" />
      </svg>
    `;
    container.appendChild(mountainEl);

    // 2. Rope Track (SVG & Click Target)
    const trackWrap = document.createElement('div');
    trackWrap.className = 'rope-track-wrap';

    ropeSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    ropeSvg.setAttribute('class', 'rope-track-svg');
    ropeSvg.innerHTML = `
      <defs>
        <pattern id="ropeTwistPattern" width="6" height="10" patternUnits="userSpaceOnUse">
          <rect width="6" height="10" fill="#C29B38" />
          <line x1="0" y1="0" x2="6" y2="5" stroke="#E0B85C" stroke-width="2.2" />
          <line x1="0" y1="5" x2="6" y2="10" stroke="#D4A346" stroke-width="2.2" />
          <line x1="0" y1="1" x2="6" y2="6" stroke="#8A5A16" stroke-width="0.9" opacity="0.85" />
          <line x1="0" y1="6" x2="6" y2="11" stroke="#8A5A16" stroke-width="0.9" opacity="0.85" />
        </pattern>
      </defs>
      <!-- Rope Main Body (x=15.5, width=5, centered at x=18) -->
      <rect id="ropeTrackRect" x="15.5" y="14" width="5" height="600" rx="2" fill="url(#ropeTwistPattern)" stroke="#8A5A16" stroke-width="0.7" />
      
      <!-- Frayed Untied Bottom Tassels -->
      <g id="ropeFrayedEnd" transform="translate(18, 614)">
        <path d="M-2.5,0 Q-5,7 -7,11 M-1,0 Q-2,8 -3,12 M0,0 Q0.8,9 0,13 M1,0 Q2.5,8 4,12 M2.5,0 Q4.5,7 6,10" 
              stroke="#D4A346" stroke-width="1.3" stroke-linecap="round" fill="none" />
        <path d="M-2,0 Q-3.5,5 -5,9 M0.8,0 Q2,7 3,10" 
              stroke="#E0B85C" stroke-width="0.9" stroke-linecap="round" fill="none" />
      </g>
    `;
    trackWrap.appendChild(ropeSvg);

    ropeClickable = document.createElement('div');
    ropeClickable.className = 'rope-track-clickable';
    ropeClickable.title = 'Click along rope to navigate';
    trackWrap.appendChild(ropeClickable);

    container.appendChild(trackWrap);

    // 3. Traveler Climber Thumb
    travelerEl = document.createElement('div');
    travelerEl.className = 'rope-traveler-climber';
    travelerEl.title = 'Drag traveler to scroll';
    travelerEl.innerHTML = createTravelerSvg();
    container.appendChild(travelerEl);

    // 4. Sea Waves (Bottom)
    seaEl = document.createElement('div');
    seaEl.className = 'rope-sea-bottom';
    seaEl.innerHTML = `
      <svg class="wave-layer wave-back" viewBox="0 0 180 80" preserveAspectRatio="none">
        <path d="M0,32 Q22,24 45,32 T90,32 T135,32 T180,32 L180,80 L0,80 Z" fill="#0284C7" />
      </svg>
      <svg class="wave-layer wave-front" viewBox="0 0 180 80" preserveAspectRatio="none">
        <path d="M0,38 Q22,46 45,38 T90,38 T135,38 T180,38 L180,80 L0,80 Z" fill="#0369A1" />
        <path d="M0,38 Q22,46 45,38 T90,38 T135,38 T180,38" fill="none" stroke="#E0F2FE" stroke-width="2.5" opacity="0.85" />
      </svg>
    `;
    container.appendChild(seaEl);

    document.body.appendChild(container);
  }

  // ── Traveler Vector Graphic (ViewBox 0 0 56 88 scaled to 24x38 px) ─────────
  function createTravelerSvg() {
    return `
      <svg class="rope-traveler-svg" viewBox="0 0 56 88" preserveAspectRatio="xMidYMid meet" fill="none" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="trvSkin" x1="20" y1="18" x2="36" y2="34" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stop-color="#FDE68A" />
            <stop offset="100%" stop-color="#F59E0B" />
          </linearGradient>
          <linearGradient id="trvPack" x1="16" y1="36" x2="40" y2="60" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stop-color="#FB923C" />
            <stop offset="100%" stop-color="#EA580C" />
          </linearGradient>
          <linearGradient id="trvRoll" x1="20" y1="31" x2="36" y2="37" gradientUnits="userSpaceOnUse">
            <stop offset="0%" stop-color="#84CC16" />
            <stop offset="100%" stop-color="#4D7C0F" />
          </linearGradient>
        </defs>

        <!-- BACKPACK (behind body) -->
        <rect x="15" y="38" width="26" height="22" rx="6" fill="url(#trvPack)" stroke="#7C2D12" stroke-width="1.4" />
        <!-- Top Bedroll -->
        <rect x="17" y="32" width="22" height="7" rx="3.5" fill="url(#trvRoll)" stroke="#365314" stroke-width="1.2" />
        <line x1="22" y1="32" x2="22" y2="39" stroke="#1F2937" stroke-width="1.2" />
        <line x1="34" y1="32" x2="34" y2="39" stroke="#1F2937" stroke-width="1.2" />

        <!-- ── POSE: IDLE ── -->
        <g id="poseIdle">
          <rect x="21" y="60" width="6.5" height="17" rx="3" fill="#78350F" stroke="#451A03" stroke-width="1.2" />
          <rect x="28.5" y="60" width="6.5" height="17" rx="3" fill="#78350F" stroke="#451A03" stroke-width="1.2" />
          <path d="M19 75 H27.5 V79 C27.5 80.5 26 81.5 24 81.5 H19 V75 Z" fill="#3B1C0A" stroke="#1A0D04" stroke-width="1.2" />
          <path d="M28.5 75 H37 V79 C37 80.5 35.5 81.5 33.5 81.5 H28.5 V75 Z" fill="#3B1C0A" stroke="#1A0D04" stroke-width="1.2" />

          <path d="M18 42 Q14 48 24 48" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" />
          <path d="M38 42 Q42 48 32 48" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" />
          <circle cx="25" cy="48" r="3.2" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1" />
          <circle cx="31" cy="48" r="3.2" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1" />
        </g>

        <!-- ── POSE: CLIMB LEFT ── -->
        <g id="poseClimbLeft" style="display: none;">
          <rect x="20" y="60" width="6.5" height="17" rx="3" fill="#78350F" stroke="#451A03" stroke-width="1.2" />
          <path d="M29 60 L35 55 L38 68 L32 70 Z" fill="#78350F" stroke="#451A03" stroke-width="1.2" />
          <path d="M18 75 H26.5 V79 C26.5 80.5 25 81.5 23 81.5 H18 V75 Z" fill="#3B1C0A" stroke="#1A0D04" stroke-width="1.2" />
          <path d="M32 67 H40.5 V71 C40.5 72.5 39 73.5 37 73.5 H32 V67 Z" fill="#3B1C0A" stroke="#1A0D04" stroke-width="1.2" />

          <path d="M18 42 Q16 28 26 28" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" />
          <path d="M38 42 Q40 50 30 52" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" />
          <circle cx="27" cy="27" r="3.2" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1" />
          <circle cx="29" cy="52" r="3.2" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1" />
        </g>

        <!-- ── POSE: CLIMB RIGHT ── -->
        <g id="poseClimbRight" style="display: none;">
          <rect x="29.5" y="60" width="6.5" height="17" rx="3" fill="#78350F" stroke="#451A03" stroke-width="1.2" />
          <path d="M27 60 L21 55 L18 68 L24 70 Z" fill="#78350F" stroke="#451A03" stroke-width="1.2" />
          <path d="M29.5 75 H38 V79 C38 80.5 36.5 81.5 34.5 81.5 H29.5 V75 Z" fill="#3B1C0A" stroke="#1A0D04" stroke-width="1.2" />
          <path d="M15.5 67 H24 V71 C24 72.5 22.5 73.5 20.5 73.5 H15.5 V67 Z" fill="#3B1C0A" stroke="#1A0D04" stroke-width="1.2" />

          <path d="M38 42 Q40 28 30 28" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" />
          <path d="M18 42 Q16 50 26 52" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" />
          <circle cx="29" cy="27" r="3.2" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1" />
          <circle cx="27" cy="52" r="3.2" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1" />
        </g>

        <!-- TORSO -->
        <rect x="19" y="38" width="18" height="24" rx="4" fill="#FFFFFF" stroke="#451A03" stroke-width="1.2" />
        <line x1="23" y1="38" x2="23" y2="62" stroke="#DC2626" stroke-width="2" />
        <line x1="33" y1="38" x2="33" y2="62" stroke="#DC2626" stroke-width="2" />

        <!-- HEAD & FRIENDLY FACE -->
        <circle cx="28" cy="24" r="9.5" fill="url(#trvSkin)" stroke="#78350F" stroke-width="1.2" />
        <circle cx="25" cy="22" r="1.3" fill="#3B1C0A" />
        <circle cx="31" cy="22" r="1.3" fill="#3B1C0A" />
        <circle cx="23" cy="26" r="1.5" fill="#F87171" opacity="0.65" />
        <circle cx="33" cy="26" r="1.5" fill="#F87171" opacity="0.65" />
        <path d="M25 26 Q28 29.5 31 26" fill="none" stroke="#78350F" stroke-width="1.4" stroke-linecap="round" />

        <!-- BROWN EXPLORER HAT -->
        <path d="M14 18 C14 18 19 14 28 14 C37 14 42 18 42 18 C45 18 47 19.5 45 21 C43 22 36 21 28 21 C20 21 13 22 11 21 C9 19.5 11 18 14 18 Z" 
              fill="#92400E" stroke="#451A03" stroke-width="1.2" />
        <path d="M20 16 C20 9 23 7 28 7 C33 7 36 9 36 16 Z" 
              fill="#78350F" stroke="#451A03" stroke-width="1.2" />
        <path d="M19.5 15.5 C22 14.8 34 14.8 36.5 15.5 L36.5 17.5 C34 16.8 22 16.8 19.5 17.5 Z" 
              fill="#DC2626" />
      </svg>
    `;
  }

  // ── Geometry & Dimensions ──────────────────────────────────────────────────
  function updateRopeGeometry() {
    const vh = window.innerHeight;
    const ropeTop = 14;
    const seaHeight = 36;
    const ropeBottom = vh - seaHeight + 14;
    const ropeHeight = Math.max(20, ropeBottom - ropeTop);

    const rect = document.getElementById('ropeTrackRect');
    if (rect) {
      rect.setAttribute('y', ropeTop);
      rect.setAttribute('height', ropeHeight);
    }

    const frayedEnd = document.getElementById('ropeFrayedEnd');
    if (frayedEnd) {
      frayedEnd.setAttribute('transform', `translate(18, ${ropeTop + ropeHeight})`);
    }

    // Check if page has scrollable content
    const scrollMax = getScrollMax();
    if (scrollMax <= 10) {
      container.classList.add('is-hidden');
    } else {
      container.classList.remove('is-hidden');
    }
  }

  function getActiveScrollTarget() {
    const spotModal = document.getElementById('spotDetailsModal');
    const spotScroll = document.getElementById('spotPageBodyScroll');
    if (spotModal && spotModal.classList.contains('open') && spotScroll) {
      return spotScroll;
    }
    return window;
  }

  function getScrollY() {
    const target = getActiveScrollTarget();
    return target === window ? window.scrollY : target.scrollTop;
  }

  function getScrollMax() {
    const target = getActiveScrollTarget();
    if (target === window) {
      return Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
    } else {
      return Math.max(0, target.scrollHeight - target.clientHeight);
    }
  }

  // ── Scroll Handling ────────────────────────────────────────────────────────
  function onScroll() {
    const scrollY = getScrollY();
    const delta = Math.abs(scrollY - lastScrollY);
    lastScrollY = scrollY;

    const scrollMax = getScrollMax();
    if (scrollMax <= 0) return;

    const scrollPercent = Math.min(100, Math.max(0, Math.round((scrollY / scrollMax) * 100)));
    container.setAttribute('aria-valuenow', scrollPercent);

    // Calculate Target Traveler Y
    const vh = window.innerHeight;
    const minY = 8;
    const maxY = vh - 36 - 38 + 14;
    const travelRange = Math.max(0, maxY - minY);
    targetTravelerY = minY + (scrollY / scrollMax) * travelRange;

    // Pose Alternation (every ~34px)
    if (!isReducedMotion && delta > 0.5) {
      accumulatedScrollDelta += delta;
      if (accumulatedScrollDelta >= 34) {
        accumulatedScrollDelta = 0;
        setPose(currentPose === 'climbLeft' ? 'climbRight' : 'climbLeft');
      }

      // Reset to idle after ~200ms
      clearTimeout(idleTimer);
      idleTimer = setTimeout(() => {
        setPose('idle');
      }, 200);
    }
  }

  function setPose(pose) {
    if (currentPose === pose) return;
    currentPose = pose;

    const idleG = document.getElementById('poseIdle');
    const leftG = document.getElementById('poseClimbLeft');
    const rightG = document.getElementById('poseClimbRight');

    if (idleG && leftG && rightG) {
      idleG.style.display = pose === 'idle' ? 'block' : 'none';
      leftG.style.display = pose === 'climbLeft' ? 'block' : 'none';
      rightG.style.display = pose === 'climbRight' ? 'block' : 'none';
    }
  }

  // ── 60 FPS Physics & Smoothing Loop ────────────────────────────────────────
  function physicsLoop() {
    // 1. Follow smoothing: 25% lerp per frame
    const diff = targetTravelerY - currentTravelerY;
    if (Math.abs(diff) > 0.05) {
      currentTravelerY += diff * 0.25;
    } else {
      currentTravelerY = targetTravelerY;
    }

    // 2. Idle sway oscillation (~2.5 deg)
    let swayAngle = 0;
    if (!isReducedMotion && currentPose === 'idle' && !isDragging) {
      idleTime += 0.035;
      swayAngle = Math.sin(idleTime * 2.4) * 2.5;
    }

    // Apply Transform
    travelerEl.style.transform = `translate3d(0, ${currentTravelerY}px, 0) rotate(${swayAngle}deg)`;

    requestAnimationFrame(physicsLoop);
  }

  // ── Drag & Tap Interactions ────────────────────────────────────────────────
  function onDragStart(e) {
    e.preventDefault();
    isDragging = true;
    dragStartY = e.clientY;
    dragStartScroll = getScrollY();
    travelerEl.classList.add('is-dragging');

    window.addEventListener('mousemove', onDragMove);
    window.addEventListener('mouseup', onDragEnd);
  }

  function onTouchStart(e) {
    if (e.touches.length !== 1) return;
    e.preventDefault();
    isDragging = true;
    dragStartY = e.touches[0].clientY;
    dragStartScroll = getScrollY();
    travelerEl.classList.add('is-dragging');

    window.addEventListener('touchmove', onTouchMove, { passive: false });
    window.addEventListener('touchend', onDragEnd);
  }

  function onDragMove(e) {
    if (!isDragging) return;
    performDrag(e.clientY);
  }

  function onTouchMove(e) {
    if (!isDragging || e.touches.length !== 1) return;
    e.preventDefault();
    performDrag(e.touches[0].clientY);
  }

  function performDrag(clientY) {
    const vh = window.innerHeight;
    const minY = 8;
    const maxY = vh - 36 - 38 + 14;
    const travelRange = Math.max(1, maxY - minY);
    const scrollMax = getScrollMax();

    const deltaY = clientY - dragStartY;
    const scrollDelta = (deltaY / travelRange) * scrollMax;
    const newScroll = Math.max(0, Math.min(scrollMax, dragStartScroll + scrollDelta));

    const target = getActiveScrollTarget();
    if (target === window) {
      window.scrollTo({ top: newScroll, behavior: 'auto' });
    } else {
      target.scrollTop = newScroll;
    }
  }

  function onDragEnd() {
    isDragging = false;
    travelerEl.classList.remove('is-dragging');
    window.removeEventListener('mousemove', onDragMove);
    window.removeEventListener('mouseup', onDragEnd);
    window.removeEventListener('touchmove', onTouchMove);
    window.removeEventListener('touchend', onDragEnd);
  }

  function onRopeClick(e) {
    const rect = ropeClickable.getBoundingClientRect();
    const clickY = e.clientY - rect.top;
    const ratio = Math.max(0, Math.min(1, clickY / rect.height));
    const scrollMax = getScrollMax();
    const targetScroll = ratio * scrollMax;

    const target = getActiveScrollTarget();
    if (target === window) {
      window.scrollTo({ top: targetScroll, behavior: 'smooth' });
    } else {
      target.scrollTo({ top: targetScroll, behavior: 'smooth' });
    }
  }

  function onResize() {
    updateRopeGeometry();
    onScroll();
  }

  // ── Auto Start ─────────────────────────────────────────────────────────────
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
