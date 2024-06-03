<template>
  <div class="HelicalWheel">
    <div class="row">
      <div class="col-12 col-md-4">
        <div class="subsection-title q-pb-md">
          Helical wheel
        </div>
        <p id="viewof-inputAngle"></p>
        <p id="viewof-currColors"></p>
        <p id="viewof-hMoment"></p>
        <p id="viewof-hFace"></p>

        <q-separator></q-separator>
        <div class="info-item-value q-py-md">
          <p>Click <span id="svgSave"></span> to download.</p>
          <p>Generated based on Tina Wang and Shyam Saladi's work
          (<a href="https://clemlab.github.io/helicalwheel/">https://clemlab.github.io/helicalwheel/</a>).
          If you want to customize the graph, please use their original website.</p>
        </div>
      </div>
      <div class="col-12 col-md-6 offset-md-1">
        <!-- <p id="viewof-slider"></p> -->
        <p id="helicalwheel"></p>
      </div>
    </div>
  </div>
</template>

<style>
.jumbotron {
  padding-top: 10px;
  padding-bottom: 10px;
  text-align: center;
}
#labelleft,
#labelright {
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
  flex-basis: 24px;
}

.social-media-sharer,
.social-media-sharer__icon {
  display: inline-block;
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
  width: 24px;
}

.content-header--image .social-media-sharer {
  background-color: transparent;
  border: 1px solid #fff;
  padding: 1px 0;
}

.content-header:not(.content-header--image) .social-media-sharer:hover,
.content-header:not(.content-header--image) .social-media-sharer:active {
  background-color: #0288d1;
}

.social-media-sharer__icon svg {
  width: 16px;
  height: 16px;
  margin-right: 7px;
  vertical-align: top;
}

.social-media-sharer__icon_wrapper--small svg {
  margin: 0;
  vertical-align: middle;
}

.social-media-sharer__icon--solid {
  fill: #fff;
  stroke: none;
}
</style>

<script>
import drawHelicalWheel from "./helical-wheel-vis";

export default {
  name: "HelicalWheel",
  props: {
    amp_seq: {
      type: String,
      requires: true,
      // default: () => 'KKVKSIFKKALAMMGENEVKAWGIGIK'
    },
  },
  mounted() {
    console.log("drawing helical wheel for seq", this.amp_seq);
    drawHelicalWheel(this.amp_seq);
  },
};
</script>
