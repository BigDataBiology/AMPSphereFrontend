<template>
  <div id="Downloads">
    <div class="row justify-center">
      <div class="col-xs-0 col-xl-2 bg-white"></div>
      <div class="col-12 col-xl-8 justify-center q-pr-md q-ma-auto">
        <div class="subsection-title">Core resources</div>.
        <el-table :data="downloadable_files" width="100%">
          <el-table-column prop="name" label="Name" width="200%"></el-table-column>
          <el-table-column prop="type" label="Type" width="150%"></el-table-column>
          <el-table-column label="URL" width="150%">
            <template #default="props">
              <!-- <el-button @click="download(props.row.file)" label="download"></el-button> -->
              <a :href="props.row.file" :download="props.row.file.split('/').pop()">Download</a>
            </template>
          </el-table-column>
          <el-table-column prop="desc" label="Description" width="700%"></el-table-column>
        </el-table>
        <el-divider></el-divider>
<!--        <div class="subsection-title">Full AMPSphere data</div>-->
        <div style="text-align: left">
          Browse our
          <el-link href="https://doi.org/10.5281/zenodo.4574468" type="primary">
            Zenodo page
          </el-link>
          to see all the resources.
        </div>
      </div>
      <div class="col-xs-0 col-xl-2 bg-white"></div>
    </div>
  </div>
</template>

<script>
export default {
  name: "Downloads",
  data () {
    let prefix = this.axios.defaults.baseURL
    return {
      downloadable_files: [
        {
          name: 'AMPSphere database',
          type: 'Full database',
          file: prefix + "/downloads/AMPSphere_latest.sqlite",
          desc: "Full sqlite3 database containing all individual tables below.",
        },
        {
          name: "AMP",
          type: "Individual table",
          file: prefix + "/downloads/AMP.tsv",
          desc: "All AMP families and sequences."
        },
        {
          name: "GMSC and Metadata",
          type: "Individual table",
          file: prefix + "/downloads/GMSCMetadata.tsv",
          desc: "All AMP-associated smORF genes, sequences and associated metadata (microbial source, habitats, etc.)."
        },
        {
          name: "MMseqs database",
          type: "Search database",
          file: prefix + "/downloads/AMPSphere_latest.mmseqsdb.tar.xz",
          desc: 'Search database for offline or large scale query, can be directly used by the MMseqs software.'
        },
        {
          name: "HMM profile database",
          type: "Search database",
          file: prefix + "/downloads/AMPSphere_latest.hmm",
          desc: 'Search database for offline or large scale query, can be directly used by the HMMER software.'
        },
        {
          name: "AMP density for samples",
          type: "Search database",
          file: prefix + "/downloads/amp_density_per_sample.tsv.gz",
          desc: 'AMP density data accounting for all AMPs in AMPSphere and assembled base pairs in the metagenome samples.'
        },
        {
          name: "AMP density for species",
          type: "Search database",
          file: prefix + "/downloads/amp_density_per_species_and_sample.tsv.gz",
          desc: 'AMP density data accounting only for contigs with taxonomy in the metagenome samples.'
        }
      ]
    }
  },
  methods: {
    download(url) {
      this.axios.get(url, {responseType: 'arraybuffer'})
      .then(function (response) {
          var headers = response.headers();
          var blob = new Blob([response.data],{type:headers['content-type']});
          var link = document.createElement('a');
          link.href = window.URL.createObjectURL(blob);
          // link.download = filename;
          link.click();
          })
          .catch(function (error) {
            console.log(error);
          })
    }
  }
}
</script>

<style scoped>

</style>
