(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local discover (require :shared.testing.discover))

(deftest all-examples-startup-test
  (testing "every discovered Love2D example passes startup-test"
    (let [examples (discover.love2d-example-dirs)]
      (assert-is (> (# examples) 0) "expected at least one Love2D example")
      (each [_ name (ipairs examples)]
        (discover.run-example-shell! name
          "deps --profiles dev --no-prompt tasks/run-tests startup-test")))))
