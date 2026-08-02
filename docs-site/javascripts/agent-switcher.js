/**
 * Home agent switcher + sync-command clipboard helper.
 * Defensive no-op on pages without the home CTA / switcher markup.
 * Re-inits on MkDocs Material instant navigation via document$ when present.
 * Persists last agent id in sessionStorage; syncs aria-expanded on details disclosures.
 * Supports flat options and Default+Others disclosure (details or button+panel).
 */
(function () {
  "use strict";

  var RADIO_NAME = "home-agent";
  var STORAGE_KEY = "adt-home-agent";
  var STATUS_SUCCESS_MS = 2500;
  var STATUS_ERROR_MS = 8000;
  var BASE_SYNC_COMMAND =
    "pwsh -NoProfile -File .\\scripts\\toolkit.ps1 -Action Sync";

  var COPY_SUCCESS_EN = "Copied";
  var COPY_ERROR_EN = "Clipboard denied";
  var COPY_RECOVERY_EN = "Select the command text and copy manually.";
  var COPY_SUCCESS_PT = "Copiado";
  var COPY_ERROR_PT = "Área de transferência negada";
  var COPY_RECOVERY_PT = "Selecione o texto do comando e copie manualmente.";

  var STATE_SUCCESS = "success";
  var STATE_ERROR = "error";
  var CLASS_SUCCESS = "is-success";
  var CLASS_ERROR = "is-error";
  var ATTR_BOUND = "data-agent-switcher-bound";
  var ATTR_DETAILS_BOUND = "data-details-aria-bound";

  var resetTimerId = null;

  function isPortugueseLocale() {
    var lang = (document.documentElement.getAttribute("lang") || "").toLowerCase();
    return lang.indexOf("pt") === 0;
  }

  function copyMessages() {
    if (isPortugueseLocale()) {
      return {
        success: COPY_SUCCESS_PT,
        error: COPY_ERROR_PT,
        recovery: COPY_RECOVERY_PT,
      };
    }
    return {
      success: COPY_SUCCESS_EN,
      error: COPY_ERROR_EN,
      recovery: COPY_RECOVERY_EN,
    };
  }

  function queryHome() {
    var switcher = document.querySelector("[data-agent-switcher], #agent-switcher");
    var commandEl = document.querySelector("[data-sync-command], #sync-command");
    var copyBtn = document.querySelector(
      '[data-copy-target="#sync-command"], #copy-sync-command, .home-cta__copy .home-cta__primary, button.home-cta__primary'
    );
    var statusEl = document.querySelector(
      "[data-copy-status], #copy-sync-status, .home-cta__status"
    );
    var hintEl = document.querySelector(
      "[data-agent-install-hint], #agent-install-hint, .agent-switcher__hint"
    );

    if (!switcher || !commandEl || !copyBtn || !statusEl || !hintEl) {
      return null;
    }

    return {
      switcher: switcher,
      commandEl: commandEl,
      copyBtn: copyBtn,
      statusEl: statusEl,
      hintEl: hintEl,
      copyShell: copyBtn.closest(".home-cta__copy") || copyBtn,
    };
  }

  function radiosIn(switcher) {
    return Array.prototype.slice.call(
      switcher.querySelectorAll('input[type="radio"][name="' + RADIO_NAME + '"]')
    );
  }

  function selectedRadio(switcher) {
    var radios = radiosIn(switcher);
    var checked = radios.filter(function (r) {
      return r.checked;
    })[0];
    if (checked) {
      return checked;
    }

    var defaultId = switcher.getAttribute("data-default-agent");
    if (defaultId) {
      var byDefault = radios.filter(function (r) {
        return r.getAttribute("data-agent-id") === defaultId;
      })[0];
      if (byDefault) {
        return byDefault;
      }
    }

    return radios[0] || null;
  }

  function hintFromRadio(radio) {
    if (!radio) {
      return "";
    }
    var hint = radio.getAttribute("data-install-hint");
    if (hint && hint.trim()) {
      return hint.trim();
    }
    var root = radio.getAttribute("data-install-root");
    if (root && root.trim()) {
      return "Typical live root: " + root.trim();
    }
    return "";
  }

  function syncCommandFor(radio) {
    var agentId = radio && radio.getAttribute("data-agent-id");
    if (agentId && agentId.trim()) {
      return BASE_SYNC_COMMAND + " -Agent " + agentId.trim();
    }
    return BASE_SYNC_COMMAND;
  }

  function applySelection(home, radio) {
    if (!radio) {
      return;
    }
    if (!radio.checked) {
      radio.checked = true;
    }
    var hint = hintFromRadio(radio);
    if (hint) {
      home.hintEl.textContent = hint;
    }
    home.commandEl.textContent = syncCommandFor(radio);
  }

  function readStoredAgentId() {
    try {
      return window.sessionStorage.getItem(STORAGE_KEY);
    } catch (err) {
      return null;
    }
  }

  function writeStoredAgentId(agentId) {
    try {
      if (agentId && agentId.trim()) {
        window.sessionStorage.setItem(STORAGE_KEY, agentId.trim());
      }
    } catch (err) {
      // sessionStorage may throw in private mode; selection still works in-page.
    }
  }

  function summaryOf(details) {
    var child = details.firstElementChild;
    while (child) {
      if (child.tagName === "SUMMARY") {
        return child;
      }
      child = child.nextElementSibling;
    }
    return details.querySelector("summary");
  }

  function syncSummaryExpanded(details) {
    var summary = summaryOf(details);
    if (!summary) {
      return;
    }
    if (!summary.hasAttribute("aria-expanded")) {
      return;
    }
    summary.setAttribute("aria-expanded", details.open ? "true" : "false");
  }

  function openAncestorDetails(node) {
    var el = node && node.parentElement;
    while (el) {
      if (el.tagName === "DETAILS") {
        el.open = true;
        syncSummaryExpanded(el);
      }
      el = el.parentElement;
    }
  }

  function radioByAgentId(switcher, agentId) {
    if (!agentId) {
      return null;
    }
    var radios = radiosIn(switcher);
    return (
      radios.filter(function (r) {
        return r.getAttribute("data-agent-id") === agentId;
      })[0] || null
    );
  }

  function restoreStoredAgent(home) {
    var match = radioByAgentId(home.switcher, readStoredAgentId());
    if (!match) {
      return null;
    }
    openAncestorDetails(match);
    return match;
  }

  function clearCopyState(home) {
    if (resetTimerId !== null) {
      window.clearTimeout(resetTimerId);
      resetTimerId = null;
    }
    home.statusEl.textContent = "";
    home.copyShell.classList.remove(CLASS_SUCCESS, CLASS_ERROR);
    home.copyShell.removeAttribute("data-state");
    home.copyBtn.classList.remove(CLASS_SUCCESS, CLASS_ERROR);
    home.copyBtn.removeAttribute("data-state");
  }

  function setCopyState(home, state, message, clearAfterMs) {
    clearCopyState(home);
    home.statusEl.textContent = message;
    var className = state === STATE_SUCCESS ? CLASS_SUCCESS : CLASS_ERROR;
    home.copyShell.classList.add(className);
    home.copyShell.setAttribute("data-state", state);
    home.copyBtn.classList.add(className);
    home.copyBtn.setAttribute("data-state", state);

    if (typeof clearAfterMs === "number" && clearAfterMs > 0) {
      resetTimerId = window.setTimeout(function () {
        clearCopyState(home);
      }, clearAfterMs);
    }
  }

  function selectCommandText(commandEl) {
    try {
      var selection = window.getSelection();
      if (!selection) {
        return;
      }
      var range = document.createRange();
      range.selectNodeContents(commandEl);
      selection.removeAllRanges();
      selection.addRange(range);
    } catch (err) {
      // Selection APIs may fail on some hosts; status still guides manual copy.
    }
  }

  function copyText(text) {
    if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
      return navigator.clipboard.writeText(text);
    }

    return new Promise(function (resolve, reject) {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.left = "-9999px";
      document.body.appendChild(ta);
      ta.select();
      try {
        var ok = document.execCommand("copy");
        document.body.removeChild(ta);
        if (ok) {
          resolve();
        } else {
          reject(new Error("execCommand copy failed"));
        }
      } catch (err) {
        if (ta.parentNode) {
          document.body.removeChild(ta);
        }
        reject(err);
      }
    });
  }

  function bindDetailsAriaExpanded(switcher) {
    var detailsList = switcher.querySelectorAll(
      "details.agent-switcher__others, details.agent-switcher__more"
    );
    Array.prototype.forEach.call(detailsList, function (details) {
      if (details.getAttribute(ATTR_DETAILS_BOUND) === "true") {
        syncSummaryExpanded(details);
        return;
      }
      details.setAttribute(ATTR_DETAILS_BOUND, "true");
      syncSummaryExpanded(details);
      details.addEventListener("toggle", function () {
        syncSummaryExpanded(details);
      });
    });
    return detailsList.length > 0;
  }

  function bindButtonDisclosure(switcher) {
    var toggle = switcher.querySelector(
      ".agent-switcher__others-toggle[aria-expanded], button[aria-expanded].agent-switcher__others-toggle, [data-agent-others-toggle][aria-expanded]"
    );
    if (!toggle) {
      toggle = switcher.querySelector("button[aria-expanded]");
    }
    if (!toggle || toggle.getAttribute("data-others-bound") === "true") {
      return;
    }

    var panel =
      switcher.querySelector("[data-agent-others-panel], .agent-switcher__others-panel") ||
      switcher.querySelector("#" + (toggle.getAttribute("aria-controls") || ""));

    if (!panel) {
      return;
    }

    toggle.setAttribute("data-others-bound", "true");
    toggle.addEventListener("click", function () {
      var expanded = toggle.getAttribute("aria-expanded") === "true";
      var next = !expanded;
      toggle.setAttribute("aria-expanded", next ? "true" : "false");
      if (panel.hasAttribute("hidden") || typeof panel.hidden === "boolean") {
        panel.hidden = !next;
      }
      panel.setAttribute("aria-hidden", next ? "false" : "true");
    });
  }

  function bindDisclosure(switcher) {
    var hasDetails = bindDetailsAriaExpanded(switcher);
    if (!hasDetails) {
      bindButtonDisclosure(switcher);
    }
  }

  function bind(home) {
    if (home.switcher.getAttribute(ATTR_BOUND) === "true") {
      applySelection(home, restoreStoredAgent(home) || selectedRadio(home.switcher));
      return;
    }
    home.switcher.setAttribute(ATTR_BOUND, "true");

    bindDisclosure(home.switcher);

    var radios = radiosIn(home.switcher);
    radios.forEach(function (radio) {
      radio.addEventListener("change", function () {
        if (radio.checked) {
          applySelection(home, radio);
          writeStoredAgentId(radio.getAttribute("data-agent-id"));
        }
      });
    });

    home.copyBtn.addEventListener("click", function () {
      var messages = copyMessages();
      var text = (home.commandEl.textContent || "").trim();
      if (!text) {
        selectCommandText(home.commandEl);
        setCopyState(
          home,
          STATE_ERROR,
          messages.error + " — " + messages.recovery,
          STATUS_ERROR_MS
        );
        return;
      }
      copyText(text).then(
        function () {
          setCopyState(home, STATE_SUCCESS, messages.success, STATUS_SUCCESS_MS);
        },
        function () {
          selectCommandText(home.commandEl);
          setCopyState(
            home,
            STATE_ERROR,
            messages.error + " — " + messages.recovery,
            STATUS_ERROR_MS
          );
        }
      );
    });

    applySelection(home, restoreStoredAgent(home) || selectedRadio(home.switcher));
  }

  function init() {
    var home = queryHome();
    if (!home) {
      return;
    }
    bind(home);
  }

  function boot() {
    init();
    if (typeof window.document$ !== "undefined" && window.document$.subscribe) {
      window.document$.subscribe(init);
    } else if (typeof document$ !== "undefined" && document$.subscribe) {
      document$.subscribe(init);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
