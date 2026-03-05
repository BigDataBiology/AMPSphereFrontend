// Flags passed to Elm on startup
export const flags = ({ env }) => ({
    apiBaseUrl: env.API_BASE_URL || "https://ampsphere-api.big-data-biology.org/v1"
})

// Called after Elm app starts
export const onReady = ({ app, env }) => {
    // Import web components
    import('./web-components/plotly-chart.js')
}
