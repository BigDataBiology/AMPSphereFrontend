<template>
  <div class="AMP_card">
    <div class="row justify-center">
      <div class="col-xs-0 col-xl-2 bg-white"></div>
      <div class="col-12 col-xl-8 justify-center q-pr-md q-ma-auto">
        <div class="row text-center">
          <div class="col-12 text-h4">
            Antimicrobial peptide: {{ amp.accession }}<br/><br/>
          </div>
          <div class="col-10 justify-center" style="display: inline-flex; height: 100%; width: 100%">
            <img :src="makeQualityBadge('Antifam', amp.Antifam)" fit="scale-down"
                  alt="Quality badge cannot be shown. Please check your internet connection."
                  title="Search against Antifam, a database of profile-HMMs created from translations of commonly occurring non-coding RNAs"/> &nbsp; &nbsp;
            <img :src="makeQualityBadge('coordinates', amp.coordinates)" fit="scale-down"
                  alt="Quality badge cannot be shown. Please check your internet connection."
                  title="Mapping genes to their coordinates in the contigs, marking those at 5' terminal as suspicious"/> &nbsp; &nbsp;
            <img :src="makeQualityBadge('metaproteomes', amp.metaproteomes)" fit="scale-down"
                  alt="Quality badge cannot be shown. Please check your internet connection."
                  title="Mapping of exact matches in metaproteomic sets from PRIDE database"/> &nbsp; &nbsp;
            <img :src="makeQualityBadge('metatranscriptomes', amp.metatranscriptomes)" fit="scale-down"
                  alt="Quality badge cannot be shown. Please check your internet connection."
                  title="No info."/> &nbsp; &nbsp;
            <img :src="makeQualityBadge('RNAcode', amp.RNAcode)" fit="scale-down"
                  alt="Quality badge cannot be shown. Please check your internet connection."
                  title="Identification of protein-coding regions with RNAcode in alignments produced with nucleotide sequences from families of at least eight members. RNAcode assesses evolutionary signatures typical for protein genes"/>&nbsp; &nbsp;
          </div>
          <div class="col-12 text-body1">
            The AMP belongs to
            <a :href="getFamilyPageURL()"><span class="text-body1">{{ amp.family }}</span></a>
            family and has {{ amp.length }} amino acid residues.
          </div>
        </div>
        
        <div class="row bg-white">
          <div class="col-12 q-pa-md">
            <q-tabs v-model="tabName" dense align="justify" class="bg-grey-3 text-secondary">
              <q-tab name="overview" label="Overview" tabindex="overview" index="overview"/>
              <q-tab name="features" label="Features" tabindex="features" index="features"/>
            </q-tabs>
            <q-tab-panels v-model="tabName" animated class="row text-left">
              <q-tab-panel name="overview">
                <div class="row text-left">
                  <div class="col-12 col-md-3 q-pt-md q-px-md justify-center">
                    <div class="subsubsection-title">
                      Peptide sequence <q-btn @click="CopyPeptideSequence()" icon="content_copy" size="sm"></q-btn>
                    </div>
                    <pre><code id="aa-sequence">{{ amp.sequence }}</code></pre>
                    <div class="subsubsection-title">Secondary Structure</div>
                    <Plotly :data="SecStructureBarData()" :layout="secondaryStructureLayout()"
                            :toImageButtonOptions="{format: 'svg', scale: 1}"/>
                  </div>
                  <div class="col-12 col-md-8 offset-md-1 q-pt-md q-px-md justify-center" id="global distribution">
                    <div class="subsubsection-title text-center">Geographical Distribution</div>
                    <div v-if="distribution.geo.lat.length > 0">
                      <Plotly :data="GeoPlotData()" :layout="GeoPlotLayout()" :toImageButtonOptions="{format: 'svg', scale: 1}"/>
                    </div>
                    <div v-else>
                      <div style="height:400px; line-height: 400px" class="text-center q-px-md">
                        Empty, all associated smORF genes were from Progenomes2 genomes (no geographical information).
                      </div>
                    </div>
                  </div>
                </div>
                <q-separator></q-separator>
                <div class="row">
                  <div class="col-12 q-px-md q-pt-md">
                    <div class="subsection-title">Distribution</div>
                  </div>
                  <div class="col-12 col-md-6 q-px-md">
<!--                    TODO Bigger title  and figure captions-->
                    <div class="subsubsection-title text-center">Habitats</div>
                    <div v-if="distribution.habitat.labels.length !== 0">
                      <Plotly :data="EnvPlotData()" :layout="EnvPlotLayout()" :toImageButtonOptions="{format: 'svg', scale: 1}"/>
                      <p class="text-center">Some environment names may be hidden due to space limit. <br>Use your curser to zoom in and browse.</p>
                    </div>
                    <div v-else style="height:500px; display: -webkit-flex; display: flex; align-items: center; " class="text-center q-px-md">
                      <p>Empty, all associated smORF genes were from Progenomes2 genomes (no habitat information).</p>
                    </div>
                  </div>
                  <div class="col-12 col-md-6 q-px-md">
                    <div class="subsubsection-title text-center">Microbial sources</div>
                    <div>
                      <Plotly :data="MicrobialSourcePlotData()" :layout="MicrobialSourcePlotLayout()" :toImageButtonOptions="{format: 'svg', scale: 1}"/>
                      <p class="text-center">Others *: Also including unknown microbial sources <b>at species level</b>.</p>
                    </div>
                  </div>
                </div>
                <q-separator></q-separator>
                <div class="row">
                  <div class="col-12 q-px-md q-pt-md">
                    <div class="subsection-title">Relationships</div>
                    <el-button @click="DownloadRelationships" type="primary" class="download-btn">
                      <BootstrapIcon icon="cloud-download" variant="light" size="1x" />
                    Download as CSV
                    </el-button>
                    <el-table :data="currentMetadata" stripe :default-sort="{prop: 'GMSC', order: 'ascending'}" width="100%">
                      <el-table-column prop="GMSC_accession" label="Gene" sortable width="260%"/>
                      <el-table-column label="Gene sequense" sortable width="400%">
                        <template #default="props">
                          <pre><code><small>{{ props.row.gene_sequence }}</small></code></pre>
                        </template>
                      </el-table-column>
                      <el-table-column prop="sample" label="Sample/Genome" sortable width="200%"/>
                      <el-table-column prop="general_envo_name" label="Habitat" sortable width="150%"/>
                      <el-table-column label="Microbial source" sortable width="200%">
                        <template #default="props">
                          <div v-if="props.row.microbial_source_s">{{ props.row.microbial_source_s }}</div>
                          <div v-else-if="props.row.microbial_source_g">{{ props.row.microbial_source_g }}</div>
                          <div v-else-if="props.row.microbial_source_f">{{ props.row.microbial_source_f }}</div>
                          <div v-else-if="props.row.microbial_source_o">{{ props.row.microbial_source_o }}</div>
                          <div v-else-if="props.row.microbial_source_c">{{ props.row.microbial_source_c }}</div>
                          <div v-else-if="props.row.microbial_source_p">{{ props.row.microbial_source_p }}</div>
                          <div v-else-if="props.row.microbial_source_d">{{ props.row.microbial_source_d }}</div>
                        </template>
                      </el-table-column>
                    </el-table>
                    <div class="block">
                      <el-pagination
                          @size-change="setMetadataPageSize"
                          @current-change="setMetadataPage"
                          :page-sizes="[5, 10, 20, 50, 100]"
                          :page-size="5"
                          layout="total, sizes, prev, pager, next, jumper"
                          :total="amp.metadata.info.totalRow"
                      >
                      </el-pagination>
                    </div>
                  </div>
                </div>
              </q-tab-panel>
              <q-tab-panel name="features">
                <div class="row">
                  <div class="col-12 q-pa-md">
                    <div class="row">
                      <div class="col-12">
                        <HelicalWheel :amp_seq="amp.sequence"></HelicalWheel>
                      </div>
                    </div>
                    <q-separator></q-separator>
                    <div class="subsection-title">Feature positioning within family<br/><br/></div>
                    <div class="main-text">
                        These features below were calculated by using the
                        <el-link href="https://biopython.org/docs/1.79/api/Bio.SeqUtils.ProtParam.html" type="primary">
                          Bio.SeqUtils.ProtParam.ProteinAnalysis
                        </el-link>
                        module from
                        <el-link href="https://doi.org/10.1093/bioinformatics/btp163" type="primary">
                          BioPython
                        </el-link> (version 1.79).
                    </div>
                    <div class="row">
                      <div class="col-12 col-md-4">
                        <div class="subsubsection-title-center">Molecular weight<q-tooltip max-width="30rem">{{ featuresHelpMessages.MW }}</q-tooltip></div>
                        <Plotly :data="makeFamilyFeatureTraces(famFeaturesGraphData.molecular_weight, 'rgba(93, 164, 214, 0.5)')"
                                :layout="familyFeatureGraphLayout(amp.molecular_weight)"/>
                      </div>
                      <div class="col-12 col-md-4">
                        <div class="subsubsection-title-center">Aromaticity<q-tooltip max-width="30rem">{{ featuresHelpMessages.Aromaticity }}</q-tooltip></div>
                        <Plotly :data="makeFamilyFeatureTraces(famFeaturesGraphData.aromaticity, 'rgba(255, 144, 14, 0.5)')"
                                :layout="familyFeatureGraphLayout(amp.aromaticity)" />
                      </div>
                      <div  class="col-12 col-md-4">
                        <div class="subsubsection-title-center">GRAVY<q-tooltip max-width="30rem">{{ featuresHelpMessages.GRAVY }}</q-tooltip></div>
                        <Plotly :data="makeFamilyFeatureTraces(famFeaturesGraphData.gravy, 'rgba(44, 160, 101, 0.5)')"
                                :layout="familyFeatureGraphLayout(amp.gravy)" />
                      </div>
                    </div>
                    <div class="row">
                      <div class="col-12 col-md-4">
                        <div class="subsubsection-title-center">Instability index<q-tooltip max-width="30rem">{{ featuresHelpMessages.Instability_index }}</q-tooltip></div>
                        <Plotly :data="makeFamilyFeatureTraces(famFeaturesGraphData.instability_index, 'rgba(255, 65, 54, 0.5)')"
                                :layout="familyFeatureGraphLayout(amp.instability_index)" />
                      </div>
                      <div class="col-12 col-md-4">
                        <div class="subsubsection-title-center">Isoelectric point<q-tooltip max-width="30rem">{{ featuresHelpMessages.pI }}</q-tooltip></div>
                        <Plotly :data="makeFamilyFeatureTraces(famFeaturesGraphData.isoelectric_point, 'rgba(207, 114, 255, 0.5)')"
                                :layout="familyFeatureGraphLayout(amp.isoelectric_point)" />
                      </div>
                      <div class="col-12 col-md-4">
                        <div class="subsubsection-title-center">Charge at pH 7.0<q-tooltip max-width="30rem">{{ featuresHelpMessages.Charge_at_pH_7 }}</q-tooltip></div>
                        <Plotly :data="makeFamilyFeatureTraces(famFeaturesGraphData.charge_at_pH_7, 'rgba(127, 96, 0, 0.5)')"
                                :layout="familyFeatureGraphLayout(amp.charge_at_pH_7)" />
                      </div>
                      <div class="info-item-value">
                        The features were calculated by using the
                        <a href="https://biopython.org/docs/1.79/api/Bio.SeqUtils.ProtParam.html">
                          Bio.SeqUtils.ProtParam.ProteinAnalysis</a> module from<a href="https://doi.org/10.1093/bioinformatics/btp163">
                          BioPython
                        </a> (version 1.79).
                      </div>
                    </div>
                  </div>
                </div>
              </q-tab-panel>
            </q-tab-panels>
          </div>
        </div>
      </div>
      <div class="col-xs-0 col-xl-2 bg-white"></div>
    </div>
  </div>
</template>

<style>
.nav-section {
  font-size: medium;
  font-weight: bold
}

.nav-subsection {
  line-height: 1.5;
  font-size: medium;
  font-weight: normal;
}

.el-carousel__item h3 {
  color: #475669;
  font-size: 14px;
  opacity: 0.75;
  line-height: 200px;
  margin: 0;
}

.jumbotron {
          padding-top: 10px;
          padding-bottom: 10px;
          text-align: center;
}
#labelleft, #labelright {
      dominant-baseline: hanging;
      font-size: 10px;
}

#labelleft {
  text-anchor: end;
}

#labelright {
  text-anchor: start;
}

rect.overlay {
  stroke: black;
}

rect.selection {
  stroke: none;
  fill: lightblue;
  fill-opacity: 0.4;
}

.social-media-sharers {
  -ms-flex-positive: 0;
  flex-grow: 0;
  -ms-flex-preferred-size: 24px;
  flex-basis: 24px
}

.social-media-sharer, .social-media-sharer__icon {
  display: inline-block
}

.social-media-sharer {
  background-color: #212121;
  border-radius: 3px;
  color: #fff;
  margin: 0 8px;
  height: 24px;
  padding: 2px 0;
  text-decoration: none;
  transition: 25ms ease-out;
  width: 24px
}

.content-header--image .social-media-sharer {
  background-color: transparent;
  border: 1px solid #fff;
  padding: 1px 0
}

.content-header:not(.content-header--image) .social-media-sharer:hover,
.content-header:not(.content-header--image) .social-media-sharer:active {
  background-color: #0288d1
}

.social-media-sharer__icon svg {
  width: 16px;
  height: 16px;
  margin-right: 7px;
  vertical-align: top
}

.social-media-sharer__icon_wrapper--small svg {
  margin: 0;
  vertical-align: middle
}

.social-media-sharer__icon--solid {
  fill: #fff;
  stroke: none
}
</style>

<script>
import Plotly from "../components/Plotly"
import * as clipboard from "clipboard-polyfill/text"
import { Notify } from "quasar"
import HelicalWheel from '@/components/HelicalWheel'


export default {
  name: 'AMP_card',
  components: {
    Plotly,
    HelicalWheel
  },
  data() {
    const default_distribution = {
      geo: {type: "bubble map", lat: [], lon: [], size: [], colors: []},
      habitat: {type: "bar plot", labels: [], values: []},
      microbial_source: {type: "bar plot", labels: [], values: []}
    }
    return {
      tabName: 'overview',
      amp: {
        accession: this.$route.query.accession,
        sequence: '',
        length: 0,
        family: '',
        molecular_weight: 0,
        aromaticity: 0,
        gravy: 0,
        instability_index: 0,
        isoelectric_point: 0,
        charge_at_pH_7: 0,
        secondary_structure: {helix: 0, turn: 0, sheet: 0},
        feature_graph_points: {
          transfer_energy: {type: "line plot", x: [], y: [], c: []},
          hydrophobicity_parker: {type: "line plot", x: [], y: [], c: []},
          surface_accessibility: {type: "line plot", x: [], y: [], c: []},
          flexibility: {type: "line plot", x: [], y: [], c: []}
        },
        metadata: {
          info: {
            pageSize: 5,
            totalPage: 1,
            totalRow: 1,
            currentPage: 1,
          },
          data: [],
        },
        quality: {
          Antifam: "yellow",
          RNAcode: "yellow",
          metaproteomes: "yellow",
          coordinates: "yellow",
          score: 0,
        },
      },
      distribution: default_distribution,
      default_distribution: default_distribution,
      famFeaturesGraphData: {
        molecular_weight: [],
        length: [],
        aromaticity: [],
        gravy: [],
        instability_index: [],
        isoelectric_point: [],
        charge_at_pH_7: [],
      },
      featuresHelpMessages: {
        MW: 'Molecular weight of a protein in Daltons.',
        Aromaticity: 'Aromaticity according to Lobry (1994), simply the relative frequency of Phe+Trp+Tyr.',
        Instability_index: 'Instability index according to Guruprasad et al (1990) is a test of a protein for stability. Values above 40 correspont to unstable proteins (short half lives).',
        GRAVY: 'Grand average of hydropathicity index (GRAVY) represents the hydrophobicity value of a peptide, and consists of the sum of the hydropathy values of all the amino acids divided by the sequence length. If GRAVY is positive, it indicates a hydrophobic protein as well as its opposite, when GRAVY is negative.',
        Charge_at_pH_7: 'Charge corresponds to the net electrical charge of a protein at pH 7.0',
        pI: 'Isoelectric point (pI) is the pH at which a particular molecule carries no net electrical charge.'
      },
    }
  },
  // setup (){
  //   const $q = useQuasar()
  // },
  created() {
    this.getAMP()
  },
  mounted() {
    this.setMetadataPageSize(5)
  },
  computed: {
    currentMetadata() {
      return this.amp.metadata.data
    }
  },
  methods: {
    getAMP() {
      let self = this
      let amp_accession = self.$route.query.accession
      this.axios.get('/amps/' + amp_accession, {})
          .then(function (response) {
            console.log(response.data)
            self.amp = response.data
            self.amp.charge_at_pH_7 = response.data.charge
            self.amp.metadata.info.totalRow = response.data.metadata.info.totalItem
            self.getFamilyFeatures()
          })
          .catch(function (error) {
            console.log(error);
          })
      this.axios.get('/amps/' + amp_accession + '/distributions', {})
          .then(function (response) {
            console.log(response.data)
            self.distribution = response.data
          })
          .catch(function (error) {
            console.log(error)
          })
    },
    makeQualityBadge(name, value){
      const colors_mapping = {
        Passed: "green",
        "Not tested": 'yellow',
        Failed: "red",
      }
      const URL = 'https://img.shields.io/static/v1?style=flat&label=' + name + '&color=' + colors_mapping[value] + '&message=' + value + '&style=flat'
      // console.log(URL)
      return URL
    },
    getFamilyFeatures() {
      let self = this
      this.axios.get('/families/' + self.amp.family + '/features', {})
          .then(function (response) {
            console.log(response.data)
            self.updateFamilyFeatures(response.data)
          })
          .catch(function (error) {
            console.log(error)
          })
    },
    SecStructureBarData() {
      let strucData = this.amp.secondary_structure
      // strucData.disordered = 1 - strucData.turn - strucData.helix - strucData.sheet
      return [{
        type: 'bar',
        name: '',
        x: Object.keys(strucData),
        y: Object.values(strucData),
        marker: {color: this.ColorPalette('quanlitative')},
        textinfo: "label+percent", insidetextorientation: "radial"
      }]
    },
    secondaryStructureLayout() {
      return {
        title: {text: ''},
        yaxis: {title: 'Fraction of amino acids'},
        margin: {l: 80, r: 40, t: 20, b: 60, pad: 0},
        showlegend: false,
        height: 300,
        width: 300
      }
    },
    setMetadataPage(page) {
      this.amp.metadata.info.currentPage = page - 1
      console.log(this.amp.metadata.info.currentPage)
      let config = {
        params: {page: this.amp.metadata.info.currentPage, page_size: this.amp.metadata.info.pageSize}
      }
      let self = this
      this.axios.get('/amps/' + this.amp.accession + '/metadata', config)
          .then(function (response) {
            console.log(response.data)
            self.amp.metadata.data = response.data.data
            self.amp.metadata.info.totalPage = response.data.info.totalPage
            self.amp.metadata.info.totalRow = response.data.info.totalItem
            console.log(self.amp.metadata.data)
          })
          .catch(function (error) {
            console.log(error);
          })
    },
    setMetadataPageSize(size) {
      this.amp.metadata.info.pageSize = size
      this.setMetadataPage(1)
    },
    GeoPlotData() {
      let data = this.distribution.geo
      return [{
        type: 'scattergeo',
        mode: 'markers',
        lat: data.lat,
        lon: data.lon,
        marker: {
          symbol: 'circle',
          size: 10,
          sizeref: 10,
          color: data.size,
          cmax: 1000,
          cmin: 0,
          colorscale: 'Greens',
          reversescale: true,
          colorbar: {
              title: '# smORF genes',
          },
          line: {
            color: 'rgb(0, 0, 0)',
            width: 1
          }
        },
      }]
    },
    GeoPlotLayout() {
      return {
        height: 400,
        showlegend: false,
        geo: {
          scope: 'global',
          resolution: 50,
          showland: true,
          landcolor: 'rgb(217, 217, 217)',
          subunitwidth: 1,
          countrywidth: 1,
          subunitcolor: 'rgb(255,255,255)',
          countrycolor: 'rgb(255,255,255)'
        },
        margin: {
          l: 40,
          r: 40,
          t: 40,
          b: 40
        }
      }
    },
    EnvPlotData() {
      let data = this.distribution
      let env_data = {
        type: "bar",
        x: data.habitat.values,
        y: data.habitat.labels,
        orientation: 'h',
        marker: {
          color: this.ColorPalette('quanlitative')[0],
          width: 1
        },
      }
      return [env_data]
    },
    EnvPlotLayout() {
      return {
        margin: {l: 200, r: 50, b: 80, t: 20}, autosize: false, height: 500, width: 600,
        xaxis: {
          type: 'log', autorange: true,
          title: {
            text: '# smORF genes (in exponential)',
            font: {
              size: 18,
            }
          },
        },
      }
    },
    MicrobialSourcePlotData(){
      let data = this.distribution
      let env_data = {
        type: "bar",
        x: data.microbial_source.values,
        y: data.microbial_source.labels,
        orientation: 'h',
        marker: {
          color: this.ColorPalette('quanlitative')[1],
          width: 1
        },
      }
      return [env_data]
    },
    MicrobialSourcePlotLayout(){
      return {
        margin: {l: 200, r: 50, b: 80, t: 20}, autosize: false, height: 500, width: 600, 
        xaxis: {
          type: 'log', autorange: true,
          title: {
            text: '# smORF genes (in exponential)',
            font: {
              size: 18,
            }
          },
        },
      }
    },
    DistributionGraphData() {
      let data = this.distribution
      let habitat_data = {
        type: "sunburst",
        labels: data.habitat.labels, //["Eve", "Cain", "Seth", "Enos", "Noam", "Abel", "Awan", "Enoch", "Azura"],
        parents: data.habitat.parents, //["", "Eve", "Eve", "Seth", "Seth", "Eve", "Eve", "Awan", "Eve" ],
        values: data.habitat.values, //[65, 14, 12, 10, 2, 6, 6, 4, 4],
        leaf: {opacity: 0.4},
        // marker: {line: {"width": 2}},
        branchvalues: 'total'
      }
      // let host_data = {
      //   type: "sunburst",
      //   labels: data.host.labels, //['Viruses', "Anelloviridae", "unclassified Anelloviridae", "Small anellovirus", "cellular organisms", "Bacteria", "Terrabacteria group", "Actinobacteria"],
      //   parents: data.host.parents, // ["", 'Viruses', "Anelloviridae", "unclassified Anelloviridae", "", "cellular organisms", "Bacteria", "Terrabacteria group"],
      //   values: data.host.values, //[14, 14, 14, 14, 6, 6, 6, 6],
      //   outsidetextfont: {size: 20, color: "#377eb8"},
      //   leaf: {opacity: 0.4},
      //   // marker: {line: {width: 2}},
      //   branchvalues: 'total',
      //   visible: false,
      // }
      return [habitat_data]
    },
    // DistributionGraphLayout() {
    //   return {
    //     height: 400, margin: {l: 40, r: 40, b: 40, t: 40}, autosize: true,
    //     sunburstcolorway: this.ColorPalette('quanlitative'),
    //     updatemenus: [{
    //       direction: 'left', type: 'buttons', pad: {r: 10, t: 10},
    //       showactive: true, x: 0.5, y: 1.2, yanchor: 'top', xanchor: 'center',
    //       buttons: [{
    //         method: 'update',
    //         args: [{'visible': this.makeTraceVisible(0, 2)}],
    //         label: 'Habitats'
    //       }, {
    //         method: 'update',
    //         args: [{'visible': this.makeTraceVisible(1, 2)}],
    //         label: 'Hosts'
    //       },
    //       ]
    //     }
    //     ]
    //   }
    // },
    initFamilyFeatures() {
      this.famFeaturesGraphData = {
        molecular_weight: [],
        length: [],
        aromaticity: [],
        gravy: [],
        instability_index: [],
        isoelectric_point: [],
        charge_at_pH_7: [],
        // Secondary_structure: {helix: [], turn: [], sheet: []},
      }
    },
    updateFamilyFeatures(data) {
      this.initFamilyFeatures()
      let self = this
      Object.values(data).forEach(function (amp_features) {
            self.famFeaturesGraphData.instability_index.push(amp_features.Instability_index)
            self.famFeaturesGraphData.gravy.push(amp_features.GRAVY)
            self.famFeaturesGraphData.molecular_weight.push(amp_features.MW)
            self.famFeaturesGraphData.aromaticity.push(amp_features.Aromaticity)
            self.famFeaturesGraphData.charge_at_pH_7.push(amp_features.Charge_at_pH_7)
            self.famFeaturesGraphData.isoelectric_point.push(amp_features.Isoelectric_point)
          }
      )
    },
    makeFamilyFeatureTraces(data, color) {
      return [
        {
          type: 'violin',
          y: data,
          points: 'all',
          box: {
            visible: true
          },
          hoverinfo: 'y',
          // boxpoints: 'all',
          line: {
            color: 'black'
          },
          fillcolor: color,
          opacity: 0.6,
          meanline: {
            visible: true
          },
          name: ''
          // x0: ''
        },
      ]
    },
    familyFeatureGraphLayout(value) {
      // console.log(value)
      return {
        // title: name,
        autosize: true,
        margin: {l: 50, r: 20, b: 20, t: 20},
        annotations: [{
          x: 0,
          xanchor: 'left',
          y: value,
          yanchor: 'bottom',
          text: this.amp.accession,
          showarrow: true,
          arrowcolor: 'red',
          arrowhead: 2,
          font: {
            size: 14,
            color: 'red'
          },
          align: 'right',
          ax: 40,
          ay: 0,
        }],
        // shapes: [
        //   {
        //     type: 'line',
        //     xref: 'paper',
        //     yref: 'y',
        //     x0: 0,
        //     y0: value,
        //     x1: 1,
        //     y1: value,
        //     line: {
        //         color: 'red',
        //         width: 2,
        //         dash:'dot'
        //     }
        //   }
        // ]
      }
    },
    featureGraphData() {
      let self = this
      let data = self.features.graph_points
      let line = {color: 'blue'}
      return [

        {
          x: data.transfer_energy.x,
          y: data.transfer_energy.y,
          line: line,
          marker: {color: data.transfer_energy.c},
          visible: true,
        },
        {x: data.flexibility.x, y: data.flexibility.y, line: line, visible: false},
        {x: data.hydrophobicity_parker.x, y: data.hydrophobicity_parker.y, line: line, visible: false},
        {x: data.surface_accessibility.x, y: data.surface_accessibility.y, line: line, visible: false}
      ]
    },
    featureGraphLayout() {
      return {
        height: 600, width: 1000, margin: {l: 100, r: 100, b: 80, t: 40},
        // xaxis: {
        //   title: {
        //     text: 'Window start position'
        //   },
        //   showticklabels: true,
        //   tickfont: {
        //     // family: 'Old Standard TT, serif',
        //     size: 10,
        //     tickangle: 90,
        //     color: ['green', 'red', 'blue']//this.features.graph_points.surface_accessibility.c
        //   },
        //   // label: {
        //   //   font: {
        //   //     size: 10,
        //   //     color: this.features.graph_points.surface_accessibility.c
        //   //   }
        //   // }
        // },
        // yaxis: {
        //   title: {
        //     text: 'Selected feature'
        //   }
        // },
        updatemenus: [
          {
            direction: 'left', type: 'buttons', pad: {r: 10, t: 10},
            showactive: true, x: 0.5, y: 1.2, yanchor: 'top', xanchor: 'center',
            buttons: [
              {method: 'restyle', args: ['visible', this.makeTraceVisible(0, 4)], label: 'EZ energy'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(1, 4)], label: 'Flexibility'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(2, 4)], label: 'Hydrophobicity - Parker'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(3, 4)], label: 'Surface Accessibility'}
            ]
          }],
      }
    },
    comparisonGraphData() {
      function makeTrace(i) {
        return {
          y: Array.apply(null, Array(100)).map(() => Math.random()),
          line: {
            color: 'black'
          },
          visible: i === 0,
          //name: ['EZenergy', 'Flexibility', 'Hydrophobicity Parker', 'SA AMPs'].slice(i),
        };
      }

      return [0, 1, 2, 3, 4, 5, 6, 7].map(makeTrace)
    },
    comparisonGraphLayout() {
      return {
        direction: 'left', type: 'buttons', pad: {r: 10, t: 10},
        updatemenus: [
          {
            direction: 'left', type: 'buttons', pad: {'r': 10, 't': 10},
            showactive: true, x: 0.5, y: 1.4, yanchor: 'top', xanchor: 'center',
            buttons: [
              {method: 'restyle', args: ['visible', this.makeTraceVisible(4, 12)], label: 'aa composition diviation'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(5, 12)], label: 'aindex_z'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(6, 12)], label: 'boman_z'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(7, 12)], label: 'charge_z'}],
          },
          {
            direction: 'left', type: 'buttons', pad: {'r': 10, 't': 10},
            showactive: true, x: 0.5, y: 1.2, yanchor: 'top', xanchor: 'center',
            buttons: [
              {method: 'restyle', args: ['visible', this.makeTraceVisible(8, 12)], label: 'hmoment_z'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(9, 12)], label: 'hydrophobicity z'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(10, 12)], label: 'instaindex_z'},
              {method: 'restyle', args: ['visible', this.makeTraceVisible(11, 12)], label: 'pI_z'}]
          }
        ]
      }
    },
    MapColors(categories, colors) {
      const levels = [...new Set(categories)]
      console.log(levels)
      const mapping = []
      for (let i = 0; i <= categories.length; i++) {
        mapping[levels[i]] = colors[i]
      }
      return categories.map(function (cate) {
        return mapping[cate]
      })
    },
    ColorPalette(kind) {
      if (kind === 'sequential') {
        return ['#ffffe5', '#fff7bc', '#fee391', '#fec44f', '#fe9929', '#ec7014', '#cc4c02', '#8c2d04']
      } else if (kind === 'diverging') {
        return ['#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#c7eae5', '#80cdc1', '#35978f', '#01665e']
      } else if (kind === 'quanlitative') {
        return ['#1b9e77', '#d95f02', '#7570b3', '#e7298a', '#66a61e', '#e6ab02', '#a6761d', '#666666']
      } else {
        console.log('please set the `kind` option for color palette.')
        return null
      }
    },
    exportSVG() {
      return {
        toImageButtonOptions: {
          format: 'svg', // one of png, svg, jpeg, webp
          filename: 'custom_image',
          height: 500,
          width: 700,
          scale: 1 // Multiply title/legend/axis/canvas sizes by this factor
        }
      }
    },
    getFamilyPageURL() {
      // TODO Change URL here
      return "/family?accession=" + this.amp.family
    },
    CopyPeptideSequence() {
      clipboard.writeText(this.amp.sequence).then(
          () => {
            console.log("success!");
            this.showNotif('Peptide sequences copied.')
          },
          () => {
            console.log("error!");
          }
      )
    },
    showNotif(message){
      Notify.create({
        message: message,
        // html: true,
        color: 'primary',
        position: 'bottom',
        timeout: 3000,
        icon: 'announcement',
        // actions: [
        //   { label: 'Got it', color: 'yellow', handler: () => { /* ... */ } }
        // ]
      })
    },
    makeTraceVisible(index, totalTrace) {
      var visibility = []
      for (var i = 0; i < totalTrace; i++) {
        visibility[i] = false
      }
      visibility[index] = true
      console.log(visibility)
      return visibility
    },
    UnpackCol(rows, key) {
      return rows.map(function (row) {
        return row[key];
      });
    },
    downloadCurrPage() {
      print()
    },
    async DownloadRelationships(){
      const ObjectsToCsv = require('objects-to-csv');
      const data = new ObjectsToCsv(this.currentMetadata);
      const str = await data.toString()
      const blob = new Blob([str], {type: "text/plain;charset=utf-8"});
      saveAs(blob, "Relationships.csv");
    }
  }
}
</script>
