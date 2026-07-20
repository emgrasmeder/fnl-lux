{:deps {:fennel {:type :rock :version "1.6.1-1"}}
 :paths {:fennel ["./?.fnl" "../../src/?.fnl" "../../src/?/init.fnl"]}
 :profiles {:dev {:deps {"https://gitlab.com/andreyorst/fennel-test"
                          {:type :git :sha "647321b33d250a56eefdef4adb2ae17a4b27e9a6"}}
                  :paths {:fennel ["./tests/?.fnl" "./?.fnl"]}}}}
