import { createApp, h } from 'vue'
import App from './App.vue'
import ElementPLus from 'element-plus'
import './styles/theme/index.css'
import './styles/main.css';
import "quasar/dist/quasar.sass"
import locale from 'element-plus/lib/locale/lang/en'
import router from './router'
import axios from 'axios'
import VueAxios from 'vue-axios'
import { Download, More } from '@element-plus/icons'
import JsonViewer from "vue3-json-viewer"
import BootstrapIcon from '@dvuckovic/vue3-bootstrap-icons'
import { Quasar, Notify } from 'quasar'
import quasarUserOptions from './quasar-user-options'
import VueGtag from "vue-gtag-next"


router.beforeEach((to, from, next) => {
    if (to.meta.title) {
        document.title = to.meta.title
    }
    next()
})

const app = createApp(
    {render: () => h(App),}
)


app.use(router)
app.use(VueGtag, {
    property: {
        id: "G-WXMZ531P7V",
    },
})


app.use(Quasar, {plugins: {Notify}, config: {notify: { /* look at QuasarConfOptions from the API card */ }}})
app.use(Quasar, quasarUserOptions)
app.use(ElementPLus, {locale})
app.use(VueAxios, axios)
app.use(JsonViewer)
app.component(More.name, More)
app.component(Download.name, Download)
app.component('BootstrapIcon', BootstrapIcon);
axios.defaults.baseURL = 'https://ampsphere-api.big-data-biology.org/v1'
app.mount('#app')