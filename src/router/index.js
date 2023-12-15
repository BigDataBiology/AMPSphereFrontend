import { createRouter, createWebHistory } from 'vue-router'
import Home from "../views/Home"
import BrowseData from "../views/Browse_data"
import Downloads from '../views/Downloads'
import AMP_card from '../views/AMP_Card'
import Family_card from "../views/Family_card";
import About from '../views/About'
import Quality_tests from '@/views/Quality_tests'
import Contact from '../views/Contact'
import SequenceSearch from "../views/SequenceSearch";
import TextSearch from "../views/TextSearch";
import { trackRouter } from "vue-gtag-next";


const routes = [
    {
        path: '/',
        redirect: 'home'
    },
    {
        path: "/home",
        name: "Home",
        component: Home,
        meta:{
            title: 'AMPSphere: Home'
        }
    },
    {
        path: "/browse_data",
        name: "Browse_data",
        component: BrowseData,
        meta:{
            title: 'AMPSphere: Browse data'
        }
    },
    {
        path: "/text_search",
        name: "Text_search",
        component: TextSearch,
        meta:{
            title: 'AMPSphere: Text search'
        }
    },
    {
        path: "/sequence_search",
        name: "Sequence_search",
        component: SequenceSearch,
        meta:{
            title: 'AMPSphere: Sequence search'
        }
    },
    {
        path: "/amp",
        name: "AMP",
        component: AMP_card,
        meta:{
            title: 'AMPSphere: AMP'
        },
    },
    {
        path: "/family",
        name: "Family",
        component: Family_card,
        meta:{
            title: 'AMPSphere: Family'
        },
    },
    {
        path: '/downloads',
        name: 'Downloads',
        component: Downloads,
        meta:{
            title: 'AMPSphere: Downloads'
        }
    },
    {
        path: '/contact',
        name: 'Contact',
        component: Contact,
        meta: {
            title: 'AMPSphere: Contact'
        }
    },
    {
        path: '/about',
        name: 'About',
        component: About,
        meta: {
            title: 'AMPSphere: About'
        }
    },
    {
        path: '/quality_tests',
        name: 'Quality tests',
        component: Quality_tests,
        meta: {
            title: 'AMPSphere: Quality tests'
        }
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes: routes,
})

trackRouter(router)

export default router
