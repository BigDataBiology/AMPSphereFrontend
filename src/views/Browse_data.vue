<template>
  <div class="BrowseData">
    <div class="row justify-center">
      <div class="col-xs-0 col-xl-2 bg-white"></div>
      <div class="col-12 col-xl-8 justify-center q-pa-auto">
        <div class="row">
          <div class="col-12 col-md-3 q-pa-sm">
            <div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Filter by quality</div>
              <div class="row q-px-md q-py-xs">
                <q-select filled v-model="options.quality" label="Quality" @update:model-value="onQualityChange"
                          :options="['High', 'Medium', 'Low']"
                          style="width: 250px" behavior="menu" align="center" clearable/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Filter by metadata</div>
              <div class="row q-px-md q-py-xs">
                <q-select filled v-model="options.habitat" label="Habitat" @update:model-value="onHabitatChange"
                          :options="availableOptions.habitat" @filter="filterHabitat"
                          input-debounce="0" use-input fill-input hide-selected style="width: 250px"
                          behavior="menu" align="center" clearable/>
              </div>
              <div class="row q-px-md">
                <q-select filled v-model="options.microbial_source" label="Microbial source"
                          @update:model-value="onMicrobialSourceChange"
                          :options="availableOptions.microbial_source" @filter="filterMicrobialSource"
                          style="width: 250px"
                          input-debounce="0" use-input fill-input hide-selected hint="GTDB taxonomy name"
                          behavior="menu" align="center" clearable/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Peptide length:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.pep_length.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.pep_length.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.pep_length" @change="onPepLengthChange"
                         :min="staticOptions.pep_length.min" :max="staticOptions.pep_length.max"
                         :inner-min="filteredAvailableOptions.pep_length.min" style="width: 240px"
                         :inner-max="filteredAvailableOptions.pep_length.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Molecular weight:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.molecular_weight.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.molecular_weight.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.molecular_weight" @change="onMWChange"
                         :min="staticOptions.molecular_weight.min" :max="staticOptions.molecular_weight.max"
                         :inner-min="filteredAvailableOptions.molecular_weight.min" style="width: 240px"
                         :inner-max="filteredAvailableOptions.molecular_weight.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Isoelectric point:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.isoelectric_point.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.isoelectric_point.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.isoelectric_point" @change="onpIChange"
                         :min="staticOptions.isoelectric_point.min" :max="staticOptions.isoelectric_point.max"
                         :inner-min="filteredAvailableOptions.isoelectric_point.min" style="width: 240px"
                         :inner-max="filteredAvailableOptions.isoelectric_point.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Charge at pH 7.0:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.charge_at_pH_7.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.charge_at_pH_7.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.charge_at_pH_7" @change="onChargechange"
                         :min="staticOptions.charge_at_pH_7.min" :max="staticOptions.charge_at_pH_7.max"
                         :inner-min="filteredAvailableOptions.charge_at_pH_7.min" label style="width: 240px"
                         :inner-max="filteredAvailableOptions.charge_at_pH_7.max" color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">
                 <q-toggle v-model="advancedFiltersVisible" label="Advanced filters" left-label class="q-mb-md" />
              </div>

              <q-slide-transition>
                <div v-show="advancedFiltersVisible">
                  <!--  TODO　Add in database checking-->
                  <div class="row q-px-md q-py-xs">
                    <q-input v-model.number="options.family" type="text" label="Family" filled style="width: 250px"
                             :error="(!familyInDB && options.family !== '')" lazy-rules
                             @change="onFamilyChange" clearable @clear="onFamilyClear"
                             error-message="The input does not match any family" />
                  </div>
                  <div class="row q-px-md q-py-xs">
                    <q-input v-model.number="options.sample" type="text" label="Sample/Genome" filled style="width: 250px"
                             :error="(!sampleInDB && options.sample !== '')" lazy-rules
                             @change="onSampleChange" clearable @clear="onSampleClear"
                             error-message="The input does not match any sample/genome" />
                  </div>
                </div>
              </q-slide-transition>
            </div>
          </div>

          <div class="col-12 col-md-9 q-py-sm q-px-lg">
            <div class="row">
              <div class="col-6 main-text">Displaying: {{ info.pageSize }} out of {{ info.totalRow }} results.</div>
              <div class="col-6" style="padding-right: 10rem;">
                <el-button @click="downloadSearchResults" type="primary" class="download-btn">
                  <BootstrapIcon icon="cloud-download" variant="light" size="1x" />
                Download as CSV
              </el-button>
              </div>
            </div>
            <el-table :data="amps" stripe style="width: 100%" v-loading="loading">
              <el-table-column label="Accession" width="150%">
                <template #default="props">
                  <el-button @click="AMPDetail(props.row.accession)" type="text">{{ props.row.accession }}</el-button>
                </template>
              </el-table-column>
              <el-table-column label="Family" width="150%">
                <template #default="props">
                  <el-button @click="familyDetail(props.row.family)" type="text">{{ props.row.family }}</el-button>
                </template>
              </el-table-column>
              <el-table-column label="Peptide sequence" width="300%">
                <template #default="props">
                  <pre><code><small>{{ props.row.sequence }}</small></code></pre>
                </template>
              </el-table-column>
              <el-table-column label="# smORF genes" width="120%">
                <template #default="props">
                  <!--                <el-tooltip class="item" effect="dark" content="Associated number of small ORF genes." placement="right">-->
                  <span>{{ props.row.metadata.info.totalItem }}</span>
                  <!--                </el-tooltip>-->
                </template>
              </el-table-column>
              <el-table-column label="Quality badge" width="150%">
                <template #default="props">
                  <!--                  <q-badge :color="getBadgeColor(props.row.quality.badge)" :label="getBadgeLabel(props.row.quality.badge)" text-color="black"/>-->
                  <q-img :src="makeBadgeURL(props.row.RNAcode)" height="70%" fit="scale-down"></q-img>
                </template>
              </el-table-column>
            </el-table>
            <el-pagination @size-change="setAMPsPageSize" @current-change="setAMPsPage" :page-sizes="[20, 50, 100, 200]"
                           :page-size="20" layout="sizes, pager, jumper" :total="info.totalRow">
            </el-pagination>
          </div>
        </div>
      </div>
      <div class="col-xs-0 col-xl-2 bg-white"></div>
    </div>
  </div>
</template>

<style>
.env-logos {
  width: 100%;
  height: 100px;
  background-color: #ffffff;
}
</style>

<script>
import {useQuasar} from 'quasar'


export default {
  name: "BrowseData",

  data() {
    const options_full = {

      quality: [],
      habitat: [],
      microbial_source: [],
      pep_length: {min: 8, max: 98},
      molecular_weight: {min: 813, max: 12286},
      isoelectric_point: {min: 4, max: 12},
      charge_at_pH_7: {min: -57, max: 44}
    }
    return {
      advancedFiltersVisible: false,
      familyInDB: true,
      sampleInDB: true,
      loading: false,
      amps: [],
      axiosRefCount: 0,
      info: {currentPage: 1, pageSize: 20, totalRow: 0, totalPage: 1,},
      options: {
        quality: null, family: null, habitat: null, sample: null, microbial_source: null,
        pep_length: {min: 8, max: 99},
        molecular_weight: {min: 813, max: 12286},
        isoelectric_point: {min: 4, max: 12},
        charge_at_pH_7: {min: -57, max: 44}
      },
      staticOptions: options_full,
      availableOptions: options_full,
      filteredAvailableOptions: options_full
    }
  },
  setup() {
    const $q = useQuasar()
    let timer
    return {}
  },
  created() {
    let self = this
    // https://stackoverflow.com/questions/50768678/axios-ajax-show-loading-when-making-ajax-request
    this.axios.interceptors.request.use((config) => {
      self.loading = true
      // trigger 'loading=true' event here
      return config;
    }, (error) => {
      self.loading = false
      // trigger 'loading=false' event here
      return Promise.reject(error);
    });
    this.axios.interceptors.response.use((response) => {
      self.loading = false
      // trigger 'loading=false' event here
      return response;
    }, (error) => {
      self.loading = false
      // trigger 'loading=false' event here
      return Promise.reject(error);
    });
  },
  mounted() {
    this.setAMPsPageSize(20)
    this.getAvailableOptions()
    // this.grayOutOptions()
  },
  computed: {},
  methods: {
    getParams(){
      return {
          quality: this.transQualityOptions(this.options.quality),
          family: this.options.family,
          habitat: this.options.habitat,
          host: this.options.host,
          sample: this.options.sample,
          microbial_source: this.options.microbial_source,
          pep_length_interval: this.options.pep_length.min.toString() + ',' + this.options.pep_length.max.toString(),
          mw_interval: this.options.molecular_weight.min.toString() + ',' + this.options.molecular_weight.max.toString(),
          pI_interval: this.options.isoelectric_point.min.toString() + ',' + this.options.isoelectric_point.max.toString(),
          charge_interval: this.options.charge_at_pH_7.min.toString() + ',' + this.options.charge_at_pH_7.max.toString(),
          page: this.info.currentPage,
          page_size: this.info.pageSize
      }
    },
    setAMPsPage(page) {
      this.info.currentPage = page - 1
      console.log(this.info.currentPage)
      let config = {
        params: this.getParams()
      }
      let self = this
      this.axios.get('/amps', config)
          .then(function (response) {
            console.log(response.data.data)
            self.amps = self.initQualityTag(response.data.data)
            self.info.totalPage = response.data.info.totalPage
            self.info.totalRow = response.data.info.totalItem
          })
          .catch(function (error) {
            console.log(error);
          })
    },
    setAMPsPageSize(size) {
      this.info.pageSize = size
      this.setAMPsPage(1)
    },
    getAvailableOptions() {
      let self = this
      this.axios.get('/all_available_options')
          .then(function (response) {
            console.log(response.data)
            self.staticOptions = Object.assign({}, response.data)
            self.availableOptions = response.data
          })
          .catch(function (error) {
            console.log(error);
          })
    },
    grayOutOptions(){
      let config = {
        params: this.getParams()
      }
      this.axios.get('/current_available_options', config)
          .then(function (response) {
            console.log(response.data)
            self.filteredAvailableOptions = response.data
          })
          .catch(function (error) {
            console.log(error);
          })
    },
    filterHabitat(val, update, abort) {
      update(() => {
        val = val.toLowerCase()
        this.availableOptions.habitat = this.staticOptions.habitat.filter(v => v.toLowerCase().indexOf(val) > -1)
      })
    },
    filterMicrobialSource(val, update, abort) {
      update(() => {
        val = val.toLowerCase()
        this.availableOptions.microbial_source = this.staticOptions.microbial_source.filter(v => v.toLowerCase().indexOf(val) > -1)
      })
    },
    onQualityChange(option){
      this.options.quality = option
      this.setAMPsPage(1)
    },

    onFamilyChange(option) {
      this.inDBChecking(this.options.family, 'family')
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onSampleChange(option) {
      this.inDBChecking(this.options.sample, 'sample')
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onFamilyClear(){
      this.options.family = ''
      this.onFamilyChange(this.options.family)
    },
    onSampleClear(){
      this.options.sample = ''
      this.onSampleChange(this.options.sample)
    },
    onHabitatChange(option) {
      this.options.habitat = option;
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    // onSampleChange(option) {
    //   this.options.sample = option;
    //   this.setAMPsPage(1)
    // },
    onMicrobialSourceChange(option) {
      this.options.microbial_source = option;
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onPepLengthChange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('peplength changed.')
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onMWChange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('MW changed.')
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onpIChange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('pI changed.')
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onChargechange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('Charge changed.')
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    // clearFilters() {
    //   this.options = {
    //     family: null,
    //     habitat: null,
    //     sample: null,
    //     microbial_source: null,
    //     pep_length: {
    //       min: 0,
    //       max: 100
    //     }
    //   }
    // },
    initQualityTag(amps) {
      for (let i = 0; i < amps.length; i++) {
        Object.assign(amps[i], {quality_tag: {msg: 'Not available', level: 'warning'}})
      }
      return amps
    },
    transQualityOptions(quality_level){
      const quality_level_mapping = {
        'Passed': 'gold',
        'Not tested': 'silver',
        'Failed': 'bronze'
      }
      return quality_level_mapping[quality_level]
    },
    getBadgeColor(quality_level) {
      const color_mapping = {
        Passed: 'green',
        'Not tested': 'yellow',
        Failed: 'red'
      }
      return color_mapping[quality_level]
    },
    getBadgeLabel(quality_level) {
      const quality_level_mapping = {
        Passed: 'High',
        'Not tested': 'Medium',
        Failed: 'Low'
      }
      return quality_level_mapping[quality_level]
    },
    makeBadgeURL(quality) {
      const quality_level_mapping = {
        Passed: 'high',
        "Not tested": 'medium',
        Failed: 'low'
      }
      const color_mapping = {
        Passed: 'FFD700',
        "Not tested": 'C0C0C0',
        Failed: 'CD7F32'
      }
      // const URL = 'https://badgen.net/badge/quality/' + quality_level_mapping[quality]  + '/' +
      const URL = 'https://img.shields.io/static/v1?style=flat&label=quality&color=' + color_mapping[quality] + '&message=' + quality_level_mapping[quality] + '&style=flat'
      // console.log(URL)
      return URL
    },
    AMPDetail(accession) {
      window.open('/amp?accession=' + accession, '_blank')
    },
    familyDetail(accession) {
      window.open('/family?accession=' + accession, '_blank')
    },
    setLoading(isLoading) {
      if (isLoading) {
        this.axiosRefCount++;
        this.loading = true;
      } else if (this.axiosRefCount > 0) {
        this.axiosRefCount--;
        this.loading = (this.axiosRefCount > 0);
      }
    },
    async downloadSearchResults() {
      const ObjectsToCsv = require('objects-to-csv');
      const data = new ObjectsToCsv(this.amps);
      const str = await data.toString()
      const blob = new Blob([str], {type: "text/plain;charset=utf-8"});
      saveAs(blob, "AMPs.csv");
    },
    inDBChecking(val, entity_type){
      self = this
      this.axios.get('/in_db/' + entity_type + '/' + val)
          .then(function (response) {
            console.log(entity_type, val, response.data)
            if (entity_type === 'family'){
              self.familyInDB = response.data
            }
            if (entity_type === 'sample' || entity_type === 'genome'){
              self.sampleInDB = response.data
            }
          })
          .catch(function (error) {
            console.log(error);
            if (entity_type === 'family'){
              self.familyInDB = false
            }
            if (entity_type === 'sample' || entity_type === 'genome'){
              self.sampleInDB = false
            }
          })
    }
  }
}
</script>
