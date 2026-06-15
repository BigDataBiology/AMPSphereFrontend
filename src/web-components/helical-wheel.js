// <helical-wheel data-sequence="ACDEF..."> custom element.
//
// Renders a helical wheel projection with selectable angle of separation,
// color scheme, hydrophobic-moment arrow and hydrophobic-face arc, plus a
// "Save as SVG" button.
//
// The diagram is a vanilla-JS port of the d3/Observable helical wheel by
// Tina Wang and Shyam Saladi (MIT licensed):
//   https://clemlab.github.io/helicalwheel/
//   https://github.com/clemlab/helicalwheel
// Credit is shown to the user beneath the diagram.

const SVGNS = 'http://www.w3.org/2000/svg'

// Amino-acid color schemes, copied from the original project. See
// http://www.bioinformatics.nl/~berndb/aacolour.html for background.
const COLOR_SCHEMES = {
    shapely: {
        D: '#E60A0A', E: '#E60A0A', C: '#E6E600', M: '#E6E600',
        K: '#145AFF', R: '#145AFF', S: '#FA9600', T: '#FA9600',
        F: '#3232AA', Y: '#3232AA', N: '#00DCDC', Q: '#00DCDC',
        G: '#EBEBEB', L: '#0F820F', V: '#0F820F', I: '#0F820F',
        A: '#C8C8C8', W: '#B45AB4', H: '#8282D2', P: '#DC9682',
    },
    lesk: {
        G: '#FFA500', A: '#FFA500', S: '#FFA500', T: '#FFA500',
        C: '#00FF00', V: '#00FF00', I: '#00FF00', L: '#00FF00',
        P: '#00FF00', F: '#00FF00', Y: '#00FF00', M: '#00FF00',
        W: '#00FF00', N: '#FF00FF', Q: '#FF00FF', H: '#FF00FF',
        D: '#FF0000', E: '#FF0000', K: '#0000FF', R: '#0000FF',
    },
    clustal: {
        M: '#00FF00', K: '#FF0000', R: '#FF0000', S: '#FFA500',
        T: '#FFA500', F: '#FF0000', Y: '#0000FF', G: '#FFA500',
        L: '#0F820F', V: '#00FF00', I: '#0000FF', W: '#0000FF',
        H: '#FFA500', P: '#FFA500',
    },
    cinema: {
        H: '#0000FF', K: '#0000FF', R: '#0000FF', D: '#FF0000',
        E: '#FF0000', S: '#00FF00', T: '#00FF00', N: '#00FF00',
        Q: '#00FF00', A: '#FFFFFF', V: '#FFFFFF', L: '#FFFFFF',
        I: '#FFFFFF', M: '#FFFFFF', F: '#FF00FF', W: '#FF00FF',
        Y: '#FF00FF', P: '#A52A2A', G: '#A52A2A', C: '#FFFF00',
    },
    maeditor: {
        A: '#90EE90', G: '#90EE90', C: '#00FF00', D: '#006400',
        E: '#006400', N: '#006400', Q: '#006400', I: '#0000FF',
        L: '#0000FF', M: '#0000FF', V: '#0000FF', F: '#9999FF',
        W: '#9999FF', Y: '#9999FF', H: '#00008B', K: '#FFA500',
        R: '#FFA500', P: '#FFC0CB', S: '#FF0000', T: '#FF0000',
    },
    heliquest: {
        A: '#BEBEBE', C: '#FFFF00', D: '#FFFF00', E: '#FFFF00',
        F: '#FFFF00', G: '#BEBEBE', H: '#ADD8E6', I: '#FFFF00',
        L: '#FFFF00', M: '#FFFF00', N: '#FFC0CB', P: '#00FF00',
        Q: '#FFC0CB', R: '#0000FF', S: '#A020F0', T: '#A020F0',
        V: '#FFFF00', W: '#FFFF00', Y: '#FFFF00',
    },
}

const ANGLE_OPTIONS = [
    { label: 'Alpha Helix: 100', value: 100 },
    { label: 'Pi-Helix: 87', value: 87 },
    { label: '3-10 Helix: 120', value: 120 },
]

const SCHEME_OPTIONS = [
    { label: 'Cinema', value: 'cinema' },
    { label: 'Shapely', value: 'shapely' },
    { label: 'Lesk', value: 'lesk' },
    { label: 'Clustal', value: 'clustal' },
    { label: 'MAEditor (Multiple Alignment Editor)', value: 'maeditor' },
    { label: 'HeliQuest', value: 'heliquest' },
]

// Eisenberg et al. (1984) normalized consensus hydrophobicity scale. Used to
// compute the hydrophobic moment vector from the sequence.
const EISENBERG = {
    A: 0.62, R: -2.53, N: -0.78, D: -0.90, C: 0.29,
    Q: -0.85, E: -0.74, G: 0.48, H: -0.40, I: 1.38,
    L: 1.06, K: -1.50, M: 0.64, F: 1.19, P: 0.12,
    S: -0.18, T: -0.05, W: 0.81, Y: 0.26, V: 1.08,
}

// Layout constants, matching the original project.
const WIDTH = 700
const HEIGHT = 700
const RADIUS = 300
const FIELD_RADIUS = 0.7 * RADIUS
const MAX_DOT = RADIUS / 15
const MIN_DOT = RADIUS / 25
const TERM_DIST = 2
const CIRCLE_SEP = 50
const START_STROKE = 0.1
const END_STROKE = 2

function gcd(a, b) {
    return b === 0 ? a : gcd(b, a % b)
}

function lcm(a, b) {
    return (a * b) / gcd(a, b)
}

// Hydrophobic moment vector, summing each residue's Eisenberg hydrophobicity
// projected onto its position angle around the wheel. The resulting vector
// points toward the hydrophobic face; its magnitude (per residue) is <muH>.
function hydrophobicMoment(sequence, angle) {
    let mx = 0
    let my = 0
    let n = 0
    for (let i = 0; i < sequence.length; i++) {
        const h = EISENBERG[sequence[i]]
        if (h == null) continue
        const theta = (i * angle) * Math.PI / 180
        mx += h * Math.cos(theta)
        my += h * Math.sin(theta)
        n++
    }
    const magnitude = Math.sqrt(mx * mx + my * my)
    return { mx, my, magnitude, mean: n > 0 ? magnitude / n : 0 }
}

function svgEl(name, attrs) {
    const node = document.createElementNS(SVGNS, name)
    if (attrs) {
        for (const key in attrs) {
            if (attrs[key] != null) node.setAttribute(key, attrs[key])
        }
    }
    return node
}

class HelicalWheel extends HTMLElement {
    static get observedAttributes() {
        return ['data-sequence']
    }

    constructor() {
        super()
        this._angle = 100
        this._scheme = 'cinema'
        this._hMoment = true
        this._hFace = true
        this._built = false
    }

    connectedCallback() {
        if (!this._built) this._build()
        this._render()
    }

    attributeChangedCallback(name) {
        if (name === 'data-sequence' && this._built) this._render()
    }

    _sequence() {
        return (this.getAttribute('data-sequence') || '').toUpperCase().replace(/[^A-Z]/g, '')
    }

    _build() {
        this._built = true
        this.style.display = 'block'

        const wrapper = document.createElement('div')
        wrapper.className = 'helical-wheel-component'

        // --- Controls ---
        const controls = document.createElement('div')
        controls.className = 'hw-controls'

        const angleSelect = this._makeSelect(
            'Angle of Separation between Amino Acids',
            ANGLE_OPTIONS,
            this._angle,
            (v) => { this._angle = Number(v); this._render() }
        )

        const schemeSelect = this._makeSelect(
            'Color Scheme to Use',
            SCHEME_OPTIONS,
            this._scheme,
            (v) => { this._scheme = v; this._render() }
        )

        const momentToggle = this._makeToggle(
            'Hydrophobic Moment',
            this._hMoment,
            (on) => { this._hMoment = on; this._render() }
        )

        const faceToggle = this._makeToggle(
            'Hydrophobic Face',
            this._hFace,
            (on) => { this._hFace = on; this._render() }
        )

        const saveBtn = document.createElement('button')
        saveBtn.type = 'button'
        saveBtn.className = 'btn btn-sm btn-outline-secondary hw-save'
        saveBtn.textContent = 'Save as SVG'
        saveBtn.addEventListener('click', () => this._saveSvg())

        controls.appendChild(angleSelect)
        controls.appendChild(schemeSelect)
        controls.appendChild(momentToggle)
        controls.appendChild(faceToggle)
        controls.appendChild(saveBtn)

        // --- Diagram ---
        const figure = document.createElement('div')
        figure.className = 'hw-figure'
        this._svgHost = document.createElement('div')
        figure.appendChild(this._svgHost)

        const row = document.createElement('div')
        row.className = 'hw-row'
        row.appendChild(controls)
        row.appendChild(figure)
        wrapper.appendChild(row)

        // --- Credit ---
        const credit = document.createElement('p')
        credit.className = 'hw-credit'
        credit.innerHTML =
            'Generated based on Tina Wang and Shyam Saladi\'s work ' +
            '(<a href="https://clemlab.github.io/helicalwheel/" target="_blank" rel="noopener">' +
            'https://clemlab.github.io/helicalwheel/</a>). ' +
            'If you want to customize the graph, please use their original website.'
        wrapper.appendChild(credit)

        this.appendChild(wrapper)
    }

    _makeSelect(title, options, value, onChange) {
        const group = document.createElement('div')
        group.className = 'hw-field'
        const label = document.createElement('label')
        label.className = 'hw-label'
        label.textContent = title
        const select = document.createElement('select')
        select.className = 'form-control form-control-sm'
        for (const opt of options) {
            const o = document.createElement('option')
            o.value = opt.value
            o.textContent = opt.label
            if (opt.value === value) o.selected = true
            select.appendChild(o)
        }
        select.addEventListener('change', (e) => onChange(e.target.value))
        group.appendChild(label)
        group.appendChild(select)
        return group
    }

    _makeToggle(title, value, onChange) {
        const group = document.createElement('div')
        group.className = 'hw-field'
        const label = document.createElement('label')
        label.className = 'hw-label'
        label.textContent = title
        group.appendChild(label)

        const name = 'hw-' + title.replace(/\s+/g, '-').toLowerCase() + '-' + Math.random().toString(36).slice(2)
        const opts = [{ label: 'On', on: true }, { label: 'Off', on: false }]
        const radios = document.createElement('div')
        radios.className = 'hw-radios'
        for (const opt of opts) {
            const wrap = document.createElement('label')
            wrap.className = 'hw-radio'
            const input = document.createElement('input')
            input.type = 'radio'
            input.name = name
            input.checked = opt.on === value
            input.addEventListener('change', () => { if (input.checked) onChange(opt.on) })
            wrap.appendChild(input)
            wrap.appendChild(document.createTextNode(' ' + opt.label))
            radios.appendChild(wrap)
        }
        group.appendChild(radios)
        return group
    }

    _render() {
        if (!this._svgHost) return
        const sequence = this._sequence()
        this._svgHost.innerHTML = ''
        if (!sequence) return

        const svg = this._buildSvg(sequence)
        this._svgHost.appendChild(svg)
    }

    _buildSvg(sequence) {
        const angle = this._angle
        const colors = COLOR_SCHEMES[this._scheme] || COLOR_SCHEMES.cinema
        const colorFor = (c) => colors[c] || '#CCCCCC'

        const svg = svgEl('svg', {
            viewBox: `0 0 ${WIDTH} ${HEIGHT}`,
            'text-anchor': 'middle',
            class: 'helical-wheel',
        })
        svg.style.font = "700 14px sans-serif"

        // Markers for hydrophobic face / moment.
        const defs = svgEl('defs')
        const circlehead = svgEl('marker', {
            id: 'hw-circlehead', refX: 0, refY: 0, viewBox: '-6 -6 12 12',
            markerWidth: 15, markerHeight: 15, markerUnits: 'userSpaceOnUse', orient: 'auto',
        })
        circlehead.appendChild(svgEl('path', {
            d: 'M 0, 0  m -5, 0  a 5,5 0 1,0 10,0  a 5,5 0 1,0 -10,0', fill: '#bbb',
        }))
        const arrowhead = svgEl('marker', {
            id: 'hw-arrowhead', refX: 3, refY: 3, markerWidth: 20, markerHeight: 20, orient: 'auto',
        })
        arrowhead.appendChild(svgEl('path', { d: 'M 0 0 6 3 0 6 1.5 3', fill: '#bbb' }))
        defs.appendChild(circlehead)
        defs.appendChild(arrowhead)
        svg.appendChild(defs)

        const group = svgEl('g', { transform: `translate(${WIDTH / 2}, ${HEIGHT / 2})` })
        svg.appendChild(group)

        const circlesPerRound = lcm(angle, 360) / angle
        const circlesPerTurn = Math.ceil(360 / angle)
        const pctRadius = Math.abs(MAX_DOT - MIN_DOT) / (circlesPerRound / circlesPerTurn)

        // Position of each residue and its circle radius.
        const residues = sequence.split('').map((c, i) => {
            const angleRad = ((i * angle) % 360) * Math.PI / 180
            const radiusAdj = FIELD_RADIUS + CIRCLE_SEP * Math.floor(i / circlesPerRound)
            const circleRadius = i < circlesPerRound
                ? MAX_DOT - Math.floor(i / circlesPerTurn) * pctRadius
                : MIN_DOT
            return {
                c, i,
                x: Math.cos(angleRad) * radiusAdj,
                y: Math.sin(angleRad) * radiusAdj,
                circleRadius,
            }
        })

        // Connecting paths (drawn first, beneath circles); stroke shrinks along the chain.
        const pctStroke = (END_STROKE - START_STROKE) / circlesPerRound
        for (let i = 0; i < residues.length - 1; i++) {
            const a = residues[i]
            const b = residues[i + 1]
            const strokeWidth = END_STROKE >= START_STROKE
                ? Math.max(END_STROKE - pctStroke * a.i, START_STROKE)
                : Math.min(END_STROKE + pctStroke * a.i, START_STROKE)
            group.appendChild(svgEl('path', {
                d: `M${a.x},${a.y}L${b.x},${b.y}`,
                stroke: 'black',
                'stroke-width': strokeWidth,
                fill: 'none',
            }))
        }

        // Hydrophobic face arc.
        if (this._hFace) {
            const arcR = FIELD_RADIUS * 1.3
            const startAngle = Math.PI / 2 - 2 * Math.PI / 9
            const endAngle = Math.PI / 2 - 4 * Math.PI / 9
            const steps = 24
            let d = ''
            for (let s = 0; s <= steps; s++) {
                const t = startAngle + (endAngle - startAngle) * (s / steps)
                // d3.arc angle convention: 0 at top, clockwise positive.
                const px = Math.sin(t) * arcR
                const py = -Math.cos(t) * arcR
                d += (s === 0 ? 'M' : 'L') + px.toFixed(2) + ',' + py.toFixed(2)
            }
            group.appendChild(svgEl('path', {
                d,
                fill: 'none',
                stroke: '#bbb',
                'stroke-width': 3,
                'stroke-dasharray': '4,8',
                'marker-start': 'url(#hw-circlehead)',
                'marker-end': 'url(#hw-circlehead)',
            }))
        }

        // Hydrophobic moment arrow, computed from the sequence (Eisenberg scale).
        // Points toward the hydrophobic face; length scales with <muH>.
        if (this._hMoment) {
            const moment = hydrophobicMoment(sequence, angle)
            if (moment.magnitude > 1e-6) {
                const len = Math.min(FIELD_RADIUS * 0.95, Math.max(25, moment.mean * 260))
                const ux = moment.mx / moment.magnitude
                const uy = moment.my / moment.magnitude
                const line = svgEl('line', {
                    x1: 0, y1: 0,
                    x2: (ux * len).toFixed(2), y2: (uy * len).toFixed(2),
                    stroke: '#bbb', 'stroke-width': 3,
                    'marker-end': 'url(#hw-arrowhead)',
                })
                const title = svgEl('title')
                title.textContent = `Mean hydrophobic moment <μH> = ${moment.mean.toFixed(3)}`
                line.appendChild(title)
                group.appendChild(line)
            }
        }

        // Residue circles + labels (residue letter inside, position number outside).
        for (const r of residues) {
            const node = svgEl('g', { transform: `translate(${r.x}, ${r.y})` })
            node.appendChild(svgEl('circle', {
                r: r.circleRadius,
                fill: colorFor(r.c),
                stroke: 'black',
                'stroke-width': 1,
            }))
            const inside = svgEl('text', {
                'text-anchor': 'middle', 'dominant-baseline': 'central', fill: '#000',
            })
            inside.textContent = r.c
            node.appendChild(inside)

            const outside = svgEl('text', {
                dx: -r.circleRadius - TERM_DIST,
                dy: -r.circleRadius - TERM_DIST,
                fill: '#000',
            })
            outside.textContent = r.i + 1
            node.appendChild(outside)

            // N / C termini labels in red.
            if (r.i === 0 || r.i === residues.length - 1) {
                const term = svgEl('text', {
                    dx: r.circleRadius + TERM_DIST,
                    dy: r.circleRadius + TERM_DIST,
                    fill: 'red',
                })
                term.textContent = r.i === 0 ? 'N' : 'C'
                node.appendChild(term)
            }
            group.appendChild(node)
        }

        return svg
    }

    _saveSvg() {
        const svg = this._svgHost && this._svgHost.querySelector('svg')
        if (!svg) return
        const clone = svg.cloneNode(true)
        clone.setAttribute('xmlns', SVGNS)
        clone.setAttribute('xmlns:xlink', 'http://www.w3.org/1999/xlink')
        const source = new XMLSerializer().serializeToString(clone)
        const blob = new Blob([source], { type: 'image/svg+xml' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'helical-wheel.svg'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
    }
}

if (!customElements.get('helical-wheel')) {
    customElements.define('helical-wheel', HelicalWheel)
}
