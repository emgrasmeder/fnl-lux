(local love-mock (require :shared.testing.love-mock))

;; Keep in sync with fennel path in each example main.lua
(local PRODUCTION-FENNEL-PATH
  "./?.fnl;../?.fnl;../../src/?.fnl;../../src/?/init.fnl")

(fn bootstrap-production! []
  (let [fennel (require :fennel)]
    (fennel.install {:path PRODUCTION-FENNEL-PATH
                     :macroPath "./?.fnlm"})))

(fn run! []
  (love-mock.install!)
  (love-mock.clear-example-modules!)
  (bootstrap-production!)
  (let [(ok err) (pcall (fn []
                           (local fennel (require :fennel))
                           (fennel.dofile "main.fnl" {:env _G})
                           (when (and _G.love _G.love.load) (_G.love.load))
                           (when (and _G.love _G.love.update) (_G.love.update 1.0))
                           (when (and _G.love _G.love.draw) (_G.love.draw))))]
    (love-mock.uninstall!)
    (when (not ok)
      (error (.. "startup failed: " (tostring err))))))

{:PRODUCTION-FENNEL-PATH PRODUCTION-FENNEL-PATH
 :run! run!}
