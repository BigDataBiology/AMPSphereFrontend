class PlotlyChart extends HTMLElement {
    static get observedAttributes() {
        return ['data-chart']
    }

    constructor() {
        super()
        this._initialized = false
    }

    connectedCallback() {
        this.style.display = 'block'
        this.style.width = '100%'
        this._render()
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if (name === 'data-chart' && newValue !== oldValue) {
            this._render()
        }
    }

    _render() {
        const raw = this.getAttribute('data-chart')
        if (!raw || typeof Plotly === 'undefined') return

        try {
            const config = JSON.parse(raw)
            const data = config.data || []
            const layout = Object.assign(
                { autosize: true, margin: { t: 30, r: 20, b: 40, l: 50 } },
                config.layout || {}
            )
            const plotConfig = Object.assign(
                { responsive: true, displayModeBar: false },
                config.config || {}
            )

            if (this._initialized) {
                Plotly.react(this, data, layout, plotConfig)
            } else {
                Plotly.newPlot(this, data, layout, plotConfig)
                this._initialized = true
            }
        } catch (e) {
            console.error('PlotlyChart: failed to render', e)
        }
    }

    disconnectedCallback() {
        if (this._initialized && typeof Plotly !== 'undefined') {
            Plotly.purge(this)
        }
    }
}

if (!customElements.get('plotly-chart')) {
    customElements.define('plotly-chart', PlotlyChart)
}
