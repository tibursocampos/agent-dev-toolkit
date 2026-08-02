/**
 * Home agent switcher + sync-command clipboard helper.
 * Defensive no-op on pages without the home CTA / switcher markup.
 * Re-inits on MkDocs Material instant navigation via document$ when present.
 */
(function () {
  "use strict";

  var RADIO_NAME = "home-agent";
  var STATUS_RESET_MS = 2500;
  var BASE_SYNC_COMMAND = "pwsh -NoProfile -File .\\scripts\\toolkit.ps1";
  var COPY_SUCCESS_TEXT = "Copied";
  var COPY_ERROR_TEXT = "Clipboard denied";
  var STATE_SUCCESS = "success";
  var STATE_ERROR = "error";
  var CLASS_SUCCESS = "is-success";
  var CLASS_ERROR = "is-error";

  var resetTimerId = null;

  function queryHome() {
    var switcher = document.querySelector("[data-agent-switcher], #agent-switcher");
    var commandEl = document.querySelector("[data-sync-command], #sync-command");
    var copyBtn = document.querySelector('[data-copy-target="#sync-command"], #copy-sync-command');
    var statusEl = document.querySelector("[data-copy-status], #copy-sync-status");
    var hintEl = document.querySelector("[data-agent-install-hint], #agent-install-hint");

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

  function setCopyState(home, state, message) {
    clearCopyState(home);
    home.statusEl.textContent = message;
    var className = state === STATE_SUCCESS ? CLASS_SUCCESS : CLASS_ERROR;
    home.copyShell.classList.add(className);
    home.copyShell.setAttribute("data-state", state);
    home.copyBtn.classList.add(className);
    home.copyBtn.setAttribute("data-state", state);
    resetTimerId = window.setTimeout(function () {
      clearCopyState(home);
    }, STATUS_RESET_MS);
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
        document.body.removeChild(ta);
        reject(err);
      }
    });
  }

  function bind(home) {
    if (home.switcher.getAttribute("data-agent-switcher-bound") === "true") {
      return;
    }
    home.switcher.setAttribute("data-agent-switcher-bound", "true");

    var radios = radiosIn(home.switcher);
    radios.forEach(function (radio) {
      radio.addEventListener("change", function () {
        if (radio.checked) {
          applySelection(home, radio);
        }
      });
    });

    home.copyBtn.addEventListener("click", function () {
      var text = (home.commandEl.textContent || "").trim();
      if (!text) {
        setCopyState(home, STATE_ERROR, COPY_ERROR_TEXT);
        return;
      }
      copyText(text).then(
        function () {
          setCopyState(home, STATE_SUCCESS, COPY_SUCCESS_TEXT);
        },
        function () {
          setCopyState(home, STATE_ERROR, COPY_ERROR_TEXT);
        }
      );
    });

    applySelection(home, selectedRadio(home.switcher));
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
