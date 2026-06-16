// Flags passed to Elm on startup
export const flags = ({ env }) => ({
    apiBaseUrl: env.API_BASE_URL || "https://ampsphere-api.big-data-biology.org/v1"
})

// Called after Elm app starts
export const onReady = ({ app, env }) => {
    // Import web components
    import('./web-components/plotly-chart.js')
    import('./web-components/helical-wheel.js')
    import('./web-components/copy-button.js')

    // Google Analytics (gtag)
    const GA_ID = 'G-WXMZ531P7V'
    const loader = document.createElement('script')
    loader.async = true
    loader.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID
    document.head.appendChild(loader)
    window.dataLayer = window.dataLayer || []
    function gtag() { window.dataLayer.push(arguments) }
    window.gtag = gtag
    gtag('js', new Date())
    gtag('config', GA_ID)
}
