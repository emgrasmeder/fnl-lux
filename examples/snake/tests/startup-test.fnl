(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local startup (require :shared.testing.startup))

(deftest startup-test
  (testing "game loads and renders first frame"
    (startup.run!)
    (assert-is true)))
