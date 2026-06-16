// <copy-button data-text="..."> — a small button that copies data-text to the
// clipboard and briefly shows a confirmation. Self-contained, no Elm ports.

class CopyButton extends HTMLElement {
    connectedCallback() {
        if (this._button) return;

        const button = document.createElement("button");
        button.type = "button";
        button.className = "btn btn-outline-secondary btn-sm";
        this._button = button;

        this._render("Copy");
        button.addEventListener("click", () => this._copy());

        this.appendChild(button);
    }

    _render(label) {
        this._button.textContent = label;
    }

    _copy() {
        const text = this.getAttribute("data-text") || "";

        const done = () => {
            this._render("Copied!");
            clearTimeout(this._timer);
            this._timer = setTimeout(() => this._render("Copy"), 1500);
        };

        const fail = () => {
            this._render("Copy failed");
            clearTimeout(this._timer);
            this._timer = setTimeout(() => this._render("Copy"), 1500);
        };

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(done, () => this._fallback(text, done, fail));
        } else {
            this._fallback(text, done, fail);
        }
    }

    _fallback(text, done, fail) {
        const ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        let ok = false;
        try {
            ok = document.execCommand("copy");
        } catch (e) {
            ok = false;
        }
        document.body.removeChild(ta);
        (ok ? done : fail)();
    }
}

customElements.define("copy-button", CopyButton);
