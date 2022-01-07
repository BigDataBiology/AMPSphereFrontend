<template>
  <div class="BrowseData">
    <div class="row justify-center">
      <div class="col-xs-0 col-xl-2 bg-white"></div>
      <div class="col-12 col-xl-8 justify-center q-pa-auto">
        <div class="row">
          <div class="col-12 col-md-3 q-pa-sm">
            <div style="position: fixed; display: block; top: 180px; height: 500px">
              <div class="row q-px-xs q-py-xs filter-subsection-title">Filter by metadata</div>
              <div class="row q-px-md q-py-xs">
                <q-select filled v-model="options.habitat" label="Habitat" @update:model-value="onHabitatChange"
                          :options="availableOptions.habitat" @filter="filterHabitat"
                          input-debounce="0" use-input fill-input hide-selected style="width: 250px"
                          behavior="menu" align="center" clearable/>
              </div>
              <br/>
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
                         :min="availableOptions.pep_length.min" style="width: 240px"
                         :max="availableOptions.pep_length.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Molecular weight:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.molecular_weight.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.molecular_weight.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.molecular_weight" @change="onMWChange"
                         :min="availableOptions.molecular_weight.min" style="width: 240px"
                         :max="availableOptions.molecular_weight.max" label color="secondary"/>

              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Isoelectric point:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.isoelectric_point.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.isoelectric_point.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.isoelectric_point" @change="onpIChange"
                         :min="availableOptions.isoelectric_point.min" style="width: 240px"
                         :max="availableOptions.isoelectric_point.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Charge at pH 7.0:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.charge_at_pH_7.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.charge_at_pH_7.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.charge_at_pH_7" @change="onChargechange"
                         :min="availableOptions.charge_at_pH_7.min" label style="width: 240px"
                         :max="availableOptions.charge_at_pH_7.max" color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Advanced filters</div>
<!--              TODO　Add in database checking-->
              <div class="row q-px-md q-py-xs">
                <q-input v-model.number="options.family" type="text" label="Family" filled/>
                <br/>
              </div>
              <div class="row q-px-md q-py-xs">
                <q-input v-model.number="options.sample" type="text" label="Sample/Genome" filled/>
              </div>
            </div>
          </div>

          <div class="col-12 col-md-9 q-py-sm q-px-lg">
            <!--            <q-page padding>-->
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
                  <q-img :src="makeBadgeURL(props.row.quality.badge)" height="70%" fit="scale-down"></q-img>
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
      // family: [],
      habitat: [],
      // sample: [],
      microbial_source: [],
      pep_length: {min: 8, max: 98},
      molecular_weight: {min: 813, max: 12286},
      isoelectric_point: {min: 4, max: 12},
      charge_at_pH_7: {min: -57, max: 44}
    }
    return {
      drawerOpen: true,
      miniState: true,
      loading: false,
      amps: [],
      axiosRefCount: 0,
      info: {currentPage: 1, pageSize: 20, totalRow: 0, totalPage: 1,},
      options: {
        family: null, habitat: null, sample: null, microbial_source: null,
        pep_length: {min: 8, max: 99},
        molecular_weight: {min: 813, max: 12286},
        isoelectric_point: {min: 4, max: 12},
        charge_at_pH_7: {min: -57, max: 44}
      },
      avalOptionsFull: options_full,
      availableOptions: options_full,
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
  },
  computed: {},
  methods: {
    setAMPsPage(page) {
      this.info.currentPage = page - 1
      console.log(this.info.currentPage)
      let config = {
        params: {
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
      // this.showLoading()
      let self = this
      this.axios.get('/all_available_options')
          .then(function (response) {
            console.log(response.data)
            self.avalOptionsFull = Object.assign({}, response.data)
            self.availableOptions = response.data
          })
          .catch(function (error) {
            console.log(error);
          })
      // this.closeLoading()
    },
    // filterFamily(val, update, abort){
    //   update(() => {
    //     val = val.toLowerCase()
    //     this.availableOptions.family = this.avalOptionsFull.family.filter(v => v.toLowerCase().indexOf(val) > -1)
    //   })
    // },
    // filterSample(val, update, abort){
    //   update(() => {
    //     val = val.toLowerCase()
    //     this.availableOptions.sample = this.avalOptionsFull.sample.filter(v => v.toLowerCase().indexOf(val) > -1)
    //   })
    // },
    filterHabitat(val, update, abort) {
      update(() => {
        val = val.toLowerCase()
        this.availableOptions.habitat = this.avalOptionsFull.habitat.filter(v => v.toLowerCase().indexOf(val) > -1)
      })
    },
    filterMicrobialSource(val, update, abort) {
      update(() => {
        val = val.toLowerCase()
        this.availableOptions.microbial_source = this.avalOptionsFull.microbial_source.filter(v => v.toLowerCase().indexOf(val) > -1)
      })
    },
    // onFamilyChange(option) {
    //   this.options.family = option;
    //   this.setAMPsPage(1)
    // },
    onHabitatChange(option) {
      this.options.habitat = option;
      this.setAMPsPage(1)
    },
    // onSampleChange(option) {
    //   this.options.sample = option;
    //   this.setAMPsPage(1)
    // },
    onMicrobialSourceChange(option) {
      this.options.microbial_source = option;
      this.setAMPsPage(1)
    },
    onPepLengthChange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('peplength changed.')
      this.setAMPsPage(1)
    },
    onMWChange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('MW changed.')
      this.setAMPsPage(1)
    },
    onpIChange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('pI changed.')
      this.setAMPsPage(1)
    },
    onChargechange(value) {
      // this.options.pep_length = {min: 0, max: 100}
      console.log('Charge changed.')
      this.setAMPsPage(1)
    },
    clearFilters() {
      this.options = {
        family: null,
        habitat: null,
        sample: null,
        microbial_source: null,
        pep_length: {
          min: 0,
          max: 100
        }
      }
    },
    initQualityTag(amps) {
      for (let i = 0; i < amps.length; i++) {
        Object.assign(amps[i], {quality_tag: {msg: 'Not available', level: 'warning'}})
      }
      return amps
    },
    getBadgeColor(quality_level) {
      const color_mapping = {
        gold: 'green',
        silver: 'yellow',
        bronze: 'red'
      }
      return color_mapping[quality_level]
    },
    getBadgeLabel(quality_level) {
      const quality_level_mapping = {
        gold: 'High',
        silver: 'Medium',
        bronze: 'Low'
      }
      return quality_level_mapping[quality_level]
    },
    makeBadgeURL(quality) {
      const quality_level_mapping = {
        gold: 'high',
        silver: 'medium',
        bronze: 'low'
      }
      const color_mapping = {
        gold: 'FFD700',
        silver: 'C0C0C0',
        bronze: 'CD7F32'
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
    }
  }
}
</script>
