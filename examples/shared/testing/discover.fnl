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

(fn has-example-tasks? [example]
  (file-exists? (.. "examples/" example "/tasks/run-tests")))

(fn has-example-deps? [example]
  (file-exists? (.. "examples/" example "/deps.fnl")))

(local VISUAL-EXEMPT-EXAMPLES
  {:keep-going-right true})

(fn has-visual-harness? [example]
  (file-exists? (.. "examples/" example "/visual/tasks/run-visual-tests")))

(fn visual-exempt? [example]
  (not= nil (. VISUAL-EXEMPT-EXAMPLES example)))

(fn visual-example-dirs []
  (let [dirs []]
    (each [_ name (ipairs (love2d-example-dirs))]
      (when (has-visual-harness? name)
        (table.insert dirs name)))
    dirs))

(fn run-example-shell! [name shell-cmd]
  (let [cmd (.. "cd examples/" name " && " shell-cmd)
        (ok reason code) (values (os.execute cmd))]
    (when (not ok)
      (error (.. name " failed (" reason " " code "): " shell-cmd)))))

{:read-file read-file
 :file-exists? file-exists?
 :love2d-example-dirs love2d-example-dirs
 :valid-startup-test? valid-startup-test?
 :valid-main-lua? valid-main-lua?
 :has-example-tasks? has-example-tasks?
 :has-example-deps? has-example-deps?
 :has-visual-harness? has-visual-harness?
 :visual-exempt? visual-exempt?
 :visual-example-dirs visual-example-dirs
 :run-example-shell! run-example-shell!}
