/* ─── Prompt Architect — prompt-builder.js ─────────────── */
'use strict';

/* ── Model Pricing (June 2026, per million tokens) ─────── */
const MODELS = {
  haiku: {
    label:     'Claude Haiku 4.5',
    inputPPM:  1.00,
    outputPPM: 5.00,
    useCase:   'High-volume, fast tasks',
    batchDiscount: 0.50
  },
  sonnet: {
    label:     'Claude Sonnet 4.6',
    inputPPM:  3.00,
    outputPPM: 15.00,
    useCase:   'Balanced quality + speed',
    batchDiscount: 0.50
  },
  opus: {
    label:     'Claude Opus 4.8',
    inputPPM:  5.00,
    outputPPM: 25.00,
    useCase:   'Complex reasoning & analysis',
    batchDiscount: 0.50
  }
};

const VOLUME_STEPS = [100, 1000, 5000, 10000, 50000, 100000];

/* ── Rough token estimator (word-count based heuristic) ── */
function estimateTokens(text) {
  if (!text || !text.trim()) return 0;
  const words = text.trim().split(/\s+/).length;
  return Math.round(words * 1.35);
}

/* ── State ──────────────────────────────────────────────── */
const state = {
  currentStep: 0,
  selectedModel: 'haiku',
  fields: {
    personaRole:       '',
    personaExperience: '',
    personaTraits:     '',
    ctxBackground:     '',
    ctxAudience:       '',
    ctxConstraints:    '',
    taskVerb:          '',
    taskDeliverable:   '',
    taskGoal:          '',
    permUnknown:       '',
    permExtra:         '',
    fmtType:           '',
    fmtLength:         '',
    fmtExtra:          ''
  }
};

/* ── DOM References ─────────────────────────────────────── */
const $ = id => document.getElementById(id);
const $$ = sel => document.querySelectorAll(sel);

const elStepCards   = $$('.step-card');
const elStepPills   = $$('.step-pill');
const elLivePrompt  = $('live-prompt-text');
const elTokenCount  = $('token-count');
const elMeterBar    = $('meter-bar');
const elMeterScore  = $('meter-score');
const elMeterDots   = $$('.meter-dot');
const elMeterItems  = $$('.meter-item');
const elPromptOut   = $('prompt-output');
const elQualBadge   = $('quality-badge');
const elToast       = $('toast');

const elCostInputTokens  = $('cost-input-tokens');
const elCostOutputTokens = $('cost-output-tokens');
const elCostInputVal     = $('cost-input-val');
const elCostOutputVal    = $('cost-output-val');
const elCostTotal        = $('cost-total');
const elMonthlyTotal     = $('monthly-total');
const elVolumeSlider     = $('volume-slider');
const elVolumeLabel      = $('volume-label');
const elSpecInputRate    = $('spec-input-rate');
const elSpecOutputRate   = $('spec-output-rate');
const elSpecUseCase      = $('spec-use-case');

/* ── Navigation ─────────────────────────────────────────── */
const STEP_COLORS = ['#6d5ef5','#0ea8d5','#e8590c','#d42e8c','#1db870','#6d5ef5'];
const STEP_LIGHTS = ['#edeaff','#e0f6fd','#fff0e8','#fde8f4','#e4f9ed','#edeaff'];
const STEP_MIDS   = ['#bdb5fb','#87d9ee','#f7b98a','#f09fd1','#78d9a4','#bdb5fb'];

function goToStep(n) {
  state.currentStep = Math.max(0, Math.min(5, n));

  elStepCards.forEach((card, i) => {
    card.classList.toggle('active', i === state.currentStep);
  });

  elStepPills.forEach((pill, i) => {
    pill.classList.remove('active', 'complete');
    if (i === state.currentStep) pill.classList.add('active');
    else if (i < state.currentStep) pill.classList.add('complete');
  });

  // Sync right-panel accent color to active step
  const root = document.documentElement;
  root.style.setProperty('--step-color', STEP_COLORS[state.currentStep]);
  root.style.setProperty('--step-light', STEP_LIGHTS[state.currentStep]);
  root.style.setProperty('--step-mid',   STEP_MIDS[state.currentStep]);

  if (state.currentStep === 5) rebuildFinalPrompt();
}

document.addEventListener('click', function(e) {
  // Step nav pills
  const pill = e.target.closest('.step-pill');
  if (pill) {
    goToStep(parseInt(pill.dataset.step, 10));
    return;
  }
  // Next buttons
  const next = e.target.closest('[data-next]');
  if (next) {
    goToStep(parseInt(next.dataset.next, 10));
    return;
  }
  // Back buttons
  const back = e.target.closest('[data-back]');
  if (back) {
    goToStep(parseInt(back.dataset.back, 10));
    return;
  }
  // Copy button
  if (e.target.closest('#btn-copy')) {
    copyPrompt();
    return;
  }
  // Reset button
  if (e.target.closest('#btn-reset')) {
    resetAll();
    return;
  }
  // Model tabs
  const tab = e.target.closest('.model-tab');
  if (tab) {
    $$('.model-tab').forEach(t => {
      t.classList.remove('active');
      t.setAttribute('aria-selected', 'false');
    });
    tab.classList.add('active');
    tab.setAttribute('aria-selected', 'true');
    state.selectedModel = tab.dataset.model;
    updateCostEstimator();
    return;
  }
});

/* ── Field Binding ──────────────────────────────────────── */
function bindField(elId, stateKey) {
  const el = $(elId);
  if (!el) return;
  el.addEventListener('input', () => {
    state.fields[stateKey] = el.value.trim();
    onFieldChange();
  });
  el.addEventListener('change', () => {
    state.fields[stateKey] = el.value.trim();
    onFieldChange();
  });
}

bindField('persona-role',       'personaRole');
bindField('persona-experience', 'personaExperience');
bindField('persona-traits',     'personaTraits');
bindField('ctx-background',     'ctxBackground');
bindField('ctx-audience',       'ctxAudience');
bindField('ctx-constraints',    'ctxConstraints');
bindField('task-verb',          'taskVerb');
bindField('task-deliverable',   'taskDeliverable');
bindField('task-goal',          'taskGoal');
bindField('perm-extra',         'permExtra');
bindField('fmt-type',           'fmtType');
bindField('fmt-length',         'fmtLength');
bindField('fmt-extra',          'fmtExtra');

// Radio buttons for permission
document.addEventListener('change', function(e) {
  if (e.target.name === 'perm-unknown') {
    state.fields.permUnknown = e.target.value;
    onFieldChange();
  }
});

/* ── Prompt Assembly ────────────────────────────────────── */
function buildPrompt() {
  const f = state.fields;
  const parts = [];

  // Persona
  if (f.personaRole) {
    let persona = `You are ${f.personaExperience ? f.personaExperience + ' ' : ''}${f.personaRole}.`;
    if (f.personaTraits) {
      persona += ` You are ${f.personaTraits}.`;
    }
    parts.push(`## Persona\n${persona}`);
  }

  // Context
  const ctxLines = [];
  if (f.ctxBackground) ctxLines.push(f.ctxBackground);
  if (f.ctxAudience)   ctxLines.push(`The intended audience is: ${f.ctxAudience}.`);
  if (f.ctxConstraints) ctxLines.push(`Constraints: ${f.ctxConstraints}.`);
  if (ctxLines.length) parts.push(`## Context\n${ctxLines.join('\n')}`);

  // Task
  const taskLines = [];
  if (f.taskVerb && f.taskDeliverable) {
    taskLines.push(`${f.taskVerb} ${f.taskDeliverable}.`);
  } else if (f.taskDeliverable) {
    taskLines.push(f.taskDeliverable);
  }
  if (f.taskGoal) taskLines.push(`Goal: ${f.taskGoal}.`);
  if (taskLines.length) parts.push(`## Task\n${taskLines.join('\n')}`);

  // Permission
  const permLines = [];
  if (f.permUnknown) permLines.push(`If you don't know something or are uncertain: ${f.permUnknown}.`);
  if (f.permExtra)   permLines.push(f.permExtra);
  if (permLines.length) parts.push(`## Permission & Limits\n${permLines.join('\n')}`);

  // Format
  const fmtLines = [];
  if (f.fmtType)   fmtLines.push(f.fmtType + '.');
  if (f.fmtLength) fmtLines.push(f.fmtLength + '.');
  if (f.fmtExtra)  fmtLines.push(f.fmtExtra);
  if (fmtLines.length) parts.push(`## Output Format\n${fmtLines.join('\n')}`);

  return parts.join('\n\n');
}

function getSectionFill() {
  const f = state.fields;
  return {
    persona:    !!(f.personaRole),
    context:    !!(f.ctxBackground),
    task:       !!(f.taskVerb && f.taskDeliverable),
    permission: !!(f.permUnknown),
    format:     !!(f.fmtType)
  };
}

/* ── Live Updates ───────────────────────────────────────── */
function onFieldChange() {
  updatePersonaPreview();
  updateLivePrompt();
  updateMeter();
  updateCostEstimator();
}

function updatePersonaPreview() {
  const f = state.fields;
  const el = $('persona-preview-text');
  if (!el) return;
  if (!f.personaRole) {
    el.textContent = 'Fill in the fields above to see your persona take shape.';
    return;
  }
  let text = `You are ${f.personaExperience ? f.personaExperience + ' ' : ''}${f.personaRole}.`;
  if (f.personaTraits) text += ` You are ${f.personaTraits}.`;
  el.textContent = text;
}

function updateLivePrompt() {
  const prompt = buildPrompt();
  const tokens = estimateTokens(prompt);

  elLivePrompt.textContent = prompt || 'Start filling in the steps on the left to see your prompt build here in real time.';
  elTokenCount.textContent = tokens.toLocaleString();
}

function updateMeter() {
  const fill = getSectionFill();
  const sections = ['persona', 'context', 'task', 'permission', 'format'];
  let complete = 0;

  elMeterItems.forEach((item, i) => {
    const key = sections[i];
    const dot = item.querySelector('.meter-dot');
    if (fill[key]) {
      dot.className = 'meter-dot complete';
      complete++;
    } else {
      dot.className = 'meter-dot empty';
    }
  });

  const pct = (complete / 5) * 100;
  elMeterBar.style.width = pct + '%';
  elMeterScore.textContent = `${complete} / 5 sections complete`;
}

/* ── Final Prompt (Step 5) ──────────────────────────────── */
function rebuildFinalPrompt() {
  const prompt = buildPrompt();
  const fill = getSectionFill();
  const filled = Object.values(fill).filter(Boolean).length;

  elPromptOut.textContent = prompt || '(No content yet — go back and fill in at least one section.)';

  let quality, cls;
  if (filled === 5)        { quality = 'Excellent prompt'; cls = 'q-excellent'; }
  else if (filled >= 3)    { quality = 'Good prompt';      cls = 'q-good'; }
  else if (filled >= 1)    { quality = 'Basic prompt';     cls = 'q-basic'; }
  else                     { quality = 'Empty';            cls = ''; }

  elQualBadge.textContent = quality;
  elQualBadge.className = 'prompt-quality ' + cls;
}

/* ── Cost Estimator ─────────────────────────────────────── */
function updateCostEstimator() {
  const prompt    = buildPrompt();
  const inputTok  = estimateTokens(prompt);
  const outputTok = 300; // assumed medium response
  const model     = MODELS[state.selectedModel];

  const inputCost  = (inputTok  / 1_000_000) * model.inputPPM;
  const outputCost = (outputTok / 1_000_000) * model.outputPPM;
  const totalCost  = inputCost + outputCost;

  const volIdx     = parseInt(elVolumeSlider.value, 10);
  const volume     = VOLUME_STEPS[volIdx];
  const monthlyCost = totalCost * volume;

  elCostInputTokens.textContent  = inputTok.toLocaleString();
  elCostOutputTokens.textContent = '~' + outputTok.toLocaleString();
  elCostInputVal.textContent     = '$' + inputCost.toFixed(6);
  elCostOutputVal.textContent    = '$' + outputCost.toFixed(6);
  elCostTotal.textContent        = '$' + totalCost.toFixed(6);
  elVolumeLabel.textContent      = volume.toLocaleString() + ' calls/mo';
  elMonthlyTotal.textContent     = '$' + formatMoney(monthlyCost);
  elSpecInputRate.textContent    = '$' + model.inputPPM.toFixed(2) + ' / MTok';
  elSpecOutputRate.textContent   = '$' + model.outputPPM.toFixed(2) + ' / MTok';
  elSpecUseCase.textContent      = model.useCase;
}

function formatMoney(n) {
  if (n < 0.01)   return n.toFixed(6);
  if (n < 1)      return n.toFixed(4);
  if (n < 100)    return n.toFixed(2);
  return n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

elVolumeSlider.addEventListener('input', updateCostEstimator);

/* ── Copy & Reset ───────────────────────────────────────── */
function copyPrompt() {
  const text = buildPrompt();
  if (!text) { showToast('Nothing to copy yet.'); return; }
  navigator.clipboard.writeText(text).then(() => {
    showToast('Prompt copied to clipboard ✓');
  }).catch(() => {
    // fallback
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
    showToast('Prompt copied ✓');
  });
}

function resetAll() {
  // Clear all inputs
  $$('input[type="text"]').forEach(el => { el.value = ''; });
  $$('textarea').forEach(el => { el.value = ''; });
  $$('select').forEach(el => { el.selectedIndex = 0; });
  $$('input[type="radio"]').forEach(el => { el.checked = false; });

  // Reset state
  Object.keys(state.fields).forEach(k => { state.fields[k] = ''; });
  state.currentStep = 0;

  onFieldChange();
  goToStep(0);
  showToast('Prompt cleared — start fresh.');
}

/* ── Toast ──────────────────────────────────────────────── */
let toastTimer = null;
function showToast(msg) {
  elToast.textContent = msg;
  elToast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => elToast.classList.remove('show'), 2500);
}

/* ── Init ───────────────────────────────────────────────── */
(function init() {
  updateCostEstimator();
  updateMeter();
})();

/* ══════════════════════════════════════════════════════════
   PERSONA LOADER
   ══════════════════════════════════════════════════════════ */

const elDropZone      = document.getElementById('persona-drop-zone');
const elFileInput     = document.getElementById('persona-file-input');
const elLoadedDisplay = document.getElementById('loaded-persona-display');
const elLoadError     = document.getElementById('persona-load-error');
const elLoadedIcon    = document.getElementById('loaded-persona-icon');
const elLoadedName    = document.getElementById('loaded-persona-name');
const elLoadedVersion = document.getElementById('loaded-persona-version');
const elLoadedDesc    = document.getElementById('loaded-persona-desc');
const elLoadedTags    = document.getElementById('loaded-persona-tags');

/* ── Allowed values (must match HTML exactly) ─────────────── */
const VALID_EXPERIENCE = ['a junior','a mid-level','a senior','a world-class expert',''];
const VALID_VERBS      = ['Write','Analyze','Summarize','Review','Generate','Compare','Explain','Create','Debug','Translate','Rewrite','List',''];
const VALID_ON_UNKNOWN = [
  "Say 'I don't know' clearly rather than guessing",
  "Ask a clarifying question before proceeding",
  "Make a clearly labelled assumption and continue",
  "Provide a best-effort answer with a confidence caveat",
  ""
];
const VALID_FMT_TYPE = [
  "Respond in plain prose paragraphs",
  "Use markdown with headers and bullet points",
  "Return a numbered list",
  "Return a markdown table",
  "Return valid JSON only, no prose",
  "Use code blocks with explanations below each",
  "Use a step-by-step numbered format",
  "Write in Q&A format",
  ""
];
const VALID_FMT_LENGTH = [
  "Be concise — aim for under 150 words",
  "Aim for 250–400 words",
  "Be thorough — 500–800 words is acceptable",
  "Be exhaustive and comprehensive — length is not a concern",
  ""
];

/* ── Validation ───────────────────────────────────────────── */
function validatePersona(data) {
  const errors = [];
  if (typeof data !== 'object' || data === null) {
    errors.push('File must contain a JSON object.');
    return errors;
  }
  if (!data.meta || typeof data.meta.name !== 'string' || !data.meta.name.trim())
    errors.push('Missing required field: meta.name');
  if (!data.meta || typeof data.meta.description !== 'string')
    errors.push('Missing required field: meta.description');
  if (!data.persona || typeof data.persona.role !== 'string' || !data.persona.role.trim())
    errors.push('Missing required field: persona.role');
  if (data.persona && data.persona.experience !== undefined && !VALID_EXPERIENCE.includes(data.persona.experience))
    errors.push('persona.experience must be one of: ' + VALID_EXPERIENCE.filter(Boolean).join(', '));
  if (data.task && data.task.verb !== undefined && !VALID_VERBS.includes(data.task.verb))
    errors.push('task.verb must be one of: ' + VALID_VERBS.filter(Boolean).join(', '));
  if (data.permission && data.permission.onUnknown !== undefined && !VALID_ON_UNKNOWN.includes(data.permission.onUnknown))
    errors.push('permission.onUnknown does not match any allowed value — see persona-schema.json.');
  if (data.format && data.format.type !== undefined && !VALID_FMT_TYPE.includes(data.format.type))
    errors.push('format.type does not match any allowed value — see persona-schema.json.');
  if (data.format && data.format.length !== undefined && !VALID_FMT_LENGTH.includes(data.format.length))
    errors.push('format.length does not match any allowed value — see persona-schema.json.');
  return errors;
}

/* ── Form hydration ───────────────────────────────────────── */
function setSelectValue(elId, value) {
  const el = document.getElementById(elId);
  if (!el || value === undefined || value === null) return;
  for (let i = 0; i < el.options.length; i++) {
    if (el.options[i].value === value) { el.selectedIndex = i; return; }
  }
}

function setRadioValue(name, value) {
  if (!value) return;
  document.querySelectorAll('input[name="' + name + '"]').forEach(r => {
    r.checked = (r.value === value);
  });
}

function setInputValue(elId, value) {
  const el = document.getElementById(elId);
  if (el && value !== undefined && value !== null) el.value = value;
}

function hydrateFormFromPersona(data) {
  const p  = data.persona    || {};
  const c  = data.context    || {};
  const t  = data.task       || {};
  const pm = data.permission || {};
  const f  = data.format     || {};

  setInputValue('persona-role',       p.role);
  setSelectValue('persona-experience', p.experience);
  setInputValue('persona-traits',     p.traits);

  setInputValue('ctx-background',  c.background);
  setInputValue('ctx-audience',    c.audience);
  setInputValue('ctx-constraints', c.constraints);

  setSelectValue('task-verb',       t.verb);
  setInputValue('task-deliverable', t.deliverable);
  setInputValue('task-goal',        t.goal);

  setRadioValue('perm-unknown', pm.onUnknown);
  setInputValue('perm-extra',   pm.extra);

  setSelectValue('fmt-type',   f.type);
  setSelectValue('fmt-length', f.length);
  setInputValue('fmt-extra',   f.extra);

  state.fields.personaRole       = p.role        || '';
  state.fields.personaExperience = p.experience  || '';
  state.fields.personaTraits     = p.traits      || '';
  state.fields.ctxBackground     = c.background  || '';
  state.fields.ctxAudience       = c.audience    || '';
  state.fields.ctxConstraints    = c.constraints || '';
  state.fields.taskVerb          = t.verb        || '';
  state.fields.taskDeliverable   = t.deliverable || '';
  state.fields.taskGoal          = t.goal        || '';
  state.fields.permUnknown       = pm.onUnknown  || '';
  state.fields.permExtra         = pm.extra      || '';
  state.fields.fmtType           = f.type        || '';
  state.fields.fmtLength         = f.length      || '';
  state.fields.fmtExtra          = f.extra       || '';
}

/* ── UI: show loaded card ─────────────────────────────────── */
function showLoadedPersona(data) {
  const meta     = data.meta || {};
  const initials = (meta.name || 'P').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();

  elLoadedIcon.textContent    = initials;
  elLoadedName.textContent    = meta.name        || 'Unnamed Persona';
  elLoadedVersion.textContent = meta.version ? 'v' + meta.version : '';
  elLoadedDesc.textContent    = meta.description || '';

  elLoadedTags.innerHTML = '';
  (meta.tags || []).forEach(function(tag) {
    const span = document.createElement('span');
    span.className   = 'persona-tag';
    span.textContent = tag;
    elLoadedTags.appendChild(span);
  });

  elLoadedDisplay.style.display = 'block';
  elDropZone.style.display      = 'none';
  elLoadError.style.display     = 'none';
}

function showPersonaError(messages) {
  elLoadError.innerHTML     = '<strong>Could not load persona:</strong><br>' + messages.map(m => '&#8226; ' + m).join('<br>');
  elLoadError.style.display = 'block';
}

function clearLoadedPersona() {
  elLoadedDisplay.style.display = 'none';
  elDropZone.style.display      = 'block';
  elLoadError.style.display     = 'none';
  elFileInput.value             = '';
}

/* ── File reader ──────────────────────────────────────────── */
function readPersonaFile(file) {
  if (!file || !file.name.toLowerCase().endsWith('.json')) {
    showPersonaError(['File must be a .json file.']);
    return;
  }
  const reader = new FileReader();
  reader.addEventListener('load', function(ev) {
    let data;
    try {
      data = JSON.parse(ev.target.result);
    } catch (err) {
      showPersonaError(['Invalid JSON: ' + err.message]);
      return;
    }
    const errors = validatePersona(data);
    if (errors.length > 0) { showPersonaError(errors); return; }

    hydrateFormFromPersona(data);
    showLoadedPersona(data);
    onFieldChange();
    showToast('Persona loaded: ' + data.meta.name);
  });
  reader.addEventListener('error', function() {
    showPersonaError(['Failed to read file. Please try again.']);
  });
  reader.readAsText(file);
}

/* ── Drop zone events ─────────────────────────────────────── */
elDropZone.addEventListener('click', function() { elFileInput.click(); });

elDropZone.addEventListener('keydown', function(e) {
  if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); elFileInput.click(); }
});

elFileInput.addEventListener('change', function() {
  if (this.files && this.files[0]) readPersonaFile(this.files[0]);
});

elDropZone.addEventListener('dragenter', function(e) {
  e.preventDefault(); elDropZone.classList.add('drag-over');
});
elDropZone.addEventListener('dragover', function(e) {
  e.preventDefault(); elDropZone.classList.add('drag-over');
});
elDropZone.addEventListener('dragleave', function(e) {
  if (!elDropZone.contains(e.relatedTarget)) elDropZone.classList.remove('drag-over');
});
elDropZone.addEventListener('drop', function(e) {
  e.preventDefault();
  elDropZone.classList.remove('drag-over');
  const file = e.dataTransfer && e.dataTransfer.files[0];
  if (file) readPersonaFile(file);
});

/* Hook clear-persona into the existing click delegation */
const _origClickHandler = document.onclick;
document.addEventListener('click', function(e) {
  if (e.target.closest('#btn-clear-persona')) {
    clearLoadedPersona();
    resetAll();
    showToast('Persona removed — fields cleared.');
  }
});
