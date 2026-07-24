(local EXAMPLE-MODULES
  [:world :systems :ui :audio :layout :pathfinding :main
   :constants :terrain :physics :camera])

(var saved-love nil)

(fn noop [] nil)

(fn make-font []
  (let [font {}]
    (setmetatable font {:__index
                        {:getWidth (fn [_ text] (if text (# text) 0))
                         :getHeight (fn [_] 12)}})
    font))

(fn make-source []
  (let [source {}]
    (setmetatable source {:__index {:stop noop :play noop}})
    source))

(fn make-sound-data []
  (let [data {}]
    (setmetatable data {:__index {:setSample noop}})
    data))

(fn install! []
  (set saved-love _G.love)
  (let [font (make-font)
        screen-w 560
        screen-h 560]
    (set _G.love
         {:graphics {:setColor noop
                     :clear noop
                     :rectangle noop
                     :line noop
                     :circle noop
                     :print noop
                     :getFont (fn [] font)
                     :getWidth (fn [] screen-w)
                     :getHeight (fn [] screen-h)}
          :sound {:newSoundData (fn [_sample-count _rate _bits _channels]
                                  (make-sound-data))}
          :audio {:newSource (fn [_data _kind] (make-source))}
          :mouse {:getPosition (fn [] 0 0)}
          :keyboard {:isDown (fn [_] false)}
          :event {:quit noop}})))

(fn uninstall! []
  (set _G.love saved-love))

(fn clear-shared-modules! []
  (each [name _ (pairs package.loaded)]
    (when (and (= (type name) "string") (= (name:sub 1 7) "shared."))
      (tset package.loaded name nil))))

(fn clear-example-modules! []
  (each [_ name (ipairs EXAMPLE-MODULES)]
    (tset package.loaded name nil))
  (clear-shared-modules!))

{:install! install!
 :uninstall! uninstall!
 :clear-example-modules! clear-example-modules!
 :clear-shared-modules! clear-shared-modules!}
