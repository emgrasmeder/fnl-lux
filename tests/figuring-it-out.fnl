(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local {: world/create} (require :io.github.emgrasmeder.lux))

(deftest table-insert-test
  (testing "creator of worlds"
    (assert-eq (. (world/create {:componentStoreName {:arg1 :arg2}}) :component-stores)) 123))
           
