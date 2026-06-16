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

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(done, () => this._fallback(text, done));
        } else {
            this._fallback(text, done);
        }
    }

    _fallback(text, done) {
        const ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        try {
            document.execCommand("copy");
            done();
        } catch (e) {
            // ignore
        }
        document.body.removeChild(ta);
    }
}

customElements.define("copy-button", CopyButton);
