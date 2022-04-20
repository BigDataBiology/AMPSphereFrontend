<template>
  <div id="SeqLogo">
    seq logo auto-generated for SPHERE-III.001_396. Reference is <a href='https://ampsphere-api.big-data-biology.org/v1/families/SPHERE-III.001_396/downloads/SPHERE-III.001_396.pdf'>here</a>.
    <div id='seq_logo'></div>
  </div>
</template>

<style>
</style>

<script>
import { embedProteinLogo, ProteinAlphabet, loadGlyphComponents } from 'logojs-react';


export default {
  name: 'SeqLogo',
  props: {
    alignment: {
      type: Array,
      requires: false,
      default: () => `>AMP10.069_764
KKVKSIVMKVLAMMGENEVRAWGVVIK
>AMP10.000_071
KKVKSIVMKVLAMMGENEVRAWGIGIK
>AMP10.000_147
KKVKSIVMKVLAMMGENEVRAWGVGIK
>AMP10.002_939
KKVKSIVMKVLAMIGENEVRAWGIGIK
>AMP10.010_845
KKVKSIVMKVLAMMGENEVRAWGISIK
>AMP10.135_590
KKVKSIVMKVLAMMGENEVKAWGIGIK
>AMP10.340_995
KKVKSIVMKVLAMMGENEVRAWGIGLK
>AMP10.408_333
KKVKSIVMKVLAMMGENEVRAWGIGI-
>AMP10.513_119
KKVKSIVMKVLAMMGENEVRA------
>AMP10.750_124
KKVKSIVMKVLAMMGENEVRTWGIGIK
>AMP10.844_595
KKVKSIFKKALAMMCENEVKAWGIGIK
>AMP10.022_597
KKVKSIFKKALVLMGENEVRAWGIGIK
>AMP10.000_000
KKVKSIFKKALAMMGENEVKAWGIGIK
>AMP10.000_018
KKVKSIFKKALALMGENEVRAWGIGIK
>AMP10.023_695
KKVKSVFKKALAMMGENEVKAWGIGIK
>AMP10.066_336
KKVKSIFKKALALMGENEVKAWGIGIK
>AMP10.066_463
KKVKSIFKKALAMMGENEVRAWGIGIK
>AMP10.081_708
KKVKSIFKKALALMGENEVRAWGVGIK
>AMP10.270_527
KKVKSIFKKALAMMGENEIKAWGIGIK
>AMP10.564_887
KKVKSIFKKALAMMGENEVKSWGIGIK
>AMP10.729_682
KNVKSIFKKALAMMGENEVKAWGIGIK
>AMP10.095_660
KKVKNIFKKALAMMGENEVKAWGIGIK
>AMP10.653_176
KKVKRIFKKALAMMGENEVKAWGIGIK`.split('\n')
    }
  },
  mounted() {
    let m = this.calPSSM(this.$props.alignment.filter((ele, index, array) => !ele.startsWith('>')))
    this.drawSeqLogo(m, 'seq_logo')
  },
  methods:{
    calPSSM(aln){
      console.log(aln)
      let num_seqs = aln.length
      let seq_length = aln[0].length
      let m = Array(seq_length).fill().map(() => Array(20).fill(42));
      console.log(ProteinAlphabet)
      const aa_order = ProteinAlphabet.map(ele => ele.regex)
      console.log(aa_order)
      for (let i = 0; i < seq_length; i++){
        for (let j = 0; j < aa_order.length; j++){
          let count = 0
          for (let seq of aln){
            count += seq[i] == aa_order[j]
          }
          m[i][j] = count / num_seqs
        }
      }
      console.log(m)
      return m
    },
    drawSeqLogo(m, div_id){
      const seq_props = {
        // startpos: 0,
        ppm: m,
        backgroundFrequencies: undefined,
        yAxisMax: null,
        // negativealpha: undefined,
        // inverted: undefined
      }
      embedProteinLogo(document.getElementById(div_id), seq_props)
    }
  },
}
</script>
