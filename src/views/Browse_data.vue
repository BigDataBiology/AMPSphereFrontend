<template>
  <div class="BrowseData">
    <div class="row justify-center">
      <div class="col-xs-0 col-xl-2 bg-white"></div>
      <div class="col-12 col-xl-8 justify-center q-pa-auto">
        <div class="row">
          <div class="col-12 col-md-3 q-pa-sm">
            <div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Select columns to show</div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="showColumns.sequence" label="Peptide sequence" icon="check" />
              </div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="showColumns.num_genes" label="Number of smORF genes" icon="check" />
                <q-icon name="help" class="q-ml-xs" size="16px" color="grey-7">
                  <q-tooltip
                    transition-show="scale"
                    transition-hide="scale"
                    hide-delay="2500"
                    class="bg-amber text-black shadow-4 text-body2"
                  >Number of smORFs that encode the peptide. A peptide can be found in multiple samples/genome and slightly different DNA sequences can code for the same peptide</q-tooltip>
              </q-icon>
              </div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="showColumns.pI" label="Isoelectric point" icon="check" />
              </div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="showColumns.molecular_weight" label="Molecular weight" icon="check" />
              </div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="showColumns.quality" label="Quality" icon="check" />
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Filter by quality</div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="hqOnly" label="High-quality only" @update:model-value="onHQChange" icon="check" />
                <q-icon name="help" class="q-ml-xs" size="16px" color="grey-7">
                  <q-tooltip
                    transition-show="scale"
                    transition-hide="scale"
                    hide-delay="2500"
                    class="bg-amber text-black shadow-4 text-body2"
                  >High-quality predictions are those that have passed all <i>in silico</i> tests.
                  </q-tooltip>
                  </q-icon>
              </div>
              <div class="row q-px-md q-py-xs">
                <q-toggle v-model="options.exp_evidence" label="With matched experimental data only"
                       @update:model-value="onExpEvidenceChange"
                          hint="transcription/translation"
                          icon="check"
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
                <q-range v-model="options.pep_length" @change="refreshSearch"
                         :min="staticOptions.pep_length.min" :max="staticOptions.pep_length.max"
                         :inner-min="filteredAvailableOptions.pep_length.min" style="width: 240px"
                         :inner-max="filteredAvailableOptions.pep_length.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Molecular weight:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.molecular_weight.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.molecular_weight.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.molecular_weight" @change="refreshSearch"
                         :min="staticOptions.molecular_weight.min" :max="staticOptions.molecular_weight.max"
                         :inner-min="filteredAvailableOptions.molecular_weight.min" style="width: 240px"
                         :inner-max="filteredAvailableOptions.molecular_weight.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Isoelectric point:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.isoelectric_point.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.isoelectric_point.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.isoelectric_point" @change="refreshSearch"
                         :min="staticOptions.isoelectric_point.min" :max="staticOptions.isoelectric_point.max"
                         :inner-min="filteredAvailableOptions.isoelectric_point.min" style="width: 240px"
                         :inner-max="filteredAvailableOptions.isoelectric_point.max" label color="secondary"/>
              </div>
              <div class="row q-px-xs q-py-xs filter-subsection-title">Charge at pH 7.0:</div>
              <div class="row q-px-md">
                <!--                    <q-input v-model.number="options.charge_at_pH_7.min" type="number" label="Min" filled style="max-width: 100px" /> &nbsp; &nbsp;-->
                <!--                    <q-input v-model.number="options.charge_at_pH_7.max" type="number" label="Max" filled style="max-width: 100px" />-->
                <q-range v-model="options.charge_at_pH_7" @change="refreshSearch"
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
                    <q-input v-model="options.sample" type="text" label="Sample/Genome" filled style="width: 250px"
                             v-if="!isSampleMode"
                             :error="(!sampleInDB && options.sample !== '')" lazy-rules
                             @change="onSampleChange" clearable @clear="onSampleClear"
                             error-message="The input does not match any sample/genome" />
                  </div>
                </div>
              </q-slide-transition>
            </div>
          </div>

          <div class="col-12 col-md-9 q-py-sm q-px-lg">
            <div class="row text-h4" v-if="isSampleMode">
                AMPs in sample {{ options.sample }}
            </div>
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
              <el-table-column label="Peptide sequence" width="300%" v-if="showColumns.sequence">
                <template #default="props">
                  <code class="sequence">{{ props.row.sequence }}</code>
                </template>
              </el-table-column>
              <el-table-column label="# smORF genes" width="120%" align="right" v-if="showColumns.num_genes">
                <template #default="props">
                  <span>{{ props.row.num_genes.toLocaleString() }}</span>
                </template>
              </el-table-column>
              <el-table-column label="Molecular weight" width="150%" align="right" v-if="showColumns.molecular_weight">
                <template #default="props">
                  <span>{{ props.row.molecular_weight.toFixed(2) }}</span>
                </template>
              </el-table-column>
              <el-table-column label="Isoelectric point" width="130%" align="right" v-if="showColumns.pI">
                <template #default="props">
                  <span>{{ props.row.isoelectric_point.toFixed(2) }}</span>
                </template>
              </el-table-column>
              <el-table-column label="Quality" width="150%" v-if="showColumns.quality">
                <template #default="props">
                  <div class="text-left text-bold">
                    <span :style="greenRed(hasEvidence(props.row))">E
                        <q-tooltip max-width="30rem">Has experimental evidence
                        ({{ hasEvidence(props.row) ? "Passed" : "Failed" }})</q-tooltip></span> -
                    <span :style="greenRed(props.row.RNAcode === 'Passed')">R
                        <q-tooltip max-width="30rem">RNAcode ({{ props.row.RNAcode }})</q-tooltip></span> -
                    <span :style="greenRed(props.row.Antifam === 'Passed')">A
                        <q-tooltip max-width="30rem">Antifam ({{ props.row.Antifam }})</q-tooltip></span> -
                    <span :style="greenRed(props.row.coordinates === 'Passed')">T
                        <q-tooltip max-width="30rem">Terminal placement ({{ props.row.coordinates }})</q-tooltip></span>
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
import {} from 'quasar'
import { saveAs } from 'file-saver';


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
      showColumns: {
        sequence: true,
        num_genes: true,
        molecular_weight: false,
        pI: false,
        charge: false,
        quality: true,
      },
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
      filteredAvailableOptions: options_full,
      isSampleMode: false
    }
  },
  setup() {
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
    if (this.$route.query.sample) {
      this.options.sample = this.$route.query.sample
      this.isSampleMode = true
      this.inDBChecking(this.options.sample, 'sample')
    }
    this.setAMPsPageSize(100)
    this.getAvailableOptions()
  },
  computed: {},
  methods: {
    getParams(){
      let params = {
          exp_evidence: this.options.exp_evidence ? "Passed" : null,
          antifam: this.options.antifam,
          RNAcode: this.options.RNAcode,
          coordinates: this.options.coordinates,
          family: this.options.family,
          habitat: this.options.habitat,
          host: this.options.host,
          sample_genome: this.options.sample,
          microbial_source: this.options.microbial_source,
          page: this.info.currentPage,
          page_size: this.info.pageSize
      };
      function setOptionIfNotDefault(optName, optValue, defValue) {
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
      let config = {
        params: this.getParams()
      }
      let self = this
      this.axios.get('/amps', config)
          .then(function (response) {
            self.amps = response.data.data
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
            self.staticOptions = Object.assign({}, response.data)
            self.availableOptions = response.data
          })
          .catch(function (error) {
            console.log(error);
          })
    },
    filterHabitat(val, update) {
      update(() => {
        val = val.toLowerCase()
        this.availableOptions.habitat = this.staticOptions.habitat.filter(v => v.toLowerCase().indexOf(val) > -1)
      })
    },
    filterMicrobialSource(val, update) {
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
    refreshSearch() {
        this.hqOnly = (
            this.options.antifam == "Passed" &&
            this.options.coordinates == "Passed" &&
            this.options.RNAcode == "Passed"
            );
      this.setAMPsPage(1)
    },
    onExpEvidenceChange(option){
      this.options.exp_evidence = option
      this.setAMPsPage(1)
    },
    onAntifamChange(option){
      this.options.antifam = option
      this.refreshSearch()
    },
    onRNAcodeChange(option){
      this.options.RNAcode = option
      this.refreshSearch()
    },
    onCoordinatesChange(option){
      this.options.coordinates = option
      this.refreshSearch()
    },
    onAntifamClear(){
      this.options.antifam = null
      this.refreshSearch()
    },
    onRNAcodeClear(){
      this.options.RNAcode = null
      this.refreshSearch()
    },
    onCoordinatesClear(){
      this.options.coordinates = null
      this.refreshSearch()
    },
    onFamilyChange() {
      this.inDBChecking(this.options.family, 'family')
      this.setAMPsPage(1)
    },
    onSampleChange() {
      this.inDBChecking(this.options.sample, 'sample')
      this.setAMPsPage(1)
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
    },
    onMicrobialSourceChange(option) {
      this.options.microbial_source = option;
      this.setAMPsPage(1)
    },
    onHabitatClear(){
      this.options.habitat = ''
      this.onHabitatChange(this.options.habitat)
    },
    onMicrobialSourceClear(){
      this.options.microbial_source = ''
      this.onMicrobialSourceChange(this.options.microbial_source)
    },
    greenRed(val) {
      return {
          color: val ? 'green' : 'red'
      }
    },
    hasEvidence(AMP) {
      return (AMP.metaproteomes === "Passed" || AMP.metatranscriptomes === "Passed");
    },
    makeBadgeURL(name, test_result) {
      const color_mapping = {
        Passed: 'green',
        "Not tested": 'yellow',
        Failed: 'red'
      }
      const URL = 'https://img.shields.io/static/v1?style=flat&label=' + name + '&color=' + color_mapping[test_result] + '&message=' + test_result + '&style=flat'
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
      let self = this;
      this.axios.get('/in_db/' + entity_type + '/' + val)
          .then(function (response) {
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
