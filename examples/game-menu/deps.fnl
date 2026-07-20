{:deps {:com.github.emgrasmeder/lux.fnl
         {:type :git
          :sha "98b64fe0b4bf606bc16d1d9b79cd531aa5408c8f"
          :paths {:fennel ["src/?.fnl" "src/?/init.fnl"]}}
         :fennel {:type :rock :version "1.6.1-1"}}
 :paths {:fennel ["./?.fnl"]}
 :profiles {:dev {:deps {"https://gitlab.com/andreyorst/fennel-test"
                          {:type :git :sha "647321b33d250a56eefdef4adb2ae17a4b27e9a6"}}
                  :paths {:fennel ["./tests/?.fnl" "./?.fnl"]}}}}
