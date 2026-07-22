(import-macros
 {: deftest : testing : assert-is : assert-not}
 :io.gitlab.andreyorst.fennel-test)

(fn read-file [path]
  (let [handle (io.open path "r")]
    (when handle
      (let [content (handle:read "*a")]
        (handle:close)
        content))))

(fn file-exists? [path]
  (let [handle (io.open path "r")]
    (when handle (handle:close))
    (not= handle nil)))

(fn registered-examples []
  (let [content (read-file "tasks/run-tests")
        names []]
    (when content
      (each [line (content:gmatch "[^\n]+")]
        (when (line:find "(local examples" 1 true)
          (let [start (line:find "[" 1 true)
                stop (line:find "]" 1 true)]
            (when (and start stop (< start stop))
              (let [inside (line:sub (+ start 1) (- stop 1))]
                (each [token (inside:gmatch ":[%w%-]+")]
                  (table.insert names (token:sub 2)))))))))
    names))

(fn love2d-example-dirs []
  (let [dirs []]
    (let [pipe (io.popen "ls -1 examples 2>/dev/null")]
      (when pipe
        (each [name (pipe:lines)]
          (when (and (not= name "shared")
                     (file-exists? (.. "examples/" name "/main.fnl"))
                     (file-exists? (.. "examples/" name "/main.lua")))
            (table.insert dirs name)))
        (pipe:close)))
    dirs))

(fn in-list? [list value]
  (var found false)
  (each [_ item (ipairs list)]
    (when (= item value)
      (set found true)))
  found)

(fn valid-startup-test? [example]
  (let [path (.. "examples/" example "/tests/startup-test.fnl")
        content (read-file path)]
    (and content
         (content:find "shared.testing.startup" 1 true)
         (content:find "startup.run!" 1 true))))

(fn valid-main-lua? [example]
  (let [path (.. "examples/" example "/main.lua")
        content (read-file path)]
    (and content (content:find "../?.fnl" 1 true))))

(deftest example-coverage-test
  (testing "every Love2D example is registered and startup-tested"
    (let [registered (registered-examples)
          examples (love2d-example-dirs)]
      (each [_ example (ipairs examples)]
        (assert-is (valid-startup-test? example)
                   (.. example " must have tests/startup-test.fnl calling shared.testing.startup/run!"))
        (assert-is (in-list? registered example)
                   (.. example " must appear in tasks/run-tests examples list"))
        (assert-is (valid-main-lua? example)
                   (.. example "/main.lua must include ../?.fnl in the fennel path"))))))

(deftest registered-examples-exist-test
  (testing "registered examples are real Love2D projects"
    (let [registered (registered-examples)
          examples (love2d-example-dirs)]
      (each [_ name (ipairs registered)]
        (assert-is (in-list? examples name)
                   (.. "registered example " name " must have main.fnl and main.lua"))))))
