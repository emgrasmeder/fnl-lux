(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local discover (require :shared.testing.discover))

(deftest example-coverage-test
  (testing "every Love2D example meets startup and bootstrap policy"
    (let [examples (discover.love2d-example-dirs)]
      (each [_ example (ipairs examples)]
        (assert-is (discover.valid-startup-test? example)
                   (.. example " must have tests/startup-test.fnl calling shared.testing.startup/run!"))
        (assert-is (discover.valid-main-lua? example)
                   (.. example "/main.lua must include ../?.fnl in the fennel path"))
        (assert-is (discover.has-example-tasks? example)
                   (.. example " must have tasks/run-tests"))
        (assert-is (discover.has-example-deps? example)
                   (.. example " must have deps.fnl"))))))
