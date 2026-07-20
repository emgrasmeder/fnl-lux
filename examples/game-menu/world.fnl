(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))

(local window-width 640)
(local window-height 480)
(local button-width 200)
(local button-height 40)
(local button-gap 20)

(fn button-x [] (/ (- window-width button-width) 2))

(fn create-menu-world []
  (let [world (create {:button [:x :y :w :h]
                       :label [:text]
                       :action [:kind]})
        x (button-x)
        play-y (- (/ window-height 2) button-height button-gap)
        exit-y (+ (/ window-height 2) button-gap)
        play-id (create-entity world [:button x play-y button-width button-height
                                      :label "Play"
                                      :action :play])
        exit-id (create-entity world [:button x exit-y button-width button-height
                                      :label "Exit"
                                      :action :exit])]
    {:world world
     :button-ids [play-id exit-id]
     :window-width window-width
     :window-height window-height}))

{:create-menu-world create-menu-world
 :window-width window-width
 :window-height window-height
 :button-width button-width
 :button-height button-height}
