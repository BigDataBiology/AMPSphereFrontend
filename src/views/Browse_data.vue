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
                <q-toggle v-model="hqOnly" label="High-quality only" left-label @update:model-value="onHQChange" />
              </div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="options.exp_evidence" label="With matched experimental data only" left-label
                       @update:model-value="onExpEvidenceChange"
                          hint="transcription/translation"
                          clearable/>
              </div>
              <div class="row q-px-xs q-py-xs filter-toggle-label">
                 <q-toggle v-model="qualitySpecFiltersVisible" label="Specific tests" left-label />
              </div>
              <q-slide-transition>
                <div v-show="qualitySpecFiltersVisible">
                  <div class="row q-px-md q-py-xs">
                    <q-select filled v-model="options.antifam" label="Antifam" @update:model-value="onAntifamChange"
                          :options="['Passed', 'Failed']" @clear="onAntifamClear"
                          style="width: 250px" behavior="menu" align="center" clearable/>
                  </div>
                  <div class="row q-px-md q-py-xs">
                    <q-select filled v-model="options.RNAcode" label="RNAcode" @update:model-value="onRNAcodeChange"
                          :options="['Passed', 'Failed']" @clear="onRNAcodeClear"
                          style="width: 250px" behavior="menu" align="center" clearable/>
                  </div>
                  <div class="row q-px-md q-py-xs">
                    <q-select filled v-model="options.coordinates" label="terminal placement" @update:model-value="onCoordinatesChange"
                          :options="['Passed', 'Failed']" @clear="onCoordinatesClear"
                          style="width: 250px" behavior="menu" align="center" clearable/>
                  </div>
                </div>
              </q-slide-transition>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Filter by metadata</div>
              <div class="row q-px-md q-py-xs">
                <q-select filled v-model="options.habitat" label="Habitat" @update:model-value="onHabitatChange"
                          :options="availableOptions.habitat" @filter="filterHabitat" @clear="onHabitatClear"
                          input-debounce="0" use-input fill-input hide-selected style="width: 250px"
                          behavior="menu" align="center" clearable/>
              </div>
              <div class="row q-px-md">
                <q-select filled v-model="options.microbial_source" label="Microbial source"
                          @update:model-value="onMicrobialSourceChange" @clear="onMicrobialSourceClear"
                          :options="availableOptions.microbial_source" @filter="filterMicrobialSource"
                          style="width: 250px"
                          input-debounce="0" use-input fill-input hide-selected hint="GTDB taxonomy name"
                          behavior="menu" align="center" clearable/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Peptide length:</div>
              <div class="row q-px-md">
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
              <div class="col-6 main-text">Displaying: <span v-if="info.totalRow >= info.pageSize">{{info.pageSize}}</span> <span v-else>{{ info.totalRow.toLocaleString() }}</span> out of {{ info.totalRow.toLocaleString() }} results.</div>
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
		  <a :href="'/amp?accession=' + props.row.accession"> {{ props.row.accession }}</a>
                </template>
              </el-table-column>
              <el-table-column label="Family" width="150%">
                <template #default="props">
                  <a :href="'/family?accession=' + props.row.family">{{ props.row.family }}</a>
                </template>
              </el-table-column>
              <el-table-column label="Peptide sequence" width="300%">
                <template #default="props">
                  <pre><code><small>{{ props.row.sequence }}</small></code></pre>
                </template>
              </el-table-column>
              <el-table-column label="# smORF genes" width="120%">
                <template #default="props">
                  <span>{{ props.row.num_genes.toLocaleString() }}</span>
                </template>
              </el-table-column>
              <el-table-column label="Quality" width="150%">
                <template #default="props">
                  <div class="text-left text-bold">
                    <font :color="hasEvidence(props.row) === 'Passed'?'green':'red'">E<q-tooltip max-width="30rem">Has experimental evidence ({{ hasEvidence(props.row) }})</q-tooltip></font> -
                    <font :color="props.row.RNAcode === 'Passed'?'green':'red'">R<q-tooltip max-width="30rem">RNAcode ({{ props.row.RNAcode }})</q-tooltip></font> -
                    <font :color="props.row.Antifam === 'Passed'?'green':'red'">A<q-tooltip max-width="30rem">Antifam ({{ props.row.Antifam }})</q-tooltip></font> -
                    <font :color="props.row.coordinates === 'Passed'?'green':'red'">T<q-tooltip max-width="30rem">Terminal placement ({{ props.row.coordinates }})</q-tooltip></font>
                  </div>
                </template>
              </el-table-column>
            </el-table>
            <el-pagination @size-change="setAMPsPageSize" @current-change="setAMPsPage" :page-sizes="[100, 200, 500, 1000]"
                           :page-size="100" layout="sizes, pager, jumper" :total="info.totalRow">
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
      pep_length: {min: 8, max: 99},
      molecular_weight: {min: 813, max: 12286},
      isoelectric_point: {min: 4, max: 12},
      charge_at_pH_7: {min: -57, max: 44}
    }
    return {
      advancedFiltersVisible: false,
      qualitySpecFiltersVisible: false,
      hqOnly: false,
      familyInDB: true,
      sampleInDB: true,
      loading: false,
      amps: [],
      axiosRefCount: 0,
      info: {currentPage: 1, pageSize: 100, totalRow: 0, totalPage: 1,},
      options: {
        exp_evidence: false, antifam: null, RNAcode: null, coordinates: null,
        family: null, habitat: null, sample: null, microbial_source: null,
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
    this.setAMPsPageSize(100)
    this.getAvailableOptions()
    // this.grayOutOptions()
  },
  computed: {},
  methods: {
    getParams(){
      let params = {
          exp_evidence: this.options.exp_evidence ? "Passed" : null,
          antifam: this.options.antifam,
          RNAcode: this.options.RNAcode,
          coordinates: this.options.coordinates,  // four filters to be added.
          family: this.options.family,
          habitat: this.options.habitat,
          host: this.options.host,
          sample: this.options.sample,
          microbial_source: this.options.microbial_source,
          page: this.info.currentPage,
          page_size: this.info.pageSize
      };
      function setOptionIfNotDefault(optName, optValue, defValue) {
          console.log("Checking for " + optName + " " +
                 optValue.min.toString() + " != " +defValue.min.toString() + " || " + optValue.max.toString() + " != " + defValue.max.toString());
          if (optValue.min != defValue.min || optValue.max != defValue.max) {
              params[optName] = optValue.min.toString() + ',' + optValue.max.toString();
          }
      }
      setOptionIfNotDefault('pep_length_interval', this.options.pep_length, this.availableOptions.pep_length);
      setOptionIfNotDefault('pI_interval', this.options.isoelectric_point, this.availableOptions.isoelectric_point);
      setOptionIfNotDefault('mw_interval', this.options.molecular_weight, this.availableOptions.molecular_weight);
      setOptionIfNotDefault('charge_interval', this.options.charge_at_pH_7, this.availableOptions.charge_at_pH_7);

      return params;
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
            self.amps = response.data.data
            for(let amp of self.amps){
              amp.num_genes = amp.metadata.info.totalItem
              delete amp.metadata
              delete amp.secondary_structure
            }
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
    onHQChange(option) {
        if (option) {
            this.options.antifam = "Passed"
            this.options.coordinates = "Passed"
            this.options.RNAcode = "Passed"
        } else {
            this.options.antifam = null
            this.options.coordinates = null
            this.options.RNAcode = null
        }
        this.setAMPsPage(1)
    },
    recomputeHQOnly() {
        this.hqOnly = (
            this.options.antifam == "Passed" &&
            this.options.coordinates == "Passed" &&
            this.options.RNAcode == "Passed"
            );
    },
    onExpEvidenceChange(option){
      this.options.exp_evidence = option
      this.setAMPsPage(1)
    },
    onAntifamChange(option){
      this.options.antifam = option
      this.recomputeHQOnly()
      this.setAMPsPage(1)
    },
    onRNAcodeChange(option){
      this.options.RNAcode = option
      this.recomputeHQOnly()
      this.setAMPsPage(1)
    },
    onCoordinatesChange(option){
      this.options.coordinates = option
      this.recomputeHQOnly()
      this.setAMPsPage(1)
    },
    onAntifamClear(option){
      this.options.antifam = null
      this.recomputeHQOnly()
      this.setAMPsPage(1)
    },
    onRNAcodeClear(option){
      this.options.RNAcode = null
      this.recomputeHQOnly()
      this.setAMPsPage(1)
    },
    onCoordinatesClear(option){
      this.options.coordinates = null
      this.recomputeHQOnly()
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
    onMicrobialSourceChange(option) {
      this.options.microbial_source = option;
      this.setAMPsPage(1)
      // this.grayOutOptions()
    },
    onHabitatClear(){
      this.options.habitat = ''
      this.onHabitatChange(this.options.habitat)
    },
    onMicrobialSourceClear(){
      this.options.microbial_source = ''
      this.onMicrobialSourceChange(this.options.microbial_source)
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
    hasEvidence(AMP){
      if (AMP.metaproteomes === 'Passed' || AMP.metatranscriptomes === 'Passed'){
        return "Passed"
      } else {
        return "Failed"
      }
    },
    makeBadgeURL(name, test_result) {
      const color_mapping = {
        Passed: 'green',
        "Not tested": 'yellow',
        Failed: 'red'
      }
      // const URL = 'https://badgen.net/badge/quality/' + quality_level_mapping[quality]  + '/' +
      const URL = 'https://img.shields.io/static/v1?style=flat&label=' + name + '&color=' + color_mapping[test_result] + '&message=' + test_result + '&style=flat'
      // console.log(URL)
      return URL
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
