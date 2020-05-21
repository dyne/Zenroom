# Make ❤ with Zenroom in ClojureScript

This article shows how to use Zenroom from ClojureScript using shadow-cljs, by [transducer](https://github.com/transducer/zenroom-cljs-demo/blob/master/blogpost.md).



### 💻 npm

Install [shadow-cljs](https://github.com/thheller/shadow-cljs) and the zenroom bindings using `npm` or `yarn`:

```sh
# npm
npm install -g shadow-cljs --save-dev
npm install zenroom

# yarn
yarn global add shadow-cljs --dev
yarn add zenroom
```

### 💻 shadow-cljs

Create a `shadow-cljs.edn` with a build hook:

```clojure
{:nrepl {:port 8777}
 :source-paths ["src"]
 :dependencies [[binaryage/devtools "1.0.0"]
                [reagent "1.0.0-alpha2"]] ;; assuming we use Reagent
 :builds {:app {:target :browser
                :build-hooks [(build/setup-zenroom-wasm-hook)]
                :output-dir "resources/public/js/compiled"
                :asset-path "/js/compiled"
                :modules {:app {:init-fn view/init
                                :preloads [devtools.preload]}}
                :devtools {:http-root "resources/public"
                           :http-port 8280}}}}
```

### ✍ Build hook to be browser ready

In ClojureScript in the browser we also need to move the WebAssembly as described in [Part three Zenroom in React](https://www.dyne.org/using-zenroom-with-javascript-react-part3/):

1. We need to make `zenroom.wasm` from the npm package available on the server (in our case by copying it into `resources/public`).
1. We need to remove the line from `zenroom.js` that tries to locate `zenroom.wasm` locally.

With a [shadow-cljs build hook](https://shadow-cljs.github.io/docs/UsersGuide.html#build-hooks) we can automate this process:

```clojure
(ns build
  (:require
   [clojure.java.shell :refer [sh]]))

(defn- copy-wasm-to-public []
  (sh "cp" "node_modules/zenroom/dist/lib/zenroom.wasm" "resources/public/"))

(defn- remove-locate-wasm-locally-line []
  (sh "sed" "-i.bak" "/wasmBinaryFile = locateFile/d" "node_modules/zenroom/dist/lib/zenroom.js"))

(defn setup-zenroom-wasm-hook
  {:shadow.build/stage :configure}
  [build-state]
  (copy-wasm-to-public)
  (remove-locate-wasm-locally-line)
  build-state)
```

The build hook will run when we `shadow-cljs watch app dev` or `shadow-cljs release app`.

We do not need this build hook when targeting Node.

### ☯  ClojureScript interop

We can use JavaScript interop to interact with the Zenroom npm package.

```clojure
(require '[zenroom])

;; Assuming we have a Reagent @app-state

(defn evaluate! []
  (doto zenroom
    (.script (:input @app-state))
    (.keys (-> @app-state :keys read-string clj->js))
    (.data (-> @app-state :data read-string clj->js))
    (.print (fn [s] (swap! app-state update :results conj s)))
    (.success (fn [] (swap! app-state assoc :success? true)))
    (.error (fn [] (swap! app-state assoc :success? false)))
    .zencode-exec))
```

`evaluate!` now obtains input from the `@app-state` and has callback functions that set results of Zencode evaluation.

### ☕ More code

Source code of a full example is available at [https://www.github.com/transducer/zenroom-cljs-demo](https://www.github.com/transducer/zenroom-cljs-demo).