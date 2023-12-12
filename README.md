# AMPSphere frontend

- Live website: https://ampsphere.big-data-biology.org/


## Project setup
```
npm install
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Lints and fixes files
```
npm run lint
```

### Performance diagnosis tips
```shell
# analyze the chunk-vendors.js and create a production build
npm run report  
```

### Serve the production build on server
```shell
npm install --global yarn
yarn global add serve
npx serve -s -l tcp://0.0.0.0:80 dist
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).

