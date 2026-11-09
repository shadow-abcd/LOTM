#!/usr/bin/env python3
"""Synthesises all audio for the Godot project (no samples, no downloads).
Run from project root: python3 tools/make_audio.py     Needs numpy, scipy, ffmpeg (for .ogg music).
"""
import os, wave, subprocess, math
import numpy as np
from scipy.signal import lfilter, fftconvolve, butter, sosfilt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
SR = 32000
rng = np.random.default_rng(11)

# ───────── primitives ─────────
def t_(dur): return np.arange(int(dur * SR)) / SR
def midi(n): return 440.0 * 2 ** ((n - 69) / 12)
def env(n, a=.005, d=.1, s=.6, r=.1):
    e = np.ones(n); na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = max(na, 1)
    e[:na] = np.linspace(0, 1, na)
    if nd > 0 and na + nd < n: e[na:na + nd] = np.linspace(1, s, nd); e[na + nd:] = s
    if nr > 0 and nr < n: e[-nr:] *= np.linspace(1, 0, nr)
    return e
def osc(f, dur, kind="sine", detune=0.0):
    t = t_(dur); f = np.asarray(f) if not np.isscalar(f) else f
    ph = 2 * np.pi * np.cumsum(np.broadcast_to(f * (1 + detune), t.shape)) / SR
    if kind == "sine": return np.sin(ph)
    if kind == "saw": return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if kind == "square": return np.sign(np.sin(ph))
    if kind == "tri": return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1) - 1) - 1
    if kind == "fm": return np.sin(ph + 2.2 * np.sin(ph * 2.0))
    raise ValueError(kind)
def noise(dur): return rng.uniform(-1, 1, int(dur * SR))
def lp(x, fc, order=2):
    return sosfilt(butter(order, min(fc, SR / 2 - 100), "low", fs=SR, output="sos"), x)
def hp(x, fc, order=2):
    return sosfilt(butter(order, fc, "high", fs=SR, output="sos"), x)
def bp(x, lo, hi):
    return sosfilt(butter(2, [lo, min(hi, SR / 2 - 100)], "band", fs=SR, output="sos"), x)
def norm(x, peak=.9):
    m = np.max(np.abs(x)) + 1e-9; return x / m * peak
def sweep(f0, f1, dur, curve=2.0):
    t = np.linspace(0, 1, int(dur * SR)); return f0 + (f1 - f0) * t ** curve
def reverb(x, tail=2.2, wet=.3, bright=.55):
    n = int(tail * SR); ir = noise(tail) * np.exp(-np.linspace(0, 7, n)); ir = lp(ir, 4200 * bright + 800)
    ir = np.concatenate([[1.0], ir * .08]); y = fftconvolve(x, ir)[:len(x) + n]
    return y, n
def place(buf, snd, at):
    i = int(at * SR); e = min(len(buf), i + len(snd))
    if i < len(buf): buf[i:e] += snd[:e - i]

# ───────── file writers ─────────
def save_wav(path, x, sr=22050):
    x = np.asarray(x); ratio = SR / sr
    if sr != SR:
        idx = np.arange(0, len(x), ratio).astype(int); x = lp(x, sr * .45)[idx]
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(pcm.tobytes())

def save_ogg(path, stereo):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp.wav"
    pcm = (np.clip(stereo, -1, 1) * 32767).astype(np.int16)
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", path], check=True)
    os.remove(tmp)

def finish_loop(dry_l, dry_r, loop_len, tail_wet=.28, tail=2.4):
    """reverb, then fold the tail back onto the start so the loop is seamless"""
    outs = []
    for ch in (dry_l, dry_r):
        wetsig, n = reverb(ch, tail, tail_wet)
        y = np.zeros(len(wetsig)); y[:len(ch)] += ch; y += wetsig * tail_wet
        L = loop_len
        body = y[:L].copy(); rest = y[L:]
        body[:len(rest)] += rest[:L]
        outs.append(body)
    return norm(np.stack(outs, 1), .82)

# ───────── SFX ─────────
def sfx():
    d = os.path.join(OUT, "sfx"); S = {}
    def tone(f, dur, kind="sine", a=.003, dec=.1, s=.0, r=.05): return osc(f, dur, kind) * env(int(dur * SR), a, dec, s, r)
    S["ui_hover"] = tone(1400, .05, "sine", .002, .04, 0, .02) * .35
    S["ui_click"] = lp(tone(sweep(900, 500, .09), .09, "tri", .002, .08, 0, .02), 4000) * .8
    S["ui_back"] = tone(sweep(520, 300, .12), .12, "tri", .002, .1, 0, .03) * .7
    S["ui_open"] = norm(tone(sweep(300, 700, .2), .2, "sine", .01, .2, 0, .05) + .5 * noise(.2) * env(int(.2 * SR), .01, .2, 0, .05) * .3, .6)
    S["ui_confirm"] = np.concatenate([tone(midi(76), .09, "tri", .002, .08, 0, .02), tone(midi(83), .16, "tri", .002, .15, 0, .05)]) * .7
    S["ui_error"] = np.concatenate([tone(160, .1, "square", .002, .08, 0, .02), tone(120, .16, "square", .002, .14, 0, .04)]) * .35
    S["ui_toggle"] = tone(sweep(700, 980, .07), .07, "tri", .002, .06, 0, .02) * .7
    S["ui_slider"] = tone(1100, .03, "sine", .001, .03, 0, .01) * .4
    S["equip"] = norm(tone(midi(60), .3, "fm", .004, .25, 0, .06) + np.pad(hp(noise(.1), 2500) * env(int(.1 * SR), .001, .09, 0, .01) * .4, (0, int(.2 * SR))), .75)
    S["unequip"] = tone(sweep(600, 250, .15), .15, "tri", .002, .13, 0, .03) * .6
    S["unlock"] = np.concatenate([tone(midi(m), .1, "fm", .002, .1, 0, .03) for m in (72, 76, 79, 84)]) * .6
    S["brew"] = norm(lp(noise(.9), 900) * env(int(.9 * SR), .2, .3, .5, .3) + tone(sweep(200, 420, .9), .9, "sine", .1, .3, .4, .3) * .4, .6)
    S["potion_done"] = reverb_small(np.concatenate([tone(midi(m), .22, "sine", .003, .2, 0, .1) for m in (67, 71, 74, 79)]))
    S["coin"] = np.concatenate([tone(midi(88), .05, "sine", .001, .05, 0, .01), tone(midi(95), .18, "sine", .001, .17, 0, .06)]) * .6
    S["pickup"] = tone(sweep(900, 1500, .08), .08, "sine", .002, .07, 0, .02) * .5
    S["heal"] = norm(sum(tone(midi(m), .5, "sine", .02, .4, .2, .2) for m in (72, 76, 79)), .6)
    S["levelup"] = reverb_small(np.concatenate([tone(midi(m), .12, "tri", .003, .12, .3, .05) for m in (64, 67, 71, 76, 79, 83)]) * .8)
    S["gate_open"] = reverb_small(norm(tone(midi(40), 1.4, "saw", .05, .5, .5, .6) * .5 + sum(tone(midi(m), 1.4, "sine", .1, .4, .5, .6) * .3 for m in (64, 71, 76)), .8))
    S["dash"] = norm(bp(noise(.22), 500, 5000) * np.hanning(int(.22 * SR)), .6)
    S["hit"] = norm(lp(noise(.08), 2500) * env(int(.08 * SR), .001, .07, 0, .01) + tone(sweep(220, 90, .08), .08, "sine", .001, .07, 0, .01) * .8, .6)
    S["hit_crit"] = norm(padd(S["hit"], tone(sweep(900, 400, .14), .14, "saw", .001, .13, 0, .02) * .35), .75)
    S["enemy_die"] = norm(lp(noise(.3), 1800) * env(int(.3 * SR), .002, .28, 0, .02) + tone(sweep(260, 60, .3), .3, "sine", .001, .29, 0, .02) * .7, .65)
    S["player_hurt"] = norm(tone(sweep(300, 110, .25), .25, "saw", .002, .22, 0, .03) * .5 + lp(noise(.25), 900) * env(int(.25 * SR), .001, .24, 0, .01) * .6, .75)
    S["death"] = reverb_small(norm(tone(sweep(260, 40, 1.4), 1.4, "saw", .01, .8, .1, .5) * .6 + lp(noise(1.4), 600) * env(int(1.4 * SR), .02, .9, .1, .4) * .5, .85), .5)
    S["victory"] = reverb_small(np.concatenate([tone(midi(m), .2, "tri", .004, .18, .4, .1) for m in (60, 64, 67, 72)] + [sum(tone(midi(m), 1.2, "tri", .01, .5, .4, .6) for m in (60, 64, 67, 72))]) * .6)
    S["shoot_ember"] = norm(bp(noise(.18), 800, 4000) * env(int(.18 * SR), .005, .17, 0, .01) + tone(sweep(700, 300, .18), .18, "saw", .002, .17, 0, .01) * .3, .5)
    S["shoot_sigil"] = norm(tone(sweep(1200, 1800, .14), .14, "fm", .003, .13, 0, .02) * .6, .5)
    S["shoot_shard"] = norm(tone(sweep(2000, 900, .12), .12, "tri", .002, .11, 0, .02) + hp(noise(.12), 4000) * .3 * env(int(.12 * SR), .001, .11, 0, .01), .5)
    S["cast_pulse"] = norm(lp(noise(.5), 1500) * env(int(.5 * SR), .02, .3, .2, .2) + tone(sweep(120, 60, .5), .5, "sine", .005, .4, .2, .1), .7)
    S["cast_aura"] = norm(tone(midi(48), .4, "saw", .02, .2, .3, .2) * .4 + lp(noise(.4), 800) * .4 * env(int(.4 * SR), .05, .2, .3, .15), .5)
    S["chain_zap"] = norm(hp(noise(.2), 1500) * env(int(.2 * SR), .001, .19, 0, .01) * (np.sin(2 * np.pi * 90 * t_(.2)) > 0) + tone(sweep(1800, 400, .2), .2, "square", .001, .19, 0, .01) * .2, .55)
    S["orbit_hum"] = tone(midi(52), .4, "tri", .1, .1, .5, .15) * .3
    S["charm_use"] = reverb_small(norm(tone(midi(55), .8, "fm", .02, .3, .4, .4) + hp(noise(.8), 3000) * env(int(.8 * SR), .01, .5, 0, .3) * .3, .8))
    S["wake"] = norm(lp(noise(1.0), 400) * np.hanning(int(1.0 * SR)) * .7 + tone(midi(34), 1.0, "saw", .3, .3, .5, .4) * .4, .75)
    S["boss_appear"] = reverb_small(norm(tone(midi(28), 2.4, "saw", .3, .8, .6, 1.0) * .6 + tone(midi(34), 2.4, "saw", .5, .8, .5, 1.0) * .4 + lp(noise(2.4), 300) * np.hanning(int(2.4 * SR)) * .6, .9), 1.0)
    S["boss_hit"] = norm(padd(tone(sweep(150, 45, .35), .35, "sine", .001, .3, 0, .05), lp(noise(.2), 900) * env(int(.2 * SR), .001, .2, 0, .01) * .5), .85)
    S["telegraph"] = norm(tone(sweep(200, 900, .7), .7, "saw", .05, .4, .4, .1) * .35, .5)
    S["fate_reroll"] = np.concatenate([tone(midi(m), .06, "square", .001, .06, 0, .01) for m in (72, 79, 84)]) * .35
    S["lantern"] = norm(tone(midi(84), .6, "sine", .002, .4, .1, .3) * .5 + tone(midi(91), .6, "sine", .002, .3, .1, .3) * .25, .5)
    for k, v in S.items():
        save_wav(os.path.join(d, k + ".wav"), norm(np.asarray(v), .85))
    print("sfx:", len(S))

def padd(a, b):
    n = max(len(a), len(b)); o = np.zeros(n); o[:len(a)] += a; o[:len(b)] += b; return o

def reverb_small(x, wet=.3):
    y, n = reverb(np.asarray(x), .9, wet)
    out = np.zeros(len(y)); out[:len(x)] += x; out += y * wet
    return out

# ───────── MUSIC ─────────
def pad(freqs, dur, vol=.2, bright=1500, kind="saw"):
    n = int(dur * SR); sig = np.zeros(n)
    for f in freqs:
        for det in (-.004, 0, .004):
            sig += osc(f, dur, kind, det)
    sig = lp(sig, bright, 2) * vol / max(1, len(freqs))
    return sig * env(n, min(.8, dur / 3), 0, 1, min(1.2, dur / 3))

def bell(f, dur=1.6, vol=.3):
    t = t_(dur); sig = np.zeros_like(t)
    for mult, a in ((1, 1), (2.01, .5), (2.76, .35), (4.07, .2), (5.4, .12)):
        sig += a * np.sin(2 * np.pi * f * mult * t) * np.exp(-t * (2.2 + mult * .6))
    return sig * vol * np.minimum(1, t / .002)

def pluck(f, dur=.7, vol=.3):
    t = t_(dur); sig = (np.sin(2 * np.pi * f * t) + .4 * np.sin(2 * np.pi * f * 2 * t)) * np.exp(-t * 7); return sig * vol

def kick(vol=.8):
    n = int(.3 * SR); f = sweep(130, 38, .3, .35); return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-np.linspace(0, 9, n)) * vol

def drum(vol=.6, lowpass=500):
    n = int(.5 * SR); return lp(noise(.5), lowpass) * np.exp(-np.linspace(0, 8, n)) * vol + np.sin(2 * np.pi * np.cumsum(sweep(90, 50, .5, .4)) / SR) * np.exp(-np.linspace(0, 6, n)) * vol * .8

def hat(vol=.2):
    n = int(.08 * SR); return hp(noise(.08), 6000) * np.exp(-np.linspace(0, 10, n)) * vol

def whisper(dur, vol=.15):
    n = noise(dur); f = bp(n, 1800, 5200) + bp(n, 600, 900) * .5
    return f * np.hanning(len(f)) * vol * (1 + .5 * np.sin(2 * np.pi * 6 * t_(dur)))

def compose(name, bpm, bars, beats_per_bar, build):
    spb = 60.0 / bpm; total = bars * beats_per_bar * spb
    L = int(total * SR); l = np.zeros(L + int(4 * SR)); r = np.zeros_like(l)
    build(l, r, spb, bars, beats_per_bar)
    st = finish_loop(l[:L + 4 * SR][:L + int(4 * SR)], r[:L + int(4 * SR)], L)
    save_ogg(os.path.join(OUT, "music", name + ".ogg"), st)
    print("music:", name, round(total, 1), "s")

def both(l, r, snd, at, pan=0.0):
    place(l, snd * (1 - max(0, pan)), at); place(r, snd * (1 + min(0, pan)), at)

def music():
    # 1 — Study: warm, slow, music-box arpeggio over D-minor drone. 60 BPM, 16 bars of 4.
    def study(l, r, spb, bars, bpb):
        prog = [(38, [50, 57, 62, 65]), (34, [46, 53, 58, 62]), (31, [43, 50, 55, 58]), (33, [45, 52, 57, 60])]
        arp = [0, 2, 3, 2, 1, 2, 3, 2]
        for bar in range(bars):
            root, ch = prog[(bar // 2) % 4]; at = bar * bpb * spb
            both(l, r, pad([midi(m) for m in ch], bpb * spb * 1.05, .22, 1100, "saw"), at, 0)
            both(l, r, pad([midi(root)], bpb * spb * 1.05, .3, 300, "sine"), at)
            for i in range(8):
                m = ch[arp[i]] + 12 + (12 if i % 4 == 3 else 0)
                both(l, r, pluck(midi(m), .8, .16), at + i * spb / 2, -.4 + .8 * (i % 2))
            if bar % 4 == 3: both(l, r, bell(midi(ch[3] + 24), 3.0, .2), at + 2 * spb, .2)
            if bar % 8 == 0: both(l, r, whisper(bpb * spb, .06), at, 0)
    compose("study_theme", 60, 16, 4, study)

    # 2 — Red Priest run: driving war drums, low saw ostinato, bell fanfare. 96 BPM, E phrygian
    def red(l, r, spb, bars, bpb):
        roots = [40, 40, 41, 40, 43, 41, 40, 38]
        for bar in range(bars):
            at = bar * bpb * spb; root = roots[bar % 8]
            for b in range(bpb):
                both(l, r, kick(.7), at + b * spb)
                if b in (1, 3): both(l, r, drum(.35, 1800), at + b * spb)
                for h in (0, .5): both(l, r, hat(.12), at + (b + h) * spb, .3)
            for i in range(8):
                note = root + (0, 0, 12, 0, 7, 0, 5, 0)[i] if i % 2 == 0 else root
                snd = lp(osc(midi(note), spb / 2 * .95, "saw") * env(int(spb / 2 * .95 * SR), .004, .1, .5, .05), 900 + 600 * ((bar % 4) / 3)) * .22
                both(l, r, snd, at + i * spb / 2)
            both(l, r, pad([midi(root + 12), midi(root + 19), midi(root + 24)], bpb * spb, .18, 1600), at)
            if bar % 4 == 0:
                for k, m in enumerate((64, 65, 67, 64)): both(l, r, bell(midi(m + 12), 1.4, .22), at + k * spb, -.3 + k * .2)
    compose("run_dawnbringer", 96, 16, 4, red)

    # 3 — Hermit run: mysterious 6/8 arpeggios, glassy bells, slow pads. 78 BPM, F# dorian-ish
    def hermit(l, r, spb, bars, bpb):
        roots = [42, 45, 40, 47]
        scale = [0, 2, 3, 5, 7, 9, 10]
        for bar in range(bars):
            at = bar * bpb * spb; root = roots[(bar // 2) % 4]
            both(l, r, pad([midi(root + 12), midi(root + 19), midi(root + 22)], bpb * spb * 1.05, .22, 1800, "tri"), at)
            both(l, r, pad([midi(root)], bpb * spb * 1.05, .28, 260, "sine"), at)
            for i in range(6):
                deg = scale[(i * 2 + bar) % 7]
                both(l, r, bell(midi(root + 24 + deg), 1.8, .15), at + i * spb * .5, -.5 + i * .2)
            if bar % 2 == 0: both(l, r, kick(.35), at); both(l, r, drum(.2, 300), at + 3 * spb * .5 * 3 / 3)
    compose("run_wanderer", 78, 16, 3, hermit)

    # 4 — Demoness run: slow, detuned, dissonant pads, whispers, sparse sub pulses. 66 BPM, C# phrygian
    def demon(l, r, spb, bars, bpb):
        roots = [37, 38, 37, 40]
        for bar in range(bars):
            at = bar * bpb * spb; root = roots[(bar // 2) % 4]
            both(l, r, pad([midi(root + 12), midi(root + 13), midi(root + 18)], bpb * spb * 1.05, .22, 1300, "saw"), at)
            both(l, r, pad([midi(root)], bpb * spb * 1.05, .34, 200, "sine"), at)
            both(l, r, whisper(spb * 2.2, .08), at + spb * (bar % 3), -.7 if bar % 2 else .7)
            both(l, r, kick(.45), at); 
            if bar % 2 == 1: both(l, r, kick(.3), at + 2.5 * spb)
            for i, m in enumerate((root + 36, root + 39, root + 43)):
                if (bar + i) % 3 == 0: both(l, r, bell(midi(m), 2.4, .12), at + (i + 1) * spb * .75, .6 - i * .5)
    compose("run_hollow_seer", 66, 16, 4, demon)

    # 5 — Boss: 120 BPM, heavy, tritone stabs
    def boss(l, r, spb, bars, bpb):
        for bar in range(bars):
            at = bar * bpb * spb; root = 33 if bar % 4 < 2 else 36
            for b in range(bpb):
                both(l, r, kick(.9), at + b * spb)
                both(l, r, hat(.18), at + (b + .5) * spb, .4)
                if b in (1, 3): both(l, r, drum(.5, 2200), at + b * spb)
            for i in range(8):
                n = root + (0, 0, 6, 0, 7, 0, 6, 0)[i]
                snd = lp(osc(midi(n), spb / 2 * .9, "saw") * env(int(spb / 2 * .9 * SR), .003, .08, .6, .04), 1500) * .26
                both(l, r, snd, at + i * spb / 2)
            both(l, r, pad([midi(root + 24), midi(root + 30), midi(root + 31)], bpb * spb, .2, 2200), at)
            if bar % 4 == 3:
                for k in range(4): both(l, r, drum(.45, 900), at + (2 + k * .5) * spb)
    compose("boss_theme", 120, 16, 4, boss)

    # 6 — Title/menu sting + game-over / victory stingers are in sfx; ambience below
def ambience():
    d = os.path.join(OUT, "ambience")
    def loopify(x):
        n = len(x); fade = int(1.5 * SR); y = x[:n - fade].copy()
        y[:fade] = y[:fade] * np.linspace(0, 1, fade) + x[n - fade:] * np.linspace(1, 0, fade); return y
    def mk(name, fn, dur=10):
        sig = fn(dur + 1.5); sig = loopify(sig); sig = norm(sig, .7); save_ogg(os.path.join(d, name + ".ogg"), np.stack([sig, np.roll(sig, int(.013 * SR))], 1))
    def cinder(dur): n = noise(dur); return lp(n, 500) * (.5 + .5 * np.sin(2 * np.pi * .13 * t_(dur))) + hp(noise(dur), 5000) * .02 * (rng.random(int(dur * SR)) > .995).astype(float).cumsum() % 1
    def drowned(dur): n = lp(noise(dur), 260); return n * (.6 + .4 * np.sin(2 * np.pi * .2 * t_(dur))) + osc(midi(36), dur, "sine") * .15
    def salt(dur): return hp(lp(noise(dur), 6000), 2500) * .35 * (.5 + .5 * np.sin(2 * np.pi * .3 * t_(dur))) + osc(midi(52), dur, "tri") * .06
    def glass(dur): return sum(osc(midi(m), dur, "sine") * (.3 + .3 * np.sin(2 * np.pi * (.1 + i * .07) * t_(dur))) for i, m in enumerate((84, 88, 91, 95))) * .12
    def orchard(dur): return bp(noise(dur), 300, 1200) * (.4 + .4 * np.sin(2 * np.pi * .17 * t_(dur))) + osc(midi(43), dur, "sine") * .12
    def lantern(dur): return lp(noise(dur), 200) * .4 + osc(midi(31), dur, "sine", .002) * .25 + osc(midi(31.1), dur, "sine") * .2
    for n, f in (("cinder_wold", cinder), ("drowned_stair", drowned), ("salt_seminary", salt), ("glass_verge", glass), ("slow_orchard", orchard), ("lantern_field", lantern)):
        mk(n, f)
    print("ambience: 6")

if __name__ == "__main__":
    sfx(); music(); ambience(); print("audio done")
