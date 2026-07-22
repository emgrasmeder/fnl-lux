(local love-mock (require :test-support.love-mock))

(fn run! []
  (love-mock.install!)
  (love-mock.clear-example-modules!)
  (let [(ok err) (pcall (fn []
                           (local fennel (require :fennel))
                           (fennel.dofile "main.fnl" {:env _G})
                           (when (and _G.love _G.love.load) (_G.love.load))
                           (when (and _G.love _G.love.update) (_G.love.update 1.0))
                           (when (and _G.love _G.love.draw) (_G.love.draw))))]
    (love-mock.uninstall!)
    (when (not ok)
      (error (.. "startup failed: " (tostring err))))))

{:run! run!}
