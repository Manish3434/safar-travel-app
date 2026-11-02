/**
 * Cobra Voice Search Button (Spec v2) for Safar Web App
 * 
 * Implements the native 60fps vector Canvas animation:
 * - 200-point polar morphing in-place between round teal button and 3D cartoon Cobra Head
 * - Smooth color interpolation: Teal (#19C3B0) -> Coral-Red (#D4564C)
 * - 3D clay lighting, scale texture, cream cheek lining (#EED6B8) with rib lines
 * - Bouncing golden-amber eyes (#FBBF24) with slit pupils, specular highlights, and natural blinks
 * - Forked deep-pink tongue (#E11D48) flick
 * - Open mouth cavity (#420C14) with pointed white fangs
 * - Three glowing white voice equalizer bars inside the mouth that dance to live mic volume
 * - Concentric pulsing ripple rings
 */

(function (window) {
  'use strict';

  // 200 Pre-computed polar angles around center
  const POINT_COUNT = 200;
  const ANGLES = new Float32Array(POINT_COUNT);
  for (let i = 0; i < POINT_COUNT; i++) {
    ANGLES[i] = (2 * Math.PI * i) / POINT_COUNT;
  }

  // Theme Colors (Spec v2)
  const THEME = {
    idleColor: { r: 25, g: 195, b: 176 },       // #19C3B0 (Teal)
    idleBorderColor: { r: 14, g: 143, b: 134 }, // #0E8F86
    hoodColor: { r: 212, g: 86, b: 76 },        // #D4564C (Coral Red)
    hoodDarkColor: { r: 158, g: 42, b: 43 },    // #9E2A2B
    hoodLiningColor: '#EED6B8',                 // Soft cream
    eyeColor: '#FBBF24',                        // Amber gold
    pupilColor: '#0F172A',                      // Dark vertical slit
    mouthCavityColor: '#420C14',                // Deep dark red
    fangsColor: '#FFFFFF',
    voiceBarColor: '#FFFFFF',
    tongueColor: '#E11D48',                     // Deep pink
    rippleColor: 'rgba(25, 195, 176, '          // Teal ripples
  };

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function lerpColor(c1, c2, t) {
    const r = Math.round(lerp(c1.r, c2.r, t));
    const g = Math.round(lerp(c1.g, c2.g, t));
    const b = Math.round(lerp(c1.b, c2.b, t));
    return `rgb(${r}, ${g}, ${b})`;
  }

  function easeOutBack(t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
  }

  function easeInOutQuad(t) {
    return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
  }

  class CobraVoiceEngine {
    constructor() {
      this.canvas = null;
      this.ctx = null;
      this.containerBtn = null;
      this.captionEl = null;

      this.state = 'idle'; // 'idle' | 'touching' | 'morphing' | 'listening' | 'stopping'
      this.isListening = false;
      this.audioLoudness = 0;
      this.smoothedLoudness = 0;

      // Animation progress trackers (0.0 -> 1.0)
      this.touchProgress = 0;
      this.morphProgress = 0;
      this.eyesProgress = 0;
      this.mouthProgress = 0;
      this.tongueProgress = 0;
      this.blinkProgress = 0;
      this.rippleProgress = 0;
      this.equalizerTime = 0;

      this.rafId = null;
      this.lastTime = performance.now();
      this.blinkTimer = null;

      // Web Audio API
      this.audioContext = null;
      this.analyserNode = null;
      this.audioData = null;
      this.micStream = null;

      // Accessibility
      this.enableSnakeMorph = true;
      this.reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    }

    init(canvasId = 'cobraVoiceCanvas', buttonId = 'btnHeroVoiceSearch') {
      this.canvas = document.getElementById(canvasId);
      this.containerBtn = document.getElementById(buttonId);

      if (this.containerBtn) {
        this.containerBtn.style.position = 'relative';
        this.containerBtn.style.overflow = 'visible';
        this.containerBtn.style.background = 'transparent';
        this.containerBtn.style.border = 'none';
        this.containerBtn.style.boxShadow = 'none';
      }

      if (!this.canvas && this.containerBtn) {
        // Dynamically inject high-DPI canvas inside the voice button
        this.canvas = document.createElement('canvas');
        this.canvas.id = canvasId;
        this.canvas.className = 'cobra-voice-canvas';
        this.containerBtn.innerHTML = ''; // Replace static SVG
        this.containerBtn.appendChild(this.canvas);
      }

      if (!this.canvas) return;

      this.ctx = this.canvas.getContext('2d');
      this.resizeCanvas();
      window.addEventListener('resize', () => this.resizeCanvas());

      // Start render loop
      this.scheduleBlink();
      this.animate = this.animate.bind(this);
      this.rafId = requestAnimationFrame(this.animate);
    }

    resizeCanvas() {
      if (!this.canvas) return;
      const dpr = window.devicePixelRatio || 2;
      // 110px CSS width & height provides generous room for flared cobra cheeks & ripples
      const cssSize = 110;
      this.canvas.width = cssSize * dpr;
      this.canvas.height = cssSize * dpr;
      this.canvas.style.width = `${cssSize}px`;
      this.canvas.style.height = `${cssSize}px`;
      this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }

    scheduleBlink() {
      if (this.blinkTimer) clearTimeout(this.blinkTimer);
      const delay = 2600 + Math.random() * 1800;
      this.blinkTimer = setTimeout(() => {
        if (this.state === 'listening') {
          this.triggerBlink();
        }
        this.scheduleBlink();
      }, delay);
    }

    triggerBlink() {
      const startTime = performance.now();
      const blinkDuration = 180;
      const step = (now) => {
        const elapsed = now - startTime;
        if (elapsed < blinkDuration) {
          const t = elapsed / blinkDuration;
          this.blinkProgress = Math.sin(t * Math.PI);
          requestAnimationFrame(step);
        } else {
          this.blinkProgress = 0;
        }
      };
      requestAnimationFrame(step);
    }

    setCaption(text) {
      if (this.captionEl) {
        this.captionEl.textContent = text;
      }
    }

    start() {
      if (this.isListening) return;
      this.isListening = true;
      this.state = 'touching';
      this.touchProgress = 1.0;

      // Play authentic King Cobra snake hiss sound on touch
      if (typeof window.playCobraSnakeSound === 'function') {
        window.playCobraSnakeSound();
      }

      this.initMicrophoneAudio();

      // Timeline sequence matching Spec v2:
      // 0.00 - 0.25: Touch press down
      setTimeout(() => {
        if (!this.isListening) return;
        this.state = 'morphing';
      }, 200);

      // 0.85: Face details fade in
      // 1.05: Tongue flick & eyes pop in
      setTimeout(() => {
        if (!this.isListening) return;
        this.triggerTongueFlick();
        if (typeof window.playSnakeTongueSound === 'function') {
          window.playSnakeTongueSound();
        }
      }, 700);

      // 1.55: Mouth opens wide, listening active
      setTimeout(() => {
        if (!this.isListening) return;
        this.state = 'listening';
      }, 950);
    }

    stop() {
      if (!this.isListening && this.state === 'idle') return;
      this.isListening = false;
      this.state = 'stopping';
      this.releaseMicrophoneAudio();
    }

    toggle() {
      if (this.isListening) {
        this.stop();
      } else {
        this.start();
      }
    }

    triggerTongueFlick() {
      const startTime = performance.now();
      const duration = 340;
      const step = (now) => {
        const elapsed = now - startTime;
        if (elapsed < duration) {
          const t = elapsed / duration;
          this.tongueProgress = Math.sin(t * Math.PI);
          requestAnimationFrame(step);
        } else {
          this.tongueProgress = 0;
        }
      };
      requestAnimationFrame(step);
    }

    async initMicrophoneAudio() {
      try {
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) return;
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        this.micStream = stream;
        const AudioContextClass = window.AudioContext || window.webkitAudioContext;
        if (AudioContextClass) {
          this.audioContext = new AudioContextClass();
          const source = this.audioContext.createMediaStreamSource(stream);
          this.analyserNode = this.audioContext.createAnalyser();
          this.analyserNode.fftSize = 64;
          this.analyserNode.smoothingTimeConstant = 0.75;
          source.connect(this.analyserNode);
          this.audioData = new Uint8Array(this.analyserNode.frequencyBinCount);
        }
      } catch (err) {
        // User denied mic or not supported: fallback to procedural sine-wave audio
        this.micStream = null;
      }
    }

    releaseMicrophoneAudio() {
      if (this.micStream) {
        this.micStream.getTracks().forEach((track) => track.stop());
        this.micStream = null;
      }
      if (this.audioContext) {
        try { this.audioContext.close(); } catch (e) {}
        this.audioContext = null;
        this.analyserNode = null;
      }
    }

    getLiveLoudness() {
      if (this.analyserNode && this.audioData) {
        this.analyserNode.getByteFrequencyData(this.audioData);
        let sum = 0;
        for (let i = 0; i < this.audioData.length; i++) {
          sum += this.audioData[i];
        }
        return Math.min(1.0, (sum / (this.audioData.length * 255)) * 2.2);
      }
      // Procedural fallback when mic is unavailable
      const t = this.equalizerTime;
      return 0.35 + 0.35 * Math.sin(t * 4.2) + 0.15 * Math.cos(t * 7.5);
    }

    animate(now) {
      const dt = Math.min(0.1, (now - this.lastTime) / 1000);
      this.lastTime = now;
      this.equalizerTime += dt;

      // Update audio loudness smoothing
      const targetLoudness = this.getLiveLoudness();
      this.smoothedLoudness = lerp(this.smoothedLoudness, targetLoudness, dt * 12);

      // State Progression Physics
      if (this.state === 'touching') {
        this.touchProgress = Math.max(0, this.touchProgress - dt * 4.0);
      } else if (this.state === 'morphing') {
        this.morphProgress = Math.min(1.0, this.morphProgress + dt * 2.2);
        this.eyesProgress = Math.min(1.0, this.eyesProgress + dt * 2.8);
      } else if (this.state === 'listening') {
        this.morphProgress = 1.0;
        this.eyesProgress = 1.0;
        this.mouthProgress = Math.min(1.0, this.mouthProgress + dt * 3.5);
        this.rippleProgress = (this.rippleProgress + dt * 0.75) % 1.0;
      } else if (this.state === 'stopping') {
        this.mouthProgress = Math.max(0, this.mouthProgress - dt * 4.5);
        if (this.mouthProgress <= 0.05) {
          this.eyesProgress = Math.max(0, this.eyesProgress - dt * 4.0);
          this.morphProgress = Math.max(0, this.morphProgress - dt * 2.8);
          if (this.morphProgress <= 0.01) {
            this.state = 'idle';
            this.morphProgress = 0;
            this.eyesProgress = 0;
            this.mouthProgress = 0;
          }
        }
      }

      this.render();
      this.rafId = requestAnimationFrame(this.animate);
    }

    render() {
      const ctx = this.ctx;
      if (!ctx) return;

      const width = 110;
      const height = 110;
      ctx.clearRect(0, 0, width, height);

      const cx = width / 2;
      const cy = height / 2;
      const idleRadius = 24; // 48px diameter button
      const fullHoodRadius = idleRadius * 1.5; // ~36px (cheeks flare to ~40.3px, total ~80.6px width)

      // Touch scale press-in effect (~10% compression)
      const touchScale = 1.0 - (this.touchProgress * 0.12);
      ctx.save();
      ctx.translate(cx, cy);
      ctx.scale(touchScale, touchScale);
      ctx.translate(-cx, -cy);

      // ────────────────────────────────────────────────────────────────────────
      // 1. Concentric Pulse Halo Rings (Listening state)
      // ────────────────────────────────────────────────────────────────────────
      if (this.morphProgress > 0.05) {
        this.drawRipples(ctx, cx, cy, idleRadius);
      }

      // ────────────────────────────────────────────────────────────────────────
      // 2. 200-Point Polar Morphing Hood Shell
      // ────────────────────────────────────────────────────────────────────────
      const morphT = this.reduceMotion ? 0 : this.morphProgress;
      const hoodPath = this.createMorphPath(cx, cy, idleRadius, fullHoodRadius, morphT);

      // Color interpolation: Teal (#19C3B0) -> Coral Red (#D4564C)
      const curHoodColor = lerpColor(THEME.idleColor, THEME.hoodColor, morphT);
      const curDarkColor = lerpColor(THEME.idleBorderColor, THEME.hoodDarkColor, morphT);

      // 3D Soft Radial Lighting Gradient (top-left highlight)
      const grad = ctx.createRadialGradient(
        cx - fullHoodRadius * 0.35,
        cy - fullHoodRadius * 0.45,
        fullHoodRadius * 0.1,
        cx,
        cy,
        fullHoodRadius
      );
      grad.addColorStop(0.0, lerpColor(THEME.idleColor, { r: 255, g: 155, b: 145 }, morphT));
      grad.addColorStop(0.55, curHoodColor);
      grad.addColorStop(1.0, curDarkColor);

      // Soft drop shadow
      ctx.save();
      ctx.shadowColor = 'rgba(0, 0, 0, 0.45)';
      ctx.shadowBlur = 12;
      ctx.shadowOffsetY = 4;
      ctx.fillStyle = grad;
      ctx.fill(hoodPath);
      ctx.restore();

      // Border outline for idle button
      if (morphT < 0.25) {
        ctx.strokeStyle = `rgba(14, 143, 134, ${1.0 - morphT * 4})`;
        ctx.lineWidth = 1.8;
        ctx.stroke(hoodPath);
      }

      // Micro Scale Texture on Hood
      if (morphT > 0.3) {
        this.drawScaleTexture(ctx, hoodPath, cx, cy, fullHoodRadius, morphT);
      }

      // ────────────────────────────────────────────────────────────────────────
      // 3. Microphone Icon (Fades out as morph starts)
      // ────────────────────────────────────────────────────────────────────────
      const micOpacity = Math.max(0, 1.0 - morphT * 2.5);
      if (micOpacity > 0.01) {
        this.drawMicrophoneIcon(ctx, cx, cy, idleRadius * 0.45, micOpacity);
      }

      // If morph hasn't reached face details, exit early
      if (morphT > 0.05) {
        // 4. Cream Hood Lining & Cheeks
        this.drawCreamCheeks(ctx, cx, cy, fullHoodRadius, morphT);

        // 5. Head Dome & Nostrils
        this.drawHeadDomeAndNostrils(ctx, cx, cy, fullHoodRadius, morphT, curHoodColor);

        // 6. Forked Tongue Flick
        if (this.tongueProgress > 0.02) {
          this.drawTongue(ctx, cx, cy, fullHoodRadius, this.tongueProgress);
        }

        // 7. Open Mouth & Fangs
        if (this.mouthProgress > 0.02) {
          this.drawOpenMouth(ctx, cx, cy, fullHoodRadius, this.mouthProgress);
        }

        // 8. Glowing Voice Equalizer Bars (Inside Mouth)
        if (this.mouthProgress > 0.25) {
          this.drawEqualizerBars(ctx, cx, cy, fullHoodRadius, this.mouthProgress);
        }

        // 9. Big Expressive Cobra Eyes
        if (this.eyesProgress > 0.05) {
          this.drawEyes(ctx, cx, cy, fullHoodRadius, this.eyesProgress, this.blinkProgress);
        }
      }

      ctx.restore();
    }

    createMorphPath(cx, cy, rCircle, rHoodMax, t) {
      const path = new Path2D();
      for (let i = 0; i < POINT_COUNT; i++) {
        const theta = ANGLES[i];
        const cosTheta = Math.cos(theta);
        const sinTheta = Math.sin(theta);

        // Parametric shield curve: wide flared cheeks, top crest, tapered chin
        const cheekFactor = Math.pow(Math.abs(cosTheta), 1.6) * (1.0 + 0.35 * sinTheta);
        const chinFactor = sinTheta > 0 ? 1.0 - 0.28 * sinTheta : 1.0;
        const crestFactor = sinTheta < 0 ? 0.85 + 0.15 * Math.cos(theta * 2) : 1.0;

        const rTarget = rHoodMax * (0.68 + 0.44 * cheekFactor) * chinFactor * crestFactor;
        const currentR = (1.0 - t) * rCircle + t * rTarget;

        const x = cx + currentR * cosTheta;
        const y = cy + currentR * sinTheta;

        if (i === 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.closePath();
      return path;
    }

    drawRipples(ctx, cx, cy, baseR) {
      for (let i = 0; i < 3; i++) {
        const phase = (this.rippleProgress + i * 0.33) % 1.0;
        const r = baseR * (1.1 + phase * 1.25);
        const opacity = (1.0 - phase) * 0.45;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.strokeStyle = `${THEME.rippleColor}${opacity.toFixed(2)})`;
        ctx.lineWidth = 2.0;
        ctx.stroke();
      }
    }

    drawScaleTexture(ctx, clipPath, cx, cy, radius, t) {
      ctx.save();
      ctx.clip(clipPath);
      ctx.strokeStyle = `rgba(255, 255, 255, ${(0.07 * t).toFixed(3)})`;
      ctx.lineWidth = 1;

      const step = 6.5;
      for (let x = cx - radius; x <= cx + radius; x += step) {
        for (let y = cy - radius; y <= cy + radius; y += step) {
          const d = Math.hypot(x - cx, y - cy);
          if (d < radius * 0.82) {
            ctx.beginPath();
            ctx.arc(x, y, 1.2, 0, Math.PI * 2);
            ctx.stroke();
          }
        }
      }
      ctx.restore();
    }

    drawMicrophoneIcon(ctx, cx, cy, size, opacity) {
      ctx.save();
      ctx.fillStyle = `rgba(255, 255, 255, ${opacity.toFixed(2)})`;
      ctx.strokeStyle = `rgba(255, 255, 255, ${opacity.toFixed(2)})`;
      ctx.lineWidth = size * 0.16;
      ctx.lineCap = 'round';

      // Mic Capsule
      const capsuleW = size * 0.44;
      const capsuleH = size * 0.82;
      const capsuleX = cx - capsuleW / 2;
      const capsuleY = cy - size * 0.55;
      const r = capsuleW / 2;

      ctx.beginPath();
      ctx.roundRect ? ctx.roundRect(capsuleX, capsuleY, capsuleW, capsuleH, r) : ctx.rect(capsuleX, capsuleY, capsuleW, capsuleH);
      ctx.fill();

      // Cradle Arc
      ctx.beginPath();
      ctx.arc(cx, cy - size * 0.1, size * 0.42, 0.15, Math.PI - 0.15, false);
      ctx.stroke();

      // Stem & Base
      const stemY = cy + size * 0.32;
      ctx.beginPath();
      ctx.moveTo(cx, stemY);
      ctx.lineTo(cx, stemY + size * 0.25);
      ctx.moveTo(cx - size * 0.28, stemY + size * 0.25);
      ctx.lineTo(cx + size * 0.28, stemY + size * 0.25);
      ctx.stroke();
      ctx.restore();
    }

    drawCreamCheeks(ctx, cx, cy, radius, t) {
      ctx.save();
      ctx.fillStyle = THEME.hoodLiningColor;
      ctx.globalAlpha = Math.min(1.0, t);

      const cheekHeight = radius * 0.65;

      // Left Cheek
      ctx.beginPath();
      ctx.moveTo(cx - radius * 0.72, cy);
      ctx.quadraticCurveTo(cx - radius * 0.82, cy - cheekHeight * 0.4, cx - radius * 0.36, cy - radius * 0.15);
      ctx.quadraticCurveTo(cx - radius * 0.15, cy + cheekHeight * 0.48, cx - radius * 0.55, cy + cheekHeight * 0.38);
      ctx.closePath();
      ctx.fill();

      // Right Cheek
      ctx.beginPath();
      ctx.moveTo(cx + radius * 0.72, cy);
      ctx.quadraticCurveTo(cx + radius * 0.82, cy - cheekHeight * 0.4, cx + radius * 0.36, cy - radius * 0.15);
      ctx.quadraticCurveTo(cx + radius * 0.15, cy + cheekHeight * 0.48, cx + radius * 0.55, cy + cheekHeight * 0.38);
      ctx.closePath();
      ctx.fill();

      // Horizontal Rib Lines
      ctx.strokeStyle = 'rgba(180, 130, 90, 0.26)';
      ctx.lineWidth = 1.0;
      for (let i = 0; i < 4; i++) {
        const yOffset = (i - 1.5) * (radius * 0.12);
        ctx.beginPath();
        ctx.moveTo(cx - radius * 0.62, cy + yOffset);
        ctx.lineTo(cx - radius * 0.32, cy + yOffset + 2);
        ctx.moveTo(cx + radius * 0.62, cy + yOffset);
        ctx.lineTo(cx + radius * 0.32, cy + yOffset + 2);
        ctx.stroke();
      }
      ctx.restore();
    }

    drawHeadDomeAndNostrils(ctx, cx, cy, radius, t, hoodColor) {
      ctx.save();
      ctx.globalAlpha = Math.min(1.0, t);

      // Crown dome
      ctx.beginPath();
      ctx.ellipse(cx, cy - radius * 0.22, radius * 0.42, radius * 0.35, 0, 0, Math.PI * 2);
      ctx.fillStyle = hoodColor;
      ctx.fill();

      // Nostrils
      ctx.fillStyle = 'rgba(40, 10, 12, 0.85)';
      const nostrilY = cy - radius * 0.08;
      ctx.beginPath();
      ctx.ellipse(cx - radius * 0.10, nostrilY, radius * 0.04, radius * 0.025, -0.2, 0, Math.PI * 2);
      ctx.ellipse(cx + radius * 0.10, nostrilY, radius * 0.04, radius * 0.025, 0.2, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }

    drawTongue(ctx, cx, cy, radius, t) {
      ctx.save();
      const length = radius * 0.48 * t;
      const startY = cy + radius * 0.18;
      ctx.strokeStyle = THEME.tongueColor;
      ctx.lineWidth = radius * 0.07;
      ctx.lineCap = 'round';

      // Main stalk
      ctx.beginPath();
      ctx.moveTo(cx, startY);
      ctx.lineTo(cx, startY + length * 0.72);
      // Left Fork
      ctx.lineTo(cx - radius * 0.11, startY + length);
      // Right Fork
      ctx.moveTo(cx, startY + length * 0.72);
      ctx.lineTo(cx + radius * 0.11, startY + length);
      ctx.stroke();
      ctx.restore();
    }

    drawOpenMouth(ctx, cx, cy, radius, mouthT) {
      ctx.save();
      const mouthWidth = radius * 0.82;
      const mouthHeight = radius * 0.72 * mouthT;
      const mouthY = cy + radius * 0.08;

      // Dark red interior cavity
      ctx.beginPath();
      ctx.moveTo(cx - mouthWidth * 0.46, mouthY);
      ctx.quadraticCurveTo(cx, mouthY - mouthHeight * 0.15, cx + mouthWidth * 0.46, mouthY);
      ctx.quadraticCurveTo(cx + mouthWidth * 0.52, mouthY + mouthHeight * 0.85, cx, mouthY + mouthHeight);
      ctx.quadraticCurveTo(cx - mouthWidth * 0.52, mouthY + mouthHeight * 0.85, cx - mouthWidth * 0.46, mouthY);
      ctx.closePath();

      const cavityGrad = ctx.createLinearGradient(cx, mouthY, cx, mouthY + mouthHeight);
      cavityGrad.addColorStop(0.0, '#1E0508');
      cavityGrad.addColorStop(1.0, THEME.mouthCavityColor);
      ctx.fillStyle = cavityGrad;
      ctx.fill();

      // White Upper Fangs
      ctx.fillStyle = THEME.fangsColor;
      const fangH = radius * 0.22 * mouthT;
      const fangW = radius * 0.08;
      const fangY = mouthY + 1;

      // Left Fang
      ctx.beginPath();
      ctx.moveTo(cx - radius * 0.26, fangY);
      ctx.lineTo(cx - radius * 0.26 + fangW, fangY);
      ctx.lineTo(cx - radius * 0.26 + fangW * 0.5, fangY + fangH);
      ctx.closePath();
      ctx.fill();

      // Right Fang
      ctx.beginPath();
      ctx.moveTo(cx + radius * 0.26 - fangW, fangY);
      ctx.lineTo(cx + radius * 0.26, fangY);
      ctx.lineTo(cx + radius * 0.26 - fangW * 0.5, fangY + fangH);
      ctx.closePath();
      ctx.fill();

      // Lower Jaw Chin Ridge
      ctx.beginPath();
      ctx.moveTo(cx - mouthWidth * 0.36, mouthY + mouthHeight * 0.95);
      ctx.quadraticCurveTo(cx, mouthY + mouthHeight * 1.25, cx + mouthWidth * 0.36, mouthY + mouthHeight * 0.95);
      ctx.strokeStyle = THEME.hoodLiningColor;
      ctx.lineWidth = radius * 0.09;
      ctx.lineCap = 'round';
      ctx.stroke();

      ctx.restore();
    }

    drawEqualizerBars(ctx, cx, cy, radius, mouthT) {
      ctx.save();
      const mouthY = cy + radius * 0.08;
      const mouthHeight = radius * 0.72 * mouthT;
      const centerY = mouthY + mouthHeight * 0.52;
      const barWidth = radius * 0.09;
      const barSpacing = radius * 0.16;

      const loudness = this.smoothedLoudness;
      const t = this.equalizerTime;

      // Heights follow live loudness with organic rhythmic harmonics
      const baseMaxH = mouthHeight * 0.65;
      const h1 = baseMaxH * (0.35 + 0.65 * loudness * (0.8 + 0.2 * Math.sin(t * 8.0)));
      const h2 = baseMaxH * (0.50 + 0.75 * loudness * (0.85 + 0.25 * Math.cos(t * 10.5))); // Tallest center bar
      const h3 = baseMaxH * (0.35 + 0.65 * loudness * (0.8 + 0.2 * Math.sin(t * 7.5 + 1.2)));

      ctx.fillStyle = THEME.voiceBarColor;
      ctx.shadowColor = 'rgba(255, 255, 255, 0.9)';
      ctx.shadowBlur = 8;

      const drawBar = (x, h) => {
        const top = centerY - h / 2;
        const r = barWidth / 2;
        ctx.beginPath();
        ctx.roundRect ? ctx.roundRect(x - barWidth / 2, top, barWidth, h, r) : ctx.rect(x - barWidth / 2, top, barWidth, h);
        ctx.fill();
      };

      drawBar(cx - barSpacing, Math.max(barWidth * 1.2, h1));
      drawBar(cx, Math.max(barWidth * 1.5, h2));
      drawBar(cx + barSpacing, Math.max(barWidth * 1.2, h3));

      ctx.restore();
    }

    drawEyes(ctx, cx, cy, radius, eyesT, blinkT) {
      ctx.save();
      // Eyes spring bounce pop-in scale
      const eyeBounce = easeOutBack(Math.min(1.0, eyesT));
      const eyeRadius = radius * 0.18 * eyeBounce;
      const eyeY = cy - radius * 0.32;
      const eyeSpacing = radius * 0.36;

      // Blinking compresses eye height
      const blinkScaleY = 1.0 - (blinkT * 0.90);

      const drawEye = (x) => {
        ctx.save();
        ctx.translate(x, eyeY);
        ctx.scale(1.0, blinkScaleY);

        // Coral Eyelid Ring
        ctx.beginPath();
        ctx.arc(0, 0, eyeRadius * 1.15, 0, Math.PI * 2);
        ctx.fillStyle = THEME.hoodDarkColor;
        ctx.fill();

        // Golden Amber Sclera / Iris
        ctx.beginPath();
        ctx.arc(0, 0, eyeRadius, 0, Math.PI * 2);
        const irisGrad = ctx.createRadialGradient(-eyeRadius * 0.25, -eyeRadius * 0.25, eyeRadius * 0.1, 0, 0, eyeRadius);
        irisGrad.addColorStop(0.0, '#FEF08A');
        irisGrad.addColorStop(0.6, THEME.eyeColor);
        irisGrad.addColorStop(1.0, '#D97706');
        ctx.fillStyle = irisGrad;
        ctx.fill();

        // Vertical Slit Pupil
        ctx.beginPath();
        ctx.ellipse(0, 0, eyeRadius * 0.25, eyeRadius * 0.75, 0, 0, Math.PI * 2);
        ctx.fillStyle = THEME.pupilColor;
        ctx.fill();

        // Specular White Highlight Dot
        ctx.beginPath();
        ctx.arc(-eyeRadius * 0.32, -eyeRadius * 0.32, eyeRadius * 0.22, 0, Math.PI * 2);
        ctx.fillStyle = '#FFFFFF';
        ctx.fill();

        ctx.restore();
      };

      drawEye(cx - eyeSpacing);
      drawEye(cx + eyeSpacing);

      ctx.restore();
    }
  }

  // Expose singleton instance to global scope
  window.CobraVoice = new CobraVoiceEngine();

  // Initialize once DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => window.CobraVoice.init());
  } else {
    window.CobraVoice.init();
  }

})(window);
