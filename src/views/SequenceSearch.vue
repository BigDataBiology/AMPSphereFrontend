<template>
  <div id="SequenceSearch">
    <div class="row justify-center">
      <div class="col-xs-0 col-lg-2 bg-white"></div>
      <div class="col-12 col-lg-8 justify-center q-pr-md q-ma-auto">
        <div class="row">
          <div class="col-12" v-if="result.length === 0 && updated">
            <div class="info-item-value text-center h3">
              No matching AMP found for your sequence(s).
            </div>
            <!--        <el-empty :image-size="200" description=""></el-empty>-->
          </div>
          <div class="col-12" v-else-if="method === 'MMseqs'">
            <div class="row">
              <div class="col-12 col-lg-2 offset-lg-10">
                <el-button @click="downloadSearchResults" type="primary">
                  <BootstrapIcon icon="cloud-download" variant="light" size="1x" />
                  Download as CSV
                </el-button>
              </div>
            </div>
            <el-table :data="result" stripe style="width: 100%" v-loading="loading">
              <el-table-column label="Query" prop="query_identifier" :filters="queryFilters" :filter-method="filterTable" width="150"></el-table-column>
              <el-table-column label="Target" width="150">
                <template #default="props">
                  <el-button type="text" @click="AMPDetail(props.row.target_identifier)">{{ props.row.target_identifier }}</el-button>
                </template>
              </el-table-column>
              <el-table-column label="Family" width="150">
                <template #default="props">
<!--                  <el-button type="text" @click="familyDetail(props.row.family)">-->
                    {{ props.row.family }}
<!--                  </el-button>-->
                </template>
              </el-table-column>
              <el-table-column label="Identity (%)" sortable width="150">
                <template #default="props">
                  {{ (props.row.sequence_identity * 100).toFixed(3) }}
                </template>
              </el-table-column>
<!--              <el-table-column label="Aligned length" sortable prop="alignment_length"></el-table-column>-->
              <el-table-column label="# mismatches" sortable width="200" prop="number_mismatches"></el-table-column>
              <el-table-column label="# gap" sortable width="100" prop="number_gap_openings"></el-table-column>
              <el-table-column label="E value" sortable width="100" prop="E_value"></el-table-column>
              <el-table-column label="Bit score" sortable width="100" prop="bit_score"></el-table-column>
              <el-table-column type="expand" width="100" label="Alignment">
                <template #default="props">
                  <div class="justify-center">
<!--                    TODO Restyle this.-->
                    <code><pre>
                              {{props.row.domain_start_position_query}}{{'-'.repeat(props.row.domain_end_position_query - props.row.domain_start_position_query - 1)}}{{props.row.domain_end_position_query}}
                      Query:  {{props.row.alignment_strings[0]}}
                              {{props.row.alignment_strings[1]}}
                      Target: {{props.row.alignment_strings[2]}}
                              {{props.row.domain_start_position_target}}{{'-'.repeat(props.row.domain_end_position_target - props.row.domain_start_position_target - 1)}}{{props.row.domain_end_position_target}}
                    </pre></code>
                  </div>
                </template>
              </el-table-column>
            </el-table>

          </div>
          <div class="col-12" v-else-if="method === 'HMMER'">
            <div class="row">
              <div class="col-12 col-lg-2 offset-lg-10">
                <el-button @click="downloadSearchResults" type="primary">
                  <BootstrapIcon icon="cloud-download" variant="light" size="1x" />
                  Download as CSV
                </el-button>
              </div>
            </div>
            <el-table :data="result" stripe style="width: 100%" v-loading="loading">
              <el-table-column label="Query" prop="query_name" :filters="queryFilters" :filter-method="filterTable"></el-table-column>
              <el-table-column label="Target" width="200">
                <template #default="props">
                  <el-button type="text" @click="familyDetail(props.row.target_name)">{{ props.row.target_name }}</el-button>
                </template>
              </el-table-column>
              <el-table-column label="Reliability" sortable prop="acc"></el-table-column>
              <el-table-column label="Bias" sortable prop="bias"></el-table-column>
              <el-table-column label="E-value" sortable prop="E_value"></el-table-column>
              <el-table-column label="C E-value" sortable prop="c_Evalue"></el-table-column>
              <el-table-column label="I E-value" sortable prop="i_Evalue"></el-table-column>
              <el-table-column label="Bit score" sortable prop="score"></el-table-column>
            </el-table>
          </div>
        </div>
      </div>
      <div class="col-xs-0 col-lg-2 bg-white"></div>
    </div>
  </div>
</template>

<script>
import { saveAs } from 'file-saver';


export default {
  name: "SequenceSearch",
  data() {
    return {
      method: '',
      sequences: '',
      searchParameters: [
        {param_name: '...', value: '...'}
        // TODO update this
      ],
      searchCommand: 'mmseqs createdb {query_seq} {query_seq}.mmseqsdb &&  \\\n' +
          'mmseqs search {query_seq}.mmseqsdb  {database} {out}.mmseqsdb {tmp_dir} &&  \\\n' +
          'mmseqs convertalis {query_seq}.mmseqsdb {database} {out}.mmseqsdb {out}',
      result: [],
      updated: false,
      queryFilters: [],
      loading: false
    }
  },
  created(){
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
    this.getParams()
    this.search()
  },
  mounted(){

  },
  computed(){

  },
  methods: {
    getParams(){
      this.method = this.$route.query.method
      this.sequences = this.$route.query.queries
    },
    search(){
      let self = this
      let path = ''
      if (this.method === 'MMseqs') {path = '/search/mmseqs'}
      else if (this.method === 'HMMER'){path = '/search/hmmer'}
      else{path = ''}
      let config = {params: {query: this.sequences}}
      this.axios.get(path, config)
        .then(function (response) {
          if (response.data) {
            self.result = response.data
          } else {
            self.result = []
          }
          self.updated = true
          self.queryFilters = []
          let included = []
          for (let i = 0; i < self.result.length; i++) {
            let query
            if (self.method === 'MMseqs') {
                query = self.result[i].query_identifier
            } else if (self.method === 'HMMER') {
                query = self.result[i].query_name
            } else {
                console.log('no matching method.')
            }
            if (!included.includes(query)) {
              included.push(query)
              self.queryFilters.push({text: query, value: query})
            }
          }
        })
        .catch(function (error) {
          self.result = []
          self.updated = true
          console.log(error);
        })
    },
    updateMMseqsQueryFilters() {
      this.queryFilters = []
      let included = []
      for (let i = 0; i < this.result.length; i++) {
        let query = this.result[i].query_identifier
        if (!included.includes(query)) {
          included.push(query)
          this.queryFilters.push({text: query, value: query})
        }
      }
    },
    updateHMMERQueryFilters() {
      this.queryFilters = []
      let included = []
      for (let i = 0; i < this.result.length; i++) {
        let query = this.result[i].query_name
        if (!included.includes(query)) {
          included.push(query)
          this.queryFilters.push({text: query, value: query})
        }
      }
    },
    filterTable(value, row, column) {
      const property = column['property']
      return row[property] === value
    },
    AMPDetail(accession){
      window.open('/amp?accession='+accession, '_blank')
    },
    familyDetail(accession){
      window.open('/family?accession='+accession, '_blank')
    },
    async downloadSearchResults() {
      const ObjectsToCsv = require('objects-to-csv');
      const data = new ObjectsToCsv(this.result);
      const str = await data.toString()
      const blob = new Blob([str], {type: "text/plain;charset=utf-8"});
      saveAs(blob, "searchResults.csv");
    },
  }
}
</script>

<style scoped>

</style>
